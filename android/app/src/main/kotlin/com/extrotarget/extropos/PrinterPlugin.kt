package com.extrotarget.extropos

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import androidx.annotation.RequiresApi
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDeviceConnection
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.OutputStream
import java.net.Socket
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import android.bluetooth.BluetoothSocket
import android.bluetooth.BluetoothManager
import java.util.*

// Import ESCPOS Thermal Printer SDK
import com.dantsu.escposprinter.EscPosPrinter
import com.dantsu.escposprinter.connection.DeviceConnection
import com.dantsu.escposprinter.connection.bluetooth.BluetoothConnection
import com.dantsu.escposprinter.connection.tcp.TcpConnection
import com.dantsu.escposprinter.connection.usb.UsbConnection
import com.dantsu.escposprinter.textparser.PrinterTextParserImg

// Import POSMAC Printer SDK
import net.posprinter.posprinterface.IMyBinder
import net.posprinter.posprinterface.UiExecute
import net.posprinter.service.PosprinterService
import net.posprinter.utils.PosPrinterDev
import android.content.ServiceConnection
import android.content.ComponentName
import android.os.IBinder

// Import USB Serial Library
import com.hoho.android.usbserial.driver.UsbSerialDriver
import com.hoho.android.usbserial.driver.UsbSerialProber

class PrinterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null
    private var activity: Activity? = null
        private val REQUEST_CODE_BLUETOOTH_PERMISSIONS = 1001
        private var pendingBluetoothPermissionResult: Result? = null
        private var permissionResultListenerAdded = false
    private var usbAttachReceiver: BroadcastReceiver? = null
    private var usbPermissionReceiver: BroadcastReceiver? = null
    private val ACTION_USB_PERMISSION = "com.extrotarget.extropos.USB_PERMISSION"

    // POSMAC Printer Service
    private var posmacBinder: IMyBinder? = null
    private var posmacServiceConnection: ServiceConnection? = null
    private var isPosmacConnected = false

    private fun postLog(message: String) {
        try {
            Log.d("PrinterPlugin", message)
            // Forward to Dart side for in-app debugging if handler is registered
            try {
                channel.invokeMethod("printerLog", mapOf("message" to message))
            } catch (ie: Exception) {
                // ignore if Dart handler not ready
            }
        } catch (e: Exception) {
            // ignore logging issues
        }
    }

    // Last error message from the plugin (used for returning structured errors)
    private var lastErrorMessage: String? = null

    private fun initializePosmacService() {
        try {
            posmacServiceConnection = object : ServiceConnection {
                override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
                    posmacBinder = service as IMyBinder
                    isPosmacConnected = true
                    postLog("POSMAC service connected")
                }

                override fun onServiceDisconnected(name: ComponentName?) {
                    posmacBinder = null
                    isPosmacConnected = false
                    postLog("POSMAC service disconnected")
                }
            }

            val intent = Intent(context, PosprinterService::class.java)
            context.bindService(intent, posmacServiceConnection!!, Context.BIND_AUTO_CREATE)
            postLog("POSMAC service initialization started")
        } catch (e: Exception) {
            postLog("Failed to initialize POSMAC service: ${e.message}")
        }
    }

    private fun cleanupPosmacService() {
        try {
            if (posmacServiceConnection != null) {
                context.unbindService(posmacServiceConnection!!)
                posmacServiceConnection = null
            }
            posmacBinder = null
            isPosmacConnected = false
            postLog("POSMAC service cleaned up")
        } catch (e: Exception) {
            postLog("Error cleaning up POSMAC service: ${e.message}")
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.extrotarget.extropos/printer")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        // Initialize POSMAC service
        initializePosmacService()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Clean up USB permission receiver
        try {
            usbPermissionReceiver?.let { context.unregisterReceiver(it) }
            usbPermissionReceiver = null
        } catch (e: Exception) {
            Log.d("PrinterPlugin", "Error cleaning up USB permission receiver: ${e.message}")
        }
        // Clean up POSMAC service
        cleanupPosmacService()
    }

    // ActivityAware methods to request USB permission if needed
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        // Add permission request result listener (if not added yet)
        if (!permissionResultListenerAdded) {
            activityBinding?.addRequestPermissionsResultListener { requestCode, permissions, grantResults ->
                if (requestCode == REQUEST_CODE_BLUETOOTH_PERMISSIONS) {
                    val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                    pendingBluetoothPermissionResult?.success(granted)
                    pendingBluetoothPermissionResult = null
                    return@addRequestPermissionsResultListener true
                }
                return@addRequestPermissionsResultListener false
            }
            permissionResultListenerAdded = true
        }

        // Listen for USB device attachment to auto-request permission for printers
        try {
            if (usbAttachReceiver == null) {
                usbAttachReceiver = object : BroadcastReceiver() {
                    override fun onReceive(ctx: Context?, intent: Intent?) {
                        if (intent == null) return
                        when (intent.action) {
                            UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                                val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                                }
                                if (device != null) {
                                    postLog("USB ATTACHED: id=${device.deviceId} vid=${device.vendorId} pid=${device.productId} name=${device.deviceName} product=${device.productName} mfg=${device.manufacturerName}")
                                    
                                    // Check if likely a printer for logging
                                    val likelyPrinter = try {
                                        isPrinterDevice(device) ||
                                        (device.productName?.lowercase()?.contains("printer") == true) ||
                                        (device.productName?.lowercase()?.contains("pos") == true) ||
                                        (device.productName?.lowercase()?.contains("receipt") == true)
                                    } catch (_: Exception) { false }

                                    if (likelyPrinter) {
                                        postLog("USB ATTACHED: Detected as likely printer")
                                    } else {
                                        postLog("USB ATTACHED: Not obviously a printer, but requesting permission anyway")
                                    }
                                    
                                    // Request permission for ALL USB devices (user can decline if not needed)
                                    try {
                                        val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
                                        if (!usbManager.hasPermission(device)) {
                                            val pi = PendingIntent.getBroadcast(
                                                context, 
                                                0, 
                                                Intent(ACTION_USB_PERMISSION), 
                                                PendingIntent.FLAG_IMMUTABLE
                                            )
                                            postLog("USB ATTACHED: requesting permission for attached device")
                                            usbManager.requestPermission(device, pi)
                                        } else {
                                            postLog("USB ATTACHED: permission already granted for device")
                                        }
                                    } catch (e: Exception) {
                                        Log.e("PrinterPlugin", "USB attach handling error", e)
                                    }
                                }
                            }
                            UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                                val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                                }
                                if (device != null) {
                                    postLog("USB DETACHED: id=${device.deviceId} vid=${device.vendorId} pid=${device.productId} name=${device.deviceName}")
                                }
                            }
                        }
                    }
                }

                val filter = IntentFilter().apply {
                    addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
                    addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
                }
                context.registerReceiver(usbAttachReceiver, filter)
                postLog("USB attach receiver registered")
            }
        } catch (e: Exception) {
            Log.e("PrinterPlugin", "Failed to register USB attach receiver", e)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
        activity = null
        // Unregister attach receiver
        try {
            usbAttachReceiver?.let {
                context.unregisterReceiver(it)
                postLog("USB attach receiver unregistered")
            }
        } catch (_: Exception) {} finally { usbAttachReceiver = null }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        postLog("onMethodCall: ${call.method} args=${call.arguments}")
        when (call.method) {
            "initialize" -> {
                postLog("Plugin initialized")
                result.success(true)
            }
            "discoverPrinters" -> discoverAllPrinters(result)
            "discoverUsbPrinters" -> discoverUsbPrinters(result)
            "discoverBluetoothPrinters" -> discoverBluetoothPrinters(result)
            "discoverNetworkPrinters" -> discoverNetworkPrinters(result)
            "requestUsbPermission" -> requestUsbPermission(call, result)
            "requestBluetoothPermissions" -> requestBluetoothPermissions(result)
            "hasBluetoothPermissions" -> hasBluetoothPermissions(result)
            "printReceipt" -> printReceipt(call, result)
            "printOrder" -> printOrder(call, result)
            "testPrint" -> testPrint(call, result)
            "checkPrinterStatus" -> checkPrinterStatus(call, result)
            "discoverCustomerDisplays" -> discoverCustomerDisplays(result)
            "showCustomerDisplay" -> showCustomerDisplay(call, result)
            "clearCustomerDisplay" -> clearCustomerDisplay(call, result)
            "testCustomerDisplay" -> testCustomerDisplay(call, result)
            "printViaExternalService" -> printViaExternalService(call, result)
            else -> result.notImplemented()
        }
    }

    private fun discoverCustomerDisplays(result: Result) {
        try {
            postLog("discoverCustomerDisplays starting")
            // For now, reuse printer discovery as a coarse match (displays often appear as printers on USB/Bluetooth)
            val allPrinters = mutableListOf<Map<String, Any>>()
            allPrinters.addAll(discoverUsbPrintersInternal())
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                allPrinters.addAll(discoverBluetoothPrintersInternal())
            }
            // Filter out non-Display devices in a basic way: devices with 'display' or 'vfd' in name may be displays
            val displays = allPrinters.filter { m ->
                val name = (m["name"] as? String)?.lowercase() ?: ""
                name.contains("display") || name.contains("vfd") || name.contains("customer") || name.contains("pole")
            }
            postLog("discoverCustomerDisplays complete: found ${displays.size} candidate displays")
            result.success(displays)
        } catch (e: Exception) {
            postLog("discoverCustomerDisplays error: ${e.message}")
            result.error("DISCOVER_ERROR", "Failed to discover displays: ${e.message}", null)
        }
    }

    private fun showCustomerDisplay(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val displayId = args["displayId"] as? String
        val connectionDetails = args["connectionDetails"] as? Map<String, Any>
        val text = (args["text"] as? String) ?: (args["content"] as? String) ?: ""
        if (displayId == null || connectionDetails == null) {
            result.error("INVALID_ARGS", "displayId and connectionDetails required", null)
            return
        }

        try {
            val connType = connectionDetails["connectionType"] as? String
            val success = when (connType) {
                "network" -> {
                    val ip = connectionDetails["ipAddress"] as? String ?: return result.success(false)
                    val port = (connectionDetails["port"] as? Int) ?: 9000
                    
                    // Network I/O must run on background thread
                    val resultHolder = arrayOf(false)
                    val latch = java.util.concurrent.CountDownLatch(1)
                    
                    Thread {
                        var socket: Socket? = null
                        try {
                            socket = Socket()
                            socket.connect(java.net.InetSocketAddress(ip, port), 4000)
                            socket.getOutputStream().write(text.toByteArray())
                            socket.getOutputStream().flush()
                            resultHolder[0] = true
                            postLog("CustomerDisplay NETWORK: sent ${text.length} bytes to $ip:$port")
                        } catch (e: Exception) {
                            postLog("CustomerDisplay NETWORK error: ${e.message}")
                            resultHolder[0] = false
                        } finally {
                            try { socket?.close() } catch (_: Exception) {}
                            latch.countDown()
                        }
                    }.start()
                    
                    try {
                        latch.await(10, java.util.concurrent.TimeUnit.SECONDS)
                        resultHolder[0]
                    } catch (e: InterruptedException) {
                        postLog("CustomerDisplay NETWORK: timeout")
                        false
                    }
                }
                "usb" -> {
                    val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
                    val usbDeviceId = connectionDetails["usbDeviceId"] as? String
                    val platformId = connectionDetails["platformSpecificId"] as? String
                    var targetDevice: UsbDevice? = null
                    for ((_, device) in usbManager.deviceList) {
                        if (usbDeviceId != null && try { matchesUsbDevice(device, usbDeviceId) } catch (_: Exception) { false }) {
                            targetDevice = device
                            break
                        }
                        if (platformId != null && device.deviceName == platformId) {
                            targetDevice = device
                            break
                        }
                    }
                    if (targetDevice == null) {
                        postLog("CustomerDisplay USB: device not found")
                        false
                    } else {
                        try {
                            val conn = usbManager.openDevice(targetDevice) ?: return result.success(false)
                            var wrote = false
                            for (i in 0 until targetDevice.interfaceCount) {
                                val intf = targetDevice.getInterface(i)
                                if (conn.claimInterface(intf, true)) {
                                    for (e in 0 until intf.endpointCount) {
                                        val ep = intf.getEndpoint(e)
                                        if (ep.direction == UsbConstants.USB_DIR_OUT) {
                                            val transferred = conn.bulkTransfer(ep, text.toByteArray(), text.length, 5000)
                                            postLog("CustomerDisplay USB bulkTransfer: $transferred")
                                            if (transferred >= 0) wrote = true
                                            break
                                        }
                                    }
                                    try { conn.releaseInterface(intf) } catch (_: Exception) {}
                                    if (wrote) break
                                }
                            }
                            try { conn.close() } catch (_: Exception) {}
                            wrote
                        } catch (e: Exception) {
                            postLog("CustomerDisplay USB error: ${e.message}")
                            false
                        }
                    }
                }
                "bluetooth" -> {
                    val address = connectionDetails["bluetoothAddress"] as? String ?: return result.success(false)
                    try {
                        val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val bm = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
                            bm.adapter.getRemoteDevice(address)
                        } else {
                            @Suppress("DEPRECATION") BluetoothAdapter.getDefaultAdapter().getRemoteDevice(address)
                        }
                        val sppUuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                        val socket: BluetoothSocket = device.createRfcommSocketToServiceRecord(sppUuid)
                        try {
                            socket.connect()
                            val out: OutputStream = socket.outputStream
                            out.write(text.toByteArray())
                            out.flush()
                            true
                        } catch (e: Exception) {
                            postLog("CustomerDisplay BT error: ${e.message}")
                            false
                        } finally {
                            try { socket.close() } catch (_: Exception) {}
                        }
                    } catch (e: Exception) {
                        postLog("CustomerDisplay BT error: ${e.message}")
                        false
                    }
                }
                else -> false
            }
            result.success(success)
        } catch (e: Exception) {
            postLog("showCustomerDisplay error: ${e.message}")
            result.error("DISPLAY_ERROR", "Failed to show customer display: ${e.message}", null)
        }
    }

    private fun clearCustomerDisplay(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val displayId = args["displayId"] as? String
        val connectionDetails = args["connectionDetails"] as? Map<String, Any>
        if (displayId == null || connectionDetails == null) return result.error("INVALID_ARGS", "displayId and connectionDetails required", null)
        // Clear screen by sending blank space or newline
        val success = showCustomerDisplay(call, result)
        // showCustomerDisplay will write content from args - to clear, we'll send spaces
        // For simplicity, we delegate to showCustomerDisplay with ' ' content
        try {
            val args2 = mapOf("displayId" to displayId, "connectionDetails" to connectionDetails, "text" to " ")
            // Attempt to show blank
            showCustomerDisplay(MethodCall("showCustomerDisplay", args2), result)
            result.success(true)
        } catch (e: Exception) {
            result.error("CLEAR_ERROR", "Failed to clear display: ${e.message}", null)
        }
    }

    private fun testCustomerDisplay(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val displayId = args["displayId"] as? String
        if (displayId == null) return result.error("INVALID_ARGS", "displayId is required", null)
        val connectionDetails = args["connectionDetails"] as? Map<String, Any> ?: mapOf()
        val args2 = mapOf("displayId" to displayId, "connectionDetails" to connectionDetails, "text" to "TEST DISPLAY")
        showCustomerDisplay(MethodCall("showCustomerDisplay", args2), result)
    }

    private fun requestBluetoothPermissions(result: Result) {
        try {
            val toRequest = mutableListOf<String>()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
                    toRequest.add(Manifest.permission.BLUETOOTH_SCAN)
                }
                if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                    toRequest.add(Manifest.permission.BLUETOOTH_CONNECT)
                }
            } else {
                // On earlier platforms, ACCESS_FINE_LOCATION may be required for discovery
                if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                    toRequest.add(Manifest.permission.ACCESS_FINE_LOCATION)
                }
            }

            if (toRequest.isEmpty()) {
                postLog("Bluetooth permissions already granted")
                result.success(true)
                return
            }

            // Request at runtime via the Activity
            if (activity == null) {
                postLog("Bluetooth permission request failed: activity missing")
                result.success(false)
                return
            }

            // Store result and request permissions; callback will resolve
            pendingBluetoothPermissionResult = result
            ActivityCompat.requestPermissions(activity!!, toRequest.toTypedArray(), REQUEST_CODE_BLUETOOTH_PERMISSIONS)
        } catch (e: Exception) {
            postLog("requestBluetoothPermissions error: ${e.message}")
            result.error("PERMISSION_ERROR", "Failed to request Bluetooth permissions: ${e.message}", null)
        }
    }

    private fun hasBluetoothPermissions(result: Result) {
        // Check if Bluetooth is available and enabled
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                val bluetoothAdapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
                    bluetoothManager.adapter
                } else {
                    @Suppress("DEPRECATION")
                    BluetoothAdapter.getDefaultAdapter()
                }
                // Check bluetooth adapter state and runtime permission
                val adapterReady = bluetoothAdapter != null && bluetoothAdapter.isEnabled
                val hasRuntimePermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
                } else {
                    ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                }
                val hasPermission = adapterReady && hasRuntimePermission
                postLog("Bluetooth permissions: $hasPermission")
                result.success(hasPermission)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            postLog("Error checking Bluetooth permissions: ${e.message}")
            result.success(false)
        }
    }

    private fun printViaExternalService(call: MethodCall, result: Result) {
        try {
            @Suppress("UNCHECKED_CAST")
            val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
            val paperSize = args["paperSize"] as? String
            @Suppress("UNCHECKED_CAST")
            val data = (args["receiptData"] ?: args["orderData"]) as? Map<String, Any>
            val title = data?.get("title") as? String ?: "RECEIPT"
            val content = data?.get("content") as? String ?: ""
            val timestamp = data?.get("timestamp") as? String ?: ""

            val charsPerLine = when (paperSize) {
                "mm58" -> 32
                "mm80" -> 48
                else -> 48
            }

            val sb = StringBuilder()
            sb.append(title).append('\n')
            sb.append("".padEnd(charsPerLine, '=')).append('\n')
            sb.append(content).append('\n')
            if (timestamp.isNotEmpty()) {
                sb.append("Time: ").append(timestamp).append('\n')
            }
            sb.append("".padEnd(charsPerLine, '=')).append('\n')
            sb.append("Thank you!\n")

            val text = sb.toString()

            // Prefer ESCPrint Service if installed
            val targetPackage = "com.loopedlabs.escposprintservice"
            val pm = context.packageManager

            // Build base share intent
            val baseIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                putExtra(Intent.EXTRA_SUBJECT, title)
                putExtra(Intent.EXTRA_TITLE, title)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            var launched = false
            try {
                val targeted = Intent(baseIntent).apply { setPackage(targetPackage) }
                if (targeted.resolveActivity(pm) != null) {
                    context.startActivity(targeted)
                    launched = true
                    postLog("EXTERNAL PRINT: Launched ESCPrint Service directly")
                }
            } catch (_: Exception) { /* ignore and fallback */ }

            if (!launched) {
                val chooser = Intent.createChooser(baseIntent, "Print receipt with…").apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(chooser)
                postLog("EXTERNAL PRINT: Launched chooser for external printer service")
            }

            result.success(true)
        } catch (e: Exception) {
            Log.e("PrinterPlugin", "External print error", e)
            result.error("EXTERNAL_PRINT_FAILED", e.message, null)
        }
    }

    private fun printViaExternalServiceImpl(data: Map<String, Any>, paperSize: String?): Boolean {
        return try {
            val title = data["title"] as? String ?: "RECEIPT"
            val content = data["content"] as? String ?: ""
            val timestamp = data["timestamp"] as? String ?: ""

            val charsPerLine = when (paperSize) {
                "mm58" -> 32
                "mm80" -> 48
                else -> 48
            }

            val sb = StringBuilder()
            sb.append(title).append('\n')
            sb.append("".padEnd(charsPerLine, '=')).append('\n')
            sb.append(content).append('\n')
            if (timestamp.isNotEmpty()) {
                sb.append("Time: ").append(timestamp).append('\n')
            }
            sb.append("".padEnd(charsPerLine, '=')).append('\n')
            sb.append("Thank you!\n")

            val text = sb.toString()

            // Prefer ESCPrint Service if installed
            val targetPackage = "com.loopedlabs.escposprintservice"
            val pm = context.packageManager

            // Build base share intent
            val baseIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                putExtra(Intent.EXTRA_SUBJECT, title)
                putExtra(Intent.EXTRA_TITLE, title)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            var launched = false
            try {
                val targeted = Intent(baseIntent).apply { setPackage(targetPackage) }
                if (targeted.resolveActivity(pm) != null) {
                    context.startActivity(targeted)
                    launched = true
                    postLog("EXTERNAL PRINT: Launched ESCPrint Service directly")
                }
            } catch (_: Exception) { /* ignore and fallback */ }

            if (!launched) {
                val chooser = Intent.createChooser(baseIntent, "Print receipt with…").apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(chooser)
                postLog("EXTERNAL PRINT: Launched chooser for external printer service")
            }

            true
        } catch (e: Exception) {
            Log.e("PrinterPlugin", "External print error", e)
            postLog("EXTERNAL PRINT: Error - ${e.message}")
            false
        }
    }

    private fun requestUsbPermission(call: MethodCall, result: Result) {
        // Prevent concurrent permission requests
        if (usbPermissionReceiver != null) {
            Log.d("PrinterPlugin", "USB permission request already in progress")
            result.success(false)
            return
        }

        try {
            @Suppress("UNCHECKED_CAST")
            val connectionDetails = call.arguments as? Map<String, Any>
            val usbDeviceId = connectionDetails?.get("usbDeviceId") as? String
            val platformId = connectionDetails?.get("platformSpecificId") as? String

            val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager

            var targetDevice: UsbDevice? = null
            for ((name, device) in usbManager.deviceList) {
                if (usbDeviceId != null) {
                    try {
                        if (matchesUsbDevice(device, usbDeviceId)) {
                            targetDevice = device
                            break
                        }
                    } catch (_: Exception) {}
                }
                if (platformId != null) {
                    if (device.deviceName == platformId) {
                        targetDevice = device
                        break
                    }
                }
            }

            if (targetDevice == null) {
                Log.d("PrinterPlugin", "USB: device not found for permission request")
                result.success(false)
                return
            }

            if (usbManager.hasPermission(targetDevice)) {
                Log.d("PrinterPlugin", "USB: permission already granted")
                result.success(true)
                return
            }

            // Use Handler for timeout instead of blocking CountDownLatch
            val handler = android.os.Handler(android.os.Looper.getMainLooper())
            val requestCode = System.currentTimeMillis().toInt() // Unique request code
            val pi = PendingIntent.getBroadcast(
                context,
                requestCode,
                Intent(ACTION_USB_PERMISSION).apply {
                    putExtra("device_name", targetDevice.deviceName)
                },
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            val timeoutRunnable = Runnable {
                try {
                    context.unregisterReceiver(usbPermissionReceiver)
                    Log.d("PrinterPlugin", "USB permission request timed out")
                    result.success(false)
                } catch (e: Exception) {
                    Log.d("PrinterPlugin", "Error unregistering receiver on timeout: ${e.message}")
                    result.success(false)
                } finally {
                    usbPermissionReceiver = null
                }
            }

            // Create a unique broadcast receiver for this request
            usbPermissionReceiver = object : BroadcastReceiver() {
                override fun onReceive(ctx: Context?, intent: Intent?) {
                    if (intent == null || intent.action != ACTION_USB_PERMISSION) return

                    // Remove timeout
                    handler.removeCallbacks(timeoutRunnable)

                    try {
                        context.unregisterReceiver(this)
                    } catch (e: Exception) {
                        Log.d("PrinterPlugin", "Error unregistering receiver: ${e.message}")
                    } finally {
                        usbPermissionReceiver = null
                    }

                    val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                    Log.d("PrinterPlugin", "USB permission result: $granted for device ${targetDevice?.deviceName}")
                    result.success(granted)
                }
            }

            val filter = IntentFilter(ACTION_USB_PERMISSION)
            context.registerReceiver(usbPermissionReceiver, filter)

            // Request permission
            usbManager.requestPermission(targetDevice, pi)

            // Set timeout for 10 seconds (increased from 4)
            handler.postDelayed(timeoutRunnable, 10000)

        } catch (e: Exception) {
            Log.e("PrinterPlugin", "requestUsbPermission error: ${e.message}", e)
            result.error("USB_PERMISSION_ERROR", "${e.message}", null)
        }
    }

    private fun discoverAllPrinters(result: Result) {
        try {
            postLog("=== Starting All Printer Discovery ===")
            val allPrinters = mutableListOf<Map<String, Any>>()

            // Discover USB printers
            val usbPrinters = discoverUsbPrintersInternal()
            allPrinters.addAll(usbPrinters)
            postLog("Found ${usbPrinters.size} USB printers")

            // Discover Bluetooth printers (if Bluetooth is available)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                val btPrinters = discoverBluetoothPrintersInternal()
                allPrinters.addAll(btPrinters)
                postLog("Found ${btPrinters.size} Bluetooth printers")
            }

            postLog("=== Discovery Complete: ${allPrinters.size} total printers ===")
            result.success(allPrinters)
        } catch (e: Exception) {
            postLog("Discovery error: ${e.message}")
            Log.e("PrinterPlugin", "Discovery failed", e)
            result.error("DISCOVERY_FAILED", "Failed to discover printers: ${e.message}", null)
        }
    }

    private fun discoverUsbPrinters(result: Result) {
        try {
            postLog("=== Starting USB Printer Discovery ===")
            val usbPrinters = discoverUsbPrintersInternal()
            postLog("=== USB Discovery Complete: ${usbPrinters.size} printers ===")
            result.success(usbPrinters)
        } catch (e: Exception) {
            postLog("USB discovery error: ${e.message}")
            Log.e("PrinterPlugin", "USB discovery failed", e)
            result.error("USB_DISCOVERY_FAILED", "Failed to discover USB printers: ${e.message}", null)
        }
    }

    private fun discoverUsbPrintersInternal(): List<Map<String, Any>> {
        val printers = mutableListOf<Map<String, Any>>()
        
        try {
            val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
            val usbDevices = usbManager.deviceList

            postLog("USB: Scanning ${usbDevices.size} connected USB devices")

            if (usbDevices.isEmpty()) {
                postLog("USB: No USB devices found. Is a printer connected?")
                return printers
            }

            for ((name, device) in usbDevices) {
                try {
                    val vidHex = String.format("%04X", device.vendorId)
                    val pidHex = String.format("%04X", device.productId)
                    val hasPermission = usbManager.hasPermission(device)

                    postLog("USB Device Found:")
                    postLog("  - Name: ${device.deviceName}")
                    postLog("  - VID:PID: $vidHex:$pidHex")
                    postLog("  - Product: ${device.productName ?: "N/A"}")
                    postLog("  - Manufacturer: ${device.manufacturerName ?: "N/A"}")
                    postLog("  - Device Class: ${device.deviceClass}")
                    postLog("  - Interface Count: ${device.interfaceCount}")
                    postLog("  - Permission: ${if (hasPermission) "GRANTED" else "NOT GRANTED"}")

                    // Determine if this is a printer device
                    val isPrinter = isPrinterDevice(device)
                    val usbMode = if (device.deviceClass == UsbConstants.USB_CLASS_PRINTER) "native" else "serial"

                    postLog("  - Is Printer: $isPrinter")
                    postLog("  - USB Mode: $usbMode")

                    val displayName = buildDisplayName(device)

                    printers.add(mutableMapOf<String, Any>().apply {
                        put("id", "usb_${device.deviceId}")
                        put("name", displayName)
                        put("connectionType", "usb")
                        put("usbDeviceId", "$vidHex:$pidHex")
                        put("platformSpecificId", name)
                        put("printerType", "receipt")
                        put("status", if (hasPermission) "ready" else "no_permission")
                        put("modelName", "${device.productName ?: "USB Device"} (VID:$vidHex PID:$pidHex)")
                        put("usbMode", usbMode)
                    })

                    postLog("  ✓ Added to discovery list")

                } catch (e: Exception) {
                    postLog("USB: Error processing device $name: ${e.message}")
                    lastErrorMessage = e.message
                    Log.e("PrinterPlugin", "Error processing USB device", e)
                }
            }

        } catch (e: Exception) {
            postLog("USB: Critical error during discovery: ${e.message}")
            lastErrorMessage = e.message
            Log.e("PrinterPlugin", "USB discovery critical error", e)
        }

        return printers
    }

    private fun discoverBluetoothPrinters(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR2) {
            postLog("Bluetooth: API level too low")
            result.success(emptyList<Map<String, Any>>())
            return
        }

        try {
            postLog("=== Starting Bluetooth Printer Discovery ===")
            val btPrinters = discoverBluetoothPrintersInternal()
            postLog("=== Bluetooth Discovery Complete: ${btPrinters.size} printers ===")
            result.success(btPrinters)
        } catch (e: Exception) {
            postLog("Bluetooth discovery error: ${e.message}")
            Log.e("PrinterPlugin", "Bluetooth discovery failed", e)
            result.error("BLUETOOTH_DISCOVERY_FAILED", "Failed to discover Bluetooth printers: ${e.message}", null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    private fun discoverBluetoothPrintersInternal(): List<Map<String, Any>> {
        val printers = mutableListOf<Map<String, Any>>()

        try {
            val bluetoothAdapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
                bluetoothManager.adapter
            } else {
                @Suppress("DEPRECATION")
                BluetoothAdapter.getDefaultAdapter()
            }

            if (bluetoothAdapter == null) {
                postLog("Bluetooth: No Bluetooth adapter available")
                return printers
            }

            if (!bluetoothAdapter.isEnabled) {
                postLog("Bluetooth: Bluetooth is disabled")
                return printers
            }

            // Ensure runtime permission for accessing bonded devices
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                    postLog("Bluetooth: Missing BLUETOOTH_CONNECT permission; cannot query bonded devices")
                    return printers
                }
            }

            postLog("Bluetooth: Scanning paired devices")
            val pairedDevices = bluetoothAdapter.bondedDevices

            if (pairedDevices.isEmpty()) {
                postLog("Bluetooth: No paired devices found")
                // No paired devices - attempt active discovery (scan) as fallback
                postLog("Bluetooth: Attempting active discovery (scan) as fallback")

                try {
                    val discovered = mutableSetOf<BluetoothDevice>()
                    val discoveryLatch = CountDownLatch(1)

                    val discoveryReceiver = object : BroadcastReceiver() {
                        override fun onReceive(ctx: Context?, intent: Intent?) {
                            if (intent == null) return
                            when (intent.action) {
                                BluetoothDevice.ACTION_FOUND -> {
                                    val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                                    } else {
                                        @Suppress("DEPRECATION")
                                        intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                                    }
                                    device?.let { discovered.add(it) }
                                }
                                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                                    discoveryLatch.countDown()
                                }
                            }
                        }
                    }

                    val filter = IntentFilter().apply {
                        addAction(BluetoothDevice.ACTION_FOUND)
                        addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
                    }

                    context.registerReceiver(discoveryReceiver, filter)
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
                                postLog("Bluetooth: Missing BLUETOOTH_SCAN permission; cannot start discovery")
                            } else {
                                bluetoothAdapter.startDiscovery()
                            }
                        } else {
                            bluetoothAdapter.startDiscovery()
                        }
                    } catch (e: Exception) {
                        postLog("Bluetooth: startDiscovery failed: ${e.message}")
                    }

                    // Wait for discovery to complete (timeout 8s)
                    discoveryLatch.await(8, TimeUnit.SECONDS)

                    try { bluetoothAdapter.cancelDiscovery() } catch (_: Exception) {}
                    try { context.unregisterReceiver(discoveryReceiver) } catch (_: Exception) {}

                    // Convert discovered devices into printers
                    for (device in discovered) {
                        try {
                            val deviceName = device.name ?: "Unknown Device"
                            val isPrinter = isBluetoothPrinter(device)
                            if (isPrinter) {
                                printers.add(mutableMapOf<String, Any>().apply {
                                    put("id", "bt_${device.address.replace(":", "")}")
                                    put("name", deviceName)
                                    put("connectionType", "bluetooth")
                                    put("bluetoothAddress", device.address)
                                    put("platformSpecificId", device.address)
                                    put("printerType", "receipt")
                                    put("status", if (device.bondState == BluetoothDevice.BOND_BONDED) "ready" else "offline")
                                    put("modelName", deviceName)
                                })
                                postLog("  ✓ Discovered and added device: $deviceName")
                            } else {
                                postLog("  ✗ Discovered device not matched as printer: $deviceName")
                            }
                        } catch (e: Exception) {
                            postLog("Bluetooth: Error processing discovered device: ${e.message}")
                        }
                    }

                    if (printers.isEmpty()) {
                        postLog("Bluetooth: No printers matched keywords during scan — adding all discovered devices as fallback")
                        // Add all discovered devices as fallback candidates
                        for (device in discovered) {
                            val deviceName = device.name ?: "Unknown Device"
                            printers.add(mutableMapOf<String, Any>().apply {
                                put("id", "bt_${device.address.replace(":", "")}")
                                put("name", deviceName)
                                put("connectionType", "bluetooth")
                                put("bluetoothAddress", device.address)
                                put("platformSpecificId", device.address)
                                put("printerType", "receipt")
                                put("status", if (device.bondState == BluetoothDevice.BOND_BONDED) "ready" else "offline")
                                put("modelName", deviceName)
                            })
                        }
                    }

                    return printers
                } catch (e: Exception) {
                    postLog("Bluetooth discovery fallback failed: ${e.message}")
                    Log.e("PrinterPlugin", "Active discovery failed", e)
                    return printers
                }
            }

            postLog("Bluetooth: Found ${pairedDevices.size} paired devices")

            for (device in pairedDevices) {
                try {
                    val deviceName = device.name ?: "Unknown Device"
                    postLog("Bluetooth Device Found:")
                    postLog("  - Name: $deviceName")
                    postLog("  - Address: ${device.address}")
                    postLog("  - Bond State: ${device.bondState}")

                    // Check if device name suggests it's a printer
                    val isPrinter = isBluetoothPrinter(device)
                    postLog("  - Is Printer: $isPrinter")

                    if (isPrinter) {
                        printers.add(mutableMapOf<String, Any>().apply {
                            put("id", "bt_${device.address.replace(":", "")}")
                            put("name", deviceName)
                            put("connectionType", "bluetooth")
                            put("bluetoothAddress", device.address)
                            put("platformSpecificId", device.address)
                            put("printerType", "receipt")
                            put("status", if (device.bondState == BluetoothDevice.BOND_BONDED) "ready" else "offline")
                            put("modelName", deviceName)
                        })
                        postLog("  ✓ Added to discovery list")
                    } else {
                        postLog("  ✗ Not a printer, skipping")
                    }
                } catch (e: Exception) {
                    postLog("Bluetooth: Error processing device: ${e.message}")
                    Log.e("PrinterPlugin", "Error processing Bluetooth device", e)
                }
            }

        } catch (e: Exception) {
            postLog("Bluetooth: Critical error during discovery: ${e.message}")
            Log.e("PrinterPlugin", "Bluetooth discovery critical error", e)
        }

        return printers
    }

    private fun discoverNetworkPrinters(result: Result) {
        // Network printers are manually added by the user (IP address + port)
        // No automatic discovery is implemented yet
        postLog("Network: Manual configuration only (no auto-discovery)")
        result.success(emptyList<Map<String, Any>>())
    }

    private fun buildDisplayName(device: UsbDevice): String {
        val manufacturer = device.manufacturerName?.trim() ?: ""
        val product = device.productName?.trim() ?: ""

        return when {
            manufacturer.isNotEmpty() && product.isNotEmpty() -> "$manufacturer $product"
            product.isNotEmpty() -> product
            manufacturer.isNotEmpty() -> "$manufacturer USB Device"
            else -> "USB Device ${device.deviceId}"
        }
    }

    @Deprecated("Use discoverAllPrinters, discoverUsbPrinters, or discoverBluetoothPrinters instead")
    private fun discoverPrinters(result: Result) {
        // Backwards compatibility - redirect to discoverAllPrinters
        discoverAllPrinters(result)
    }

    @Deprecated("No longer used")
    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
    private fun discoverBluetoothPrinters(printers: MutableList<Map<String, Any>>) {
        // Old method signature - no longer used
    }

    @Deprecated("No longer used")
    private fun discoverPosmacPrinters(printers: MutableList<Map<String, Any>>) {
        // POSMAC SDK integration temporarily disabled due to complexity
        // Will be re-implemented if needed
        postLog("POSMAC: SDK integration disabled")
    }

    private fun printReceipt(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val printerId = args["printerId"] as String
        val printerType = args["printerType"] as String
        @Suppress("UNCHECKED_CAST")
        val connectionDetails = args["connectionDetails"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "connectionDetails required", null)
        @Suppress("UNCHECKED_CAST")
        val receiptData = args["receiptData"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "receiptData required", null)
        val paperSize = args["paperSize"] as? String

        try {
            postLog("printReceipt: printerId=$printerId printerType=$printerType paperSize=$paperSize connectionDetails=$connectionDetails")
            var lastErrorMessage: String? = null
            this.lastErrorMessage = null
            
            // Validate connection details before attempting direct print
            val hasValidConnection = when (printerType) {
                "network" -> {
                    val ipAddress = connectionDetails["ipAddress"] as? String
                    (ipAddress != null && ipAddress.isNotEmpty() && ipAddress != "192.168.1.") // Don't accept incomplete default
                }
                "usb" -> {
                    val usbDeviceId = connectionDetails["usbDeviceId"] as? String
                    val platformId = connectionDetails["platformSpecificId"] as? String
                    ((usbDeviceId != null && usbDeviceId.isNotEmpty()) || (platformId != null && platformId.isNotEmpty()))
                }
                "bluetooth" -> {
                    val address = connectionDetails["bluetoothAddress"] as? String
                    (address != null && address.isNotEmpty())
                }
                "posmac" -> true // POSMAC might not need validation
                else -> false
            }
            
            val success = if (hasValidConnection) {
                when (printerType) {
                    "network" -> printToNetworkPrinter(connectionDetails, receiptData, paperSize)
                    "usb" -> printToUsbPrinter(connectionDetails, receiptData, paperSize)
                    "bluetooth" -> printToBluetoothPrinter(connectionDetails, receiptData, paperSize)
                    "posmac" -> printToPosmacPrinter(connectionDetails, receiptData, paperSize)
                    else -> false
                }
            } else {
                postLog("printReceipt: Invalid connection details for $printerType, falling back to external service")
                printViaExternalServiceImpl(receiptData, paperSize)
            }
            
            postLog("printReceipt: result=$success")
            val finalMsg = if (success) "OK" else (lastErrorMessage ?: this.lastErrorMessage ?: "Failed to print")
            result.success(mapOf("success" to success, "message" to finalMsg))
        } catch (e: Exception) {
            postLog("printReceipt error: ${e.message}")
            result.error("PRINT_FAILED", "Failed to print receipt: ${e.message}", null)
        }
    }

    private fun printOrder(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val printerId = args["printerId"] as String
        val printerType = args["printerType"] as String
        @Suppress("UNCHECKED_CAST")
        val connectionDetails = args["connectionDetails"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "connectionDetails required", null)
        @Suppress("UNCHECKED_CAST")
        val orderData = args["orderData"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "orderData required", null)
        val paperSize = args["paperSize"] as? String

        try {
            val success = when (printerType) {
                "network" -> printToNetworkPrinter(connectionDetails, orderData, paperSize)
                "usb" -> printToUsbPrinter(connectionDetails, orderData, paperSize)
                "bluetooth" -> printToBluetoothPrinter(connectionDetails, orderData, paperSize)
                else -> false
            }
            result.success(success)
        } catch (e: Exception) {
            result.error("PRINT_FAILED", "Failed to print order: ${e.message}", null)
        }
    }

    private fun testPrint(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val printerId = args["printerId"] as String
        val printerType = args["printerType"] as String
        @Suppress("UNCHECKED_CAST")
        val connectionDetails = args["connectionDetails"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "connectionDetails required", null)
        val paperSize = args["paperSize"] as? String

        val testData = mapOf(
            "title" to "TEST PRINT",
            "content" to "This is a test print from Flutter POS\n\nPrinter ID: $printerId\nConnection Type: $printerType\n\nTest completed successfully!",
            "timestamp" to System.currentTimeMillis().toString()
        )

        try {
            val success = when (printerType) {
                "network" -> printToNetworkPrinter(connectionDetails, testData, paperSize)
                "usb" -> printToUsbPrinter(connectionDetails, testData, paperSize)
                "bluetooth" -> printToBluetoothPrinter(connectionDetails, testData, paperSize)
                else -> false
            }
            result.success(success)
        } catch (e: Exception) {
            result.error("TEST_PRINT_FAILED", "Test print failed: ${e.message}", null)
        }
    }

    private fun printToPosmacPrinter(connectionDetails: Map<String, Any>, data: Map<String, Any>, paperSize: String?): Boolean {
        if (posmacBinder == null || !isPosmacConnected) {
            postLog("POSMAC: Service not connected")
            return false
        }

        val platformSpecificId = connectionDetails["platformSpecificId"] as? String
        if (platformSpecificId.isNullOrEmpty()) {
            postLog("POSMAC: No platformSpecificId provided")
            return false
        }

        return try {
            // Connect to POSMAC printer
            val connectResult = booleanArrayOf(false)
            posmacBinder!!.connectUsbPort(context, platformSpecificId, object : UiExecute {
                override fun onsucess() {
                    connectResult[0] = true
                    postLog("POSMAC: Connected to USB printer $platformSpecificId")
                }

                override fun onfailed() {
                    connectResult[0] = false
                    postLog("POSMAC: Failed to connect to USB printer $platformSpecificId")
                }
            })

            if (!connectResult[0]) {
                postLog("POSMAC: Connection failed")
                return false
            }

            // Prepare receipt data
            val title = data["title"] as? String ?: "RECEIPT"
            val content = data["content"] as? String ?: ""
            val timestamp = data["timestamp"] as? String ?: ""

            // Format receipt text
            val charsPerLine = when (paperSize) {
                "mm58" -> 32
                "mm80" -> 48
                else -> 48
            }

            val sb = StringBuilder()
            sb.append(title).append('\n')
            sb.append("".padEnd(charsPerLine, '=')).append('\n')
            sb.append(content).append('\n')
            if (timestamp.isNotEmpty()) {
                sb.append("Time: ").append(timestamp).append('\n')
            }
            sb.append("".padEnd(charsPerLine, '=')).append('\n')
            sb.append("Thank you!\n\n\n\n")

            val receiptText = sb.toString()

            // Send print command using POSMAC SDK
            // Note: This is a simplified implementation. You may need to adjust based on POSMAC SDK documentation
            val printResult = booleanArrayOf(false)
            posmacBinder!!.writeDataByYouself(object : UiExecute {
                override fun onsucess() {
                    printResult[0] = true
                    postLog("POSMAC: Print successful")
                }

                override fun onfailed() {
                    printResult[0] = false
                    postLog("POSMAC: Print failed")
                }
            }, {
                // Convert receipt text to bytes - this may need adjustment based on POSMAC requirements
                mutableListOf(receiptText.toByteArray(Charsets.UTF_8))
            })

            // Disconnect
            posmacBinder!!.disconnectCurrentPort(object : UiExecute {
                override fun onsucess() {
                    postLog("POSMAC: Disconnected successfully")
                }

                override fun onfailed() {
                    postLog("POSMAC: Disconnect failed")
                }
            })

            printResult[0]

        } catch (e: Exception) {
            Log.e("PrinterPlugin", "POSMAC print error", e)
            postLog("POSMAC error: ${Log.getStackTraceString(e)}")
            false
        }
    }

    private fun checkPrinterStatus(call: MethodCall, result: Result) {
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as? Map<String, Any> ?: return result.error("INVALID_ARGS", "Arguments must be a map", null)
        val printerType = args["printerType"] as String
        @Suppress("UNCHECKED_CAST")
        val connectionDetails = args["connectionDetails"] as? Map<String, Any> ?: return result.error("INVALID_ARGS", "connectionDetails required", null)

        try {
            val status = when (printerType) {
                "network" -> checkNetworkPrinterStatus(connectionDetails)
                "usb" -> checkUsbPrinterStatus(connectionDetails)
                "bluetooth" -> checkBluetoothPrinterStatus(connectionDetails)
                else -> "offline"
            }
            result.success(status)
        } catch (e: Exception) {
            result.success("error")
        }
    }

    // Network printing implementation - using raw socket for reliability
    @Suppress("UNCHECKED_CAST")
    private fun printToNetworkPrinter(connectionDetails: Map<String, Any>, data: Map<String, Any>, paperSize: String?): Boolean {
        val ipAddress = connectionDetails["ipAddress"] as String
        val port = (connectionDetails["port"] as? Int) ?: 9100

        // Network I/O must run on background thread (Android StrictMode)
        val resultHolder = arrayOf(false)
        val latch = java.util.concurrent.CountDownLatch(1)

        Thread {
            var socket: Socket? = null
            try {
                postLog("NETWORK: preparing print data for $ipAddress:$port")

                // Get paper settings
                val charsPerLine = when (paperSize) {
                    "mm58" -> 32
                    "mm80" -> 48
                    else -> 48
                }

                // Build ESC/POS payload up-front (so retries don't rebuild)
                val output = java.io.ByteArrayOutputStream()
                // ESC @ - Initialize printer
                output.write(0x1B)
                output.write(0x40)

                @Suppress("UNCHECKED_CAST")
                val items = data["items"] as? List<Map<String, Any>>

                if (items != null) {
                    try {
                        buildStructuredReceipt(output, data, charsPerLine)
                    } catch (e: Exception) {
                        // If structured build fails, capture error and fall back to content-based printing
                        lastErrorMessage = e.message ?: "buildStructuredReceipt failed with unknown error"
                        postLog("NETWORK: structured receipt build failed: ${e.message}. Falling back to unstructured content formatting.")
                        val content = data["content"] as? String ?: ""
                        formatReceiptContent(output, content, charsPerLine)
                    }
                } else {
                    val title = data["title"] as? String ?: "RECEIPT"
                    val content = data["content"] as? String ?: ""
                    val timestamp = data["timestamp"] as? String ?: ""
                    val noCut = data["noCut"] as? Boolean ?: false

                    centerAlignBold(output)
                    output.write(0x1D)
                    output.write(0x21)
                    output.write(0x11)
                    output.write(title.toByteArray())
                    output.write('\n'.code)
                    resetFormatting(output)

                    leftAlign(output)
                    output.write(repeatChar('=', charsPerLine).toByteArray())
                    output.write('\n'.code)

                    formatReceiptContent(output, content, charsPerLine)

                    if (timestamp.isNotEmpty()) {
                        output.write('\n'.code)
                        output.write("Time: $timestamp\n".toByteArray())
                    }

                    output.write(repeatChar('=', charsPerLine).toByteArray())
                    output.write('\n'.code)
                    output.write('\n'.code)

                    centerAlign(output)
                    output.write("Thank you!\n".toByteArray())
                    output.write("Please come again\n".toByteArray())
                    
                    // Feed and cut (only for non-structured receipts, unless noCut is true)
                    if (!noCut) {
                        output.write('\n'.code)
                        output.write('\n'.code)
                        output.write('\n'.code)
                        output.write(0x1D)
                        output.write(0x56)
                        output.write(0x42)
                        output.write(0x00)
                    }
                }
                
                // Add cut command for all receipts (buildStructuredReceipt doesn't include it)
                // unless noCut is true
                val noCut = data["noCut"] as? Boolean ?: false
                if (!noCut) {
                    output.write(0x1D)
                    output.write(0x56)
                    output.write(0x42)
                    output.write(0x00)
                }

                val escPosBytes = output.toByteArray()
                // Log a preview of ESC/POS payload (first 200 bytes) for debugging
                try {
                    val previewLen = Math.min(escPosBytes.size, 200)
                    val previewText = String(escPosBytes.copyOfRange(0, previewLen))
                    postLog("NETWORK: ESC/POS payload preview (len=${previewLen}): $previewText")
                } catch (e: Exception) {
                    postLog("NETWORK: Could not build payload preview: ${e.message}")
                }

                // Retry loop with exponential backoff
                val maxRetries = 3
                var attempt = 0
                var lastError: Exception? = null
                var printed = false

                while (attempt < maxRetries && !printed) {
                    attempt += 1
                    try {
                        postLog("NETWORK: attempt $attempt connecting to $ipAddress:$port")
                        socket = Socket()
                        socket.connect(java.net.InetSocketAddress(ipAddress, port), 5000)
                        socket.soTimeout = 10000

                        // Send to printer
                        // Log payload hex preview (first 64 bytes)
                        try {
                            val previewLen = Math.min(escPosBytes.size, 64)
                            val hexPreview = escPosBytes.take(previewLen).joinToString(" ") { String.format("%02X", it.toInt() and 0xFF) }
                            postLog("NETWORK: ESC/POS hex preview (len=${previewLen}): $hexPreview")
                        } catch (e: Exception) {
                            postLog("NETWORK: Could not build ESC/POS hex preview: ${e.message}")
                        }
                        socket.getOutputStream().write(escPosBytes)
                        socket.getOutputStream().flush()

                        postLog("NETWORK: print successful on attempt $attempt, sent ${escPosBytes.size} bytes")
                        resultHolder[0] = true
                        printed = true
                    } catch (e: Exception) {
                        lastErrorMessage = e.message
                        lastError = e
                        Log.e("PrinterPlugin", "NETWORK print attempt $attempt error", e)
                        postLog("NETWORK: attempt $attempt error: ${e.message}")
                        try {
                            socket?.close()
                        } catch (_: Exception) {}
                        socket = null

                        if (attempt < maxRetries) {
                            val backoff = attempt * 1000L
                            postLog("NETWORK: retrying after ${backoff}ms")
                            try { Thread.sleep(backoff) } catch (_: Exception) {}
                        }
                    }
                }

                if (!printed) {
                    Log.e("PrinterPlugin", "NETWORK print error after $maxRetries attempts", lastError)
                    postLog("NETWORK error: Failed after $maxRetries attempts: ${lastError?.message}")
                    lastErrorMessage = lastError?.message
                }

            } catch (e: Exception) {
                Log.e("PrinterPlugin", "NETWORK print error", e)
                postLog("NETWORK error: ${e.message}")
                lastErrorMessage = e.message
            } finally {
                try {
                    socket?.close()
                    postLog("NETWORK: socket closed")
                } catch (e: Exception) {
                    Log.e("PrinterPlugin", "NETWORK close error", e)
                }
                latch.countDown()
            }
        }.start()

        return try {
            latch.await(15, java.util.concurrent.TimeUnit.SECONDS)
            resultHolder[0]
        } catch (e: InterruptedException) {
            postLog("NETWORK: timeout")
            false
        }
    }

    // USB printing implementation using ESCPOS SDK
    @Suppress("UNCHECKED_CAST")
    private fun printToUsbPrinter(connectionDetails: Map<String, Any>, data: Map<String, Any>, paperSize: String?): Boolean {
        try {
            val usbManager = context.getSystemService(Context.USB_SERVICE) as android.hardware.usb.UsbManager

            // Try to locate device by usbDeviceId or platformSpecificId
            val usbDeviceId = (connectionDetails["usbDeviceId"] as? String)
            val platformId = (connectionDetails["platformSpecificId"] as? String)

            var targetDevice: UsbDevice? = null
            for ((_, device) in usbManager.deviceList) {
                if (usbDeviceId != null) {
                    try {
                        if (matchesUsbDevice(device, usbDeviceId)) {
                            targetDevice = device
                            break
                        }
                    } catch (_: Exception) {}
                }
                if (platformId != null) {
                    if (device.deviceName == platformId) {
                        targetDevice = device
                        break
                    }
                }
            }

            if (targetDevice == null) {
                postLog("USB: device not found on deviceList")
                return false
            }

            // If we don't have permission, request it and wait
            if (!usbManager.hasPermission(targetDevice)) {
                val ACTION_USB_PERMISSION = "com.extrotarget.extropos.USB_PERMISSION"
                val pi = PendingIntent.getBroadcast(
                    context, 
                    0, 
                    Intent(ACTION_USB_PERMISSION), 
                    PendingIntent.FLAG_IMMUTABLE
                )

                val latch = java.util.concurrent.CountDownLatch(1)
                val receiver = object : BroadcastReceiver() {
                    override fun onReceive(ctx: Context?, intent: Intent?) {
                        if (intent == null) return
                        if (intent.action == ACTION_USB_PERMISSION) {
                            val granted = intent.getBooleanExtra(android.hardware.usb.UsbManager.EXTRA_PERMISSION_GRANTED, false)
                            postLog("USB permission result: $granted")
                            latch.countDown()
                        }
                    }
                }

                val filter = IntentFilter(ACTION_USB_PERMISSION)
                context.registerReceiver(receiver, filter)
                usbManager.requestPermission(targetDevice, pi)

                try {
                    latch.await(4, java.util.concurrent.TimeUnit.SECONDS)
                } catch (ie: InterruptedException) {}

                try { context.unregisterReceiver(receiver) } catch (e: Exception) {}

                if (!usbManager.hasPermission(targetDevice)) {
                    postLog("USB: permission not granted")
                    lastErrorMessage = "USB: permission not granted"
                    return false
                }
            }

            // Determine USB mode and choose appropriate printing method
            val usbMode = connectionDetails["usbMode"] as? String ?: "native"
            postLog("USB: detected USB mode: $usbMode for device ${targetDevice.productName}")

            return when (usbMode) {
                "serial" -> printViaSerialUsb(usbManager, targetDevice, data, paperSize)
                else -> printViaNativeUsb(usbManager, targetDevice, data, paperSize)
            }

        } catch (e: Exception) {
            Log.e("PrinterPlugin", "USB print error", e)
            postLog("USB error: ${Log.getStackTraceString(e)}")
            lastErrorMessage = e.message
            return false
        }
    }

    // Bluetooth printing implementation using ESCPOS SDK
    @Suppress("UNCHECKED_CAST")
    private fun printToBluetoothPrinter(connectionDetails: Map<String, Any>, data: Map<String, Any>, paperSize: String?): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR2) {
            return false
        }

        val address = connectionDetails["bluetoothAddress"] as String
        
        val adapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            bluetoothManager.adapter
        } else {
            @Suppress("DEPRECATION")
            BluetoothAdapter.getDefaultAdapter()
        }
        
        if (adapter == null) {
            return false
        }

        var btConnection: BluetoothConnection? = null
        return try {
            val device = adapter.getRemoteDevice(address)
            postLog("BLUETOOTH: attempting connect to $address (${device.name}) using ESCPOS SDK")
            
            // Cancel discovery to improve connection reliability
            try { adapter.cancelDiscovery() } catch (_: Exception) {}
            
            // Create Bluetooth connection using ESCPOS SDK
            btConnection = BluetoothConnection(device)
            
            // Get paper width
            val dpi = 203
            val widthMM = when (paperSize) {
                "mm58" -> 58f
                "mm80" -> 80f
                else -> 80f
            }
            val charsPerLine = when (paperSize) {
                "mm58" -> 32
                "mm80" -> 48
                else -> 48
            }
            
            // Build structured ESC/POS bytes first (prefer raw byte writing), fallback to SDK-formatted text
            val escPosBytes = try {
                val baos = java.io.ByteArrayOutputStream()
                buildStructuredReceipt(baos, data, charsPerLine)
                // Add cut command (buildStructuredReceipt doesn't include it)
                baos.write(0x1D)
                baos.write(0x56)
                baos.write(0x42)
                baos.write(0x00)
                baos.toByteArray()
            } catch (e: Exception) {
                lastErrorMessage = e.message
                postLog("BLUETOOTH: structured build failed: ${e.message}; falling back to buildEscPosText")
                null
            }

            if (escPosBytes != null) {
                try {
                    // Attempt raw RFCOMM socket write
                    val sppUuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
                    val socket: BluetoothSocket = device.createRfcommSocketToServiceRecord(sppUuid)
                    try {
                        socket.connect()
                        val output: OutputStream = socket.outputStream
                        output.write(escPosBytes)
                        output.flush()
                        postLog("BLUETOOTH RAW: wrote ${escPosBytes.size} bytes to $address")
                        try { socket.close() } catch (_: Exception) {}
                        return true
                    } catch (rawErr: Exception) {
                        postLog("BLUETOOTH RAW: failed to write raw bytes: ${rawErr.message}")
                        try { socket.close() } catch (_: Exception) {}
                    }
                } catch (rawErr: Exception) {
                    postLog("BLUETOOTH RAW: socket error: ${rawErr.message}")
                }
            }

            val receiptText = try {
                buildEscPosText(data, charsPerLine)
            } catch (e: Exception) {
                lastErrorMessage = e.message
                postLog("BLUETOOTH: buildEscPosText failed: ${e.message}. Falling back to unstructured content.")
                (data["content"] as? String) ?: ""
            }
            try {
                val preview = if (receiptText.length > 200) receiptText.substring(0, 200) + "..." else receiptText
                postLog("USB: payload preview (len=${receiptText.length}): $preview")
            } catch (e: Exception) {
                postLog("USB: Could not build payload preview: ${e.message}")
            }
            try {
                val preview = if (receiptText.length > 200) receiptText.substring(0, 200) + "..." else receiptText
                postLog("BLUETOOTH: payload preview (len=${receiptText.length}): $preview")
            } catch (e: Exception) {
                postLog("BLUETOOTH: Could not build payload preview: ${e.message}")
            }
            
            // Create printer and print
            val printer = EscPosPrinter(
                btConnection,
                dpi,
                widthMM,
                charsPerLine
            )
            
            val noCut = data["noCut"] as? Boolean ?: false
            if (noCut) {
                // For kitchen orders, don't cut paper
                printer.printFormattedText(receiptText)
            } else {
                printer.printFormattedTextAndCut(receiptText)
            }
            postLog("BLUETOOTH: print successful via ESCPOS SDK to $address")
            true
            
        } catch (e: Exception) {
            Log.e("PrinterPlugin", "BLUETOOTH print error", e)
            postLog("BLUETOOTH error: ${Log.getStackTraceString(e)}")
            lastErrorMessage = e.message
            false
        } finally {
            // Always disconnect to release Bluetooth connection
            try {
                btConnection?.disconnect()
                postLog("BLUETOOTH: connection closed")
            } catch (e: Exception) {
                Log.e("PrinterPlugin", "BLUETOOTH disconnect error", e)
            }
        }
    }

    // Status checking implementations
    @Suppress("UNCHECKED_CAST")
    private fun checkNetworkPrinterStatus(connectionDetails: Map<String, Any>): String {
        val ipAddress = connectionDetails["ipAddress"] as String
        val port = (connectionDetails["port"] as? Int) ?: 9100

        // Network I/O must run on background thread
        val resultHolder = arrayOf("offline")
        val latch = java.util.concurrent.CountDownLatch(1)

        Thread {
            try {
                val socket = Socket()
                try {
                    socket.connect(java.net.InetSocketAddress(ipAddress, port), 5000)
                    socket.soTimeout = 5000
                    resultHolder[0] = if (socket.isConnected) "online" else "offline"
                } catch (e: Exception) {
                    Log.d("PrinterPlugin", "checkNetworkPrinterStatus connect error: ${e.message}")
                    resultHolder[0] = "offline"
                } finally {
                    try { socket.close() } catch (_: Exception) {}
                }
            } catch (e: Exception) {
                resultHolder[0] = "offline"
            } finally {
                latch.countDown()
            }
        }.start()

        return try {
            latch.await(6, java.util.concurrent.TimeUnit.SECONDS)
            resultHolder[0]
        } catch (e: InterruptedException) {
            "offline"
        }
    }

    @Suppress("UNUSED_PARAMETER")
    private fun checkUsbPrinterStatus(connectionDetails: Map<String, Any>): String {
        // USB status checking requires permission handling
        return "offline"
    }

    @Suppress("UNCHECKED_CAST")
    private fun checkBluetoothPrinterStatus(connectionDetails: Map<String, Any>): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR2) {
            return "offline"
        }

        val address = connectionDetails["bluetoothAddress"] as String
        
        val adapter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            bluetoothManager.adapter
        } else {
            @Suppress("DEPRECATION")
            BluetoothAdapter.getDefaultAdapter()
        }
        
        if (adapter == null) {
            return "offline"
        }

        return try {
            val device = adapter.getRemoteDevice(address)
            if (device.bondState == BluetoothDevice.BOND_BONDED) "online" else "offline"
        } catch (e: Exception) {
            "offline"
        }
    }

    /**
     * Build ESC/POS formatted text using the ESCPOS SDK's text formatting syntax.
     * 
     * The SDK supports tags like:
     * [C] - Center align
     * [L] - Left align
     * [R] - Right align
     * <b> - Bold
     * <u> - Underline
     * <font size='big'> - Large text
     * <font size='tall'> - Tall text
     * <font size='wide'> - Wide text
     */
    @Suppress("UNCHECKED_CAST")
    private fun buildEscPosText(data: Map<String, Any>, charsPerLine: Int): String {
        val title = data["title"] as? String ?: "RECEIPT"
        val content = data["content"] as? String ?: ""
        val timestamp = data["timestamp"] as? String ?: ""

        val sb = StringBuilder()
        
        // Header
        sb.append("[C]<b>") // Center align + bold
        sb.append("<font size='big'>")
        sb.append(title)
        sb.append("</font></b>\n")
        
        // Separator
        sb.append("[L]") // Left align
        sb.append(repeatChar('=', charsPerLine))
        sb.append("\n")
        
        // Format content intelligently
        val lines = content.split("\n")
        for (line in lines) {
            if (line.trim().isEmpty()) {
                sb.append("\n")
                continue
            }
            
            // Item lines with prices
            if (line.contains(" x ")) {
                sb.append(formatItemLineForSdk(line, charsPerLine))
            }
            // Total/subtotal lines
            else if (line.contains("RM") || line.contains("Subtotal:") || line.contains("Tax") || 
                     line.contains("Service") || line.contains("Total:") || 
                     line.contains("Payment:") || line.contains("Paid:") || line.contains("Change:")) {
                sb.append(formatTotalLineForSdk(line, charsPerLine))
            }
            else {
                sb.append(line)
                sb.append("\n")
            }
        }
        
        // Timestamp
        if (timestamp.isNotEmpty()) {
            sb.append("\n")
            sb.append("[L]<font size='small'>")
            sb.append("Time: $timestamp")
            sb.append("</font>\n")
        }
        
        // Footer separator
        sb.append(repeatChar('=', charsPerLine))
        sb.append("\n\n")
        
        // Thank you message
        sb.append("[C]")
        sb.append("Thank you!\n")
        sb.append("Please come again\n")
        sb.append("\n")
        
        return sb.toString()
    }

    private fun formatItemLineForSdk(line: String, charsPerLine: Int): String {
        try {
            val parts = line.split(" x ")
            if (parts.size < 2) return "$line\n"
            
            val itemName = parts[0].trim()
            val remaining = parts[1].trim()
            
            val priceIndex = remaining.lastIndexOf("RM")
            if (priceIndex == -1) return "$line\n"
            
            val qtyPart = remaining.substring(0, priceIndex).trim()
            val pricePart = remaining.substring(priceIndex).trim()
            
            return if (charsPerLine >= 48) {
                // 80mm: aligned on one line
                val leftPart = "$itemName x $qtyPart"
                padRight(leftPart, charsPerLine - pricePart.length) + pricePart + "\n"
            } else {
                // 58mm: stack on two lines
                "$itemName x $qtyPart\n" + padLeft(pricePart, charsPerLine) + "\n"
            }
        } catch (e: Exception) {
            return "$line\n"
        }
    }

    private fun formatTotalLineForSdk(line: String, charsPerLine: Int): String {
        try {
            val colonIndex = line.indexOf(':')
            if (colonIndex == -1) return "$line\n"
            
            val label = line.substring(0, colonIndex + 1).trim()
            val value = line.substring(colonIndex + 1).trim()
            
            return padRight(label, charsPerLine - value.length) + value + "\n"
        } catch (e: Exception) {
            return "$line\n"
        }
    }


    private fun isPrinterDevice(device: UsbDevice): Boolean {
        // Check device class or first interface class for printer (class 7)
        if (device.deviceClass == UsbConstants.USB_CLASS_PRINTER) return true
        
        // Check interfaces
        if (device.interfaceCount > 0) {
            val firstInterface = device.getInterface(0)
            if (firstInterface.interfaceClass == UsbConstants.USB_CLASS_PRINTER) return true
        }
        
        // Check common printer vendor IDs
        val printerVendorIds = setOf(
            0x04B8, // Epson
            0x0519, // Star Micronics
            0x2730, // Citizen
            0x0DD4, // Sewoo Tech
            0x0483, // STMicroelectronics (used in many thermal printers)
            0x0416, // WINBOND
            0x28E9, // GonHun
            0x0FE6, // ICS Advent
            0x06EA, // Silex
        )
        
        return printerVendorIds.contains(device.vendorId)
    }

    private fun isBluetoothPrinter(device: BluetoothDevice): Boolean {
        val name = device.name?.lowercase() ?: ""
        val printerKeywords = setOf(
            "printer", "receipt", "thermal", "pos",
            "epson", "star", "citizen", "bixolon",
            "sewoo", "custom", "rongta", "xprinter"
        )
        return printerKeywords.any { name.contains(it) }
    }

    // USB matching helpers
    private fun matchesUsbDevice(device: UsbDevice, identifier: String): Boolean {
        val id = identifier.trim()
        // Support VID:PID (hex or decimal), with optional VID/PID or 0x prefixes
        if (id.contains(":")) {
            val parts = id.split(":")
            if (parts.size >= 2) {
                val vidCandidates = parseUsbIdCandidates(parts[0])
                val pidCandidates = parseUsbIdCandidates(parts[1])
                return vidCandidates.contains(device.vendorId) && pidCandidates.contains(device.productId)
            }
            return false
        }

        // Otherwise, treat as Android UsbDevice.deviceId (decimal string)
        return try {
            val dec = id.toInt()
            device.deviceId == dec
        } catch (_: Exception) {
            false
        }
    }

    private fun parseUsbIdCandidates(raw: String): Set<Int> {
        val set = mutableSetOf<Int>()
        var token = raw.trim()
        if (token.isEmpty()) return emptySet()

        // Normalize: remove common prefixes and non-hex characters for a hex candidate
        val cleanedHex = token.uppercase(java.util.Locale.ROOT)
            .replace("VID", "")
            .replace("PID", "")
            .replace("0X", "")
            .replace(Regex("[^0-9A-F]"), "")

        if (cleanedHex.isNotEmpty()) {
            // If contains A-F letters, it's clearly hex
            val hasHexLetters = cleanedHex.any { it in 'A'..'F' }
            if (hasHexLetters) {
                parseIntSafe(cleanedHex, 16)?.let { set.add(it) }
            } else {
                // Could be either decimal or hex; try both
                parseIntSafe(cleanedHex, 10)?.let { set.add(it) }
                parseIntSafe(cleanedHex, 16)?.let { set.add(it) }
            }
        }

        // Also try raw decimal as-is if it was not purely hex-cleaned
        token = raw.trim()
        if (token.matches(Regex("^\\d+$"))) {
            parseIntSafe(token, 10)?.let { set.add(it) }
        }

        return set
    }

    private fun parseIntSafe(value: String, radix: Int): Int? {
        return try { Integer.parseInt(value, radix) } catch (_: Exception) { null }
    }

    // ESC/POS formatting helpers
    private fun centerAlign(output: java.io.ByteArrayOutputStream) {
        output.write(0x1B)
        output.write(0x61)
        output.write(1) // Center
    }

    private fun leftAlign(output: java.io.ByteArrayOutputStream) {
        output.write(0x1B)
        output.write(0x61)
        output.write(0) // Left
    }

    private fun centerAlignBold(output: java.io.ByteArrayOutputStream) {
        output.write(0x1B)
        output.write(0x61)
        output.write(1) // Center
        output.write(0x1B)
        output.write(0x45)
        output.write(1) // Bold on
    }

    private fun bold(output: java.io.ByteArrayOutputStream) {
        output.write(0x1B)
        output.write(0x45)
        output.write(1) // Bold on
    }

    private fun resetFormatting(output: java.io.ByteArrayOutputStream) {
        output.write(0x1B)
        output.write(0x45)
        output.write(0) // Bold off
        output.write(0x1D)
        output.write(0x21)
        output.write(0) // Normal size
        output.write(0x1B)
        output.write(0x61)
        output.write(0) // Left align
    }

    private fun repeatChar(char: Char, count: Int): String {
        return char.toString().repeat(count)
    }

    private fun padRight(text: String, width: Int): String {
        return if (text.length >= width) text.substring(0, width)
        else text + " ".repeat(width - text.length)
    }

    private fun padLeft(text: String, width: Int): String {
        return if (text.length >= width) text.substring(0, width)
        else " ".repeat(width - text.length) + text
    }

    private fun formatReceiptContent(output: java.io.ByteArrayOutputStream, content: String, charsPerLine: Int) {
        // Parse receipt content and format nicely
        val lines = content.split("\n")
        
        for (line in lines) {
            if (line.trim().isEmpty()) {
                output.write('\n'.code)
                continue
            }
            
            // Check if it's an item line (contains "x " pattern)
            if (line.contains(" x ")) {
                formatItemLine(output, line, charsPerLine)
            }
            // Check if it's a total/subtotal line (contains currency symbol)
            else if (line.contains("RM") || line.contains("Subtotal:") || line.contains("Tax") || 
                     line.contains("Service") || line.contains("Total:") || 
                     line.contains("Payment:") || line.contains("Paid:") || line.contains("Change:")) {
                formatTotalLine(output, line, charsPerLine)
            }
            else {
                // Regular line - just print as is
                output.write(line.toByteArray())
                output.write('\n'.code)
            }
        }
    }

    private fun formatItemLine(output: java.io.ByteArrayOutputStream, line: String, charsPerLine: Int) {
        // Parse: "Item Name x Qty RM Price"
        // Example: "Nasi Lemak x 2 RM 12.00"
        
        try {
            val parts = line.split(" x ")
            if (parts.size < 2) {
                output.write(line.toByteArray())
                output.write('\n'.code)
                return
            }
            
            val itemName = parts[0].trim()
            val remaining = parts[1].trim()
            
            // Find the price (last RM occurrence)
            val priceIndex = remaining.lastIndexOf("RM")
            if (priceIndex == -1) {
                output.write(line.toByteArray())
                output.write('\n'.code)
                return
            }
            
            val qtyPart = remaining.substring(0, priceIndex).trim()
            val pricePart = remaining.substring(priceIndex).trim()
            
            // Format based on paper width
            if (charsPerLine >= 48) {
                // 80mm: "Item Name x Qty         RM 12.00"
                val leftPart = "$itemName x $qtyPart"
                val formatted = padRight(leftPart, charsPerLine - pricePart.length) + pricePart
                output.write(formatted.toByteArray())
            } else {
                // 58mm: Stack on two lines
                output.write("$itemName x $qtyPart\n".toByteArray())
                output.write(padLeft(pricePart, charsPerLine).toByteArray())
            }
            output.write('\n'.code)
        } catch (e: Exception) {
            // Fallback: just print the line as is
            output.write(line.toByteArray())
            output.write('\n'.code)
        }
    }

    private fun formatTotalLine(output: java.io.ByteArrayOutputStream, line: String, charsPerLine: Int) {
        // Parse lines like "Subtotal: RM 24.00"
        try {
            val colonIndex = line.indexOf(':')
            if (colonIndex == -1) {
                output.write(line.toByteArray())
                output.write('\n'.code)
                return
            }
            
            val label = line.substring(0, colonIndex + 1).trim()
            val value = line.substring(colonIndex + 1).trim()
            
            // Right-align value
            val formatted = padRight(label, charsPerLine - value.length) + value
            output.write(formatted.toByteArray())
            output.write('\n'.code)
        } catch (e: Exception) {
            output.write(line.toByteArray())
            output.write('\n'.code)
        }
    }

    private fun printViaNativeUsb(usbManager: UsbManager, device: UsbDevice, data: Map<String, Any>, paperSize: String?): Boolean {
        // Use ESCPOS SDK's UsbConnection for native USB printing
        postLog("USB: printing via native USB mode using ESCPOS SDK")
        val usbConnection = UsbConnection(usbManager, device)

        try {
            // Get paper width
            val dpi = 203
            val widthMM = when (paperSize) {
                "mm58" -> 58f
                "mm80" -> 80f
                else -> 80f
            }
            val charsPerLine = when (paperSize) {
                "mm58" -> 32
                "mm80" -> 48
                else -> 48
            }

            // Build structured ESC/POS bytes first - prefer writing raw bytes directly to USB device
            val escPosBytes = try {
                val baos = java.io.ByteArrayOutputStream()
                buildStructuredReceipt(baos, data, charsPerLine)
                // Add cut command (buildStructuredReceipt doesn't include it)
                baos.write(0x1D)
                baos.write(0x56)
                baos.write(0x42)
                baos.write(0x00)
                baos.toByteArray()
            } catch (e: Exception) {
                this.lastErrorMessage = e.message
                postLog("USB: structured build failed for USB/Bluetooth: ${e.message}; falling back to buildEscPosText")
                null
            }

            // If we have raw bytes, try to write them directly using UsbDeviceConnection.bulkTransfer
            if (escPosBytes != null) {
                try {
                    // Attempt raw write to device using UsbManager
                    val conn = usbManager.openDevice(device) ?: throw Exception("USB openDevice returned null")
                    var success = false
                    // Claim interface and find OUT endpoint
                    for (i in 0 until device.interfaceCount) {
                        val intf = device.getInterface(i)
                        if (conn.claimInterface(intf, true)) {
                            for (e in 0 until intf.endpointCount) {
                                val ep = intf.getEndpoint(e)
                                if (ep.direction == UsbConstants.USB_DIR_OUT) {
                                    val transferred = conn.bulkTransfer(ep, escPosBytes, escPosBytes.size, 5000)
                                    postLog("USB RAW: bulkTransfer returned $transferred bytes")
                                    if (transferred >= 0) success = true
                                    break
                                }
                            }
                            try { conn.releaseInterface(intf) } catch (_: Exception) {}
                            if (success) break
                        }
                    }
                    try { conn.close() } catch (_: Exception) {}
                    if (success) {
                        postLog("USB RAW: printed ${escPosBytes.size} bytes successfully")
                        return true
                    } else {
                        postLog("USB RAW: bulkTransfer failed, falling back to SDK");
                    }
                } catch (rawErr: Exception) {
                    postLog("USB RAW: error writing raw bytes: ${rawErr.message}")
                    this.lastErrorMessage = rawErr.message
                }
            }

            // Build receipt text fallback (SDK formatted string)
            val receiptText = try {
                // If items exist, try to construct SDK-formatted text from structured receipt
                if (data["items"] != null) {
                    try {
                        // Attempt to build structured bytes and convert to a best-effort string; if that fails, buildEscPosText
                        val baos = java.io.ByteArrayOutputStream()
                        buildStructuredReceipt(baos, data, charsPerLine)
                        // Convert bytes to string for SDK printing; if non-text bytes present, fall back to buildEscPosText
                        val structuredStr = try { String(baos.toByteArray()) } catch (_: Exception) { null }
                        structuredStr ?: buildEscPosText(data, charsPerLine)
                    } catch (e: Exception) {
                        this.lastErrorMessage = e.message
                        postLog("USB: structured build failed for USB/Bluetooth: ${e.message}; falling back to buildEscPosText")
                        buildEscPosText(data, charsPerLine)
                    }
                } else {
                    buildEscPosText(data, charsPerLine)
                }
            } catch (e: Exception) {
                lastErrorMessage = e.message
                postLog("USB/BLUETOOTH: buildEscPosText failed: ${e.message}. Falling back to unstructured content.")
                (data["content"] as? String) ?: ""
            }

            // Create printer and print (SDK-formatted string fallback)
            val printer = EscPosPrinter(
                usbConnection,
                dpi,
                widthMM,
                charsPerLine
            )

            val noCut = data["noCut"] as? Boolean ?: false
            if (noCut) {
                // For kitchen orders, don't cut paper
                printer.printFormattedText(receiptText)
            } else {
                printer.printFormattedTextAndCut(receiptText)
            }
            postLog("USB: native USB print successful via ESCPOS SDK")
            return true
        } finally {
            // Always disconnect to release USB connection
            try {
                usbConnection.disconnect()
                postLog("USB: native USB connection closed")
            } catch (e: Exception) {
                Log.e("PrinterPlugin", "USB native disconnect error", e)
            }
        }
    }

    private fun printViaSerialUsb(usbManager: UsbManager, device: UsbDevice, data: Map<String, Any>, paperSize: String?): Boolean {
        // For now, fall back to native USB printing for serial devices
        // TODO: Implement proper serial-over-USB printing
        postLog("USB: serial USB printing not yet implemented, falling back to native USB")
        return printViaNativeUsb(usbManager, device, data, paperSize)
    }

    private fun buildEscPosByteCommands(data: Map<String, Any>, charsPerLine: Int): ByteArray {
        // Simplified ESC/POS command generation
        val content = data["content"] as? String ?: ""
        val output = java.io.ByteArrayOutputStream()

        // Initialize printer
        output.write(byteArrayOf(0x1B, 0x40)) // ESC @

        // Print content
        output.write(content.toByteArray())
        output.write('\n'.code)

        // Cut paper
        output.write(byteArrayOf(0x1D, 0x56, 0x42, 0x00)) // GS V B NUL

        return output.toByteArray()
    }

    @Suppress("UNCHECKED_CAST")
    private fun buildStructuredReceipt(output: java.io.ByteArrayOutputStream, data: Map<String, Any>, charsPerLine: Int) {
        // Extract data
        val storeName = data["store_name"] as? String ?: data["businessName"] as? String ?: "STORE"
        val address = (data["address"] as? List<*>)?.joinToString("\n") ?: data["address"] as? String ?: ""
        
        // Handle date/time - can be combined or separate
        val dateTime = data["dateTime"] as? String ?: run {
            val date = data["date"] as? String ?: ""
            val time = data["time"] as? String ?: ""
            if (date.isNotEmpty() && time.isNotEmpty()) "$date $time" else date
        }
        
        // Handle order number from multiple possible fields
        val orderNumber = data["orderNumber"] as? String 
            ?: data["bill_no"]?.toString() 
            ?: data["order_number"]?.toString() 
            ?: ""
        
        val currency = data["currency"] as? String ?: "RM"
        val items = data["items"] as? List<Map<String, Any>> ?: emptyList()
        fun toDoubleSafe(v: Any?): Double {
            return when (v) {
                is Number -> v.toDouble()
                is String -> v.toDoubleOrNull() ?: 0.0
                else -> 0.0
            }
        }
        fun toIntSafe(v: Any?): Int {
            return when (v) {
                is Number -> v.toInt()
                is String -> v.toIntOrNull() ?: 1
                else -> 1
            }
        }

        val subtotal = if (data["subtotal"] != null) toDoubleSafe(data["subtotal"]) else toDoubleSafe(data["sub_total_amt"])
        
        // Handle tax - can be a number or array of tax objects
        val tax = if (data["tax"] != null) toDoubleSafe(data["tax"]) else run {
            val taxesArray = data["taxes"] as? List<Map<String, Any>>
            taxesArray?.sumOf { toDoubleSafe(it["amt"]) } ?: 0.0
        }
        
        val serviceCharge = if (data["serviceCharge"] != null) toDoubleSafe(data["serviceCharge"]) else toDoubleSafe(data["service_charge"])
        val total = if (data["total"] != null) toDoubleSafe(data["total"]) else 0.0
        val paymentMethod = data["paymentMethod"] as? String ?: data["payment_mode"] as? String ?: "Cash"
        val amountPaid = if (data["amountPaid"] != null) toDoubleSafe(data["amountPaid"]) else if (data["cash_tendered"] != null) toDoubleSafe(data["cash_tendered"]) else total
        val change = if (data["change"] != null) toDoubleSafe(data["change"]) else 0.0
        
        // Header - Business Name (Bold, Double Size, Centered)
        centerAlignBold(output)
        output.write(0x1D)
        output.write(0x21)
        output.write(0x11) // Double height + width
        output.write(storeName.toByteArray())
        output.write('\n'.code)
        resetFormatting(output)
        
        // Address (Centered)
        centerAlign(output)
        if (address.isNotEmpty()) {
            address.split("\n").forEach { line ->
                if (line.isNotEmpty()) {
                    output.write(line.toByteArray())
                    output.write('\n'.code)
                }
            }
        }
        
        // Order Number (Centered, Bold)
        if (orderNumber.isNotEmpty()) {
            output.write('\n'.code)
            bold(output)
            output.write("Order #$orderNumber".toByteArray())
            output.write('\n'.code)
            resetFormatting(output)
        }
        
        // Date/Time
        if (dateTime.isNotEmpty()) {
            output.write(dateTime.toByteArray())
            output.write('\n'.code)
        }
        output.write('\n'.code)
        
        // Separator
        leftAlign(output)
        output.write(repeatChar('-', charsPerLine).toByteArray())
        output.write('\n'.code)
        
        // Items
        for (item in items) {
            val name = item["name"] as? String ?: ""
            val qty = if (item["qty"] != null) toIntSafe(item["qty"]) else toIntSafe(item["quantity"])
            val price = if (item["amt"] != null) toDoubleSafe(item["amt"]) else toDoubleSafe(item["total"])
            
            // Format: "Item Name x Qty      RM Price"
            val itemLine = "$name x $qty"
            val priceStr = "$currency ${String.format("%.2f", price)}"
            
            if (charsPerLine >= 48) {
                // 80mm paper - single line
                val spaces = charsPerLine - itemLine.length - priceStr.length
                val padding = if (spaces > 0) " ".repeat(spaces) else " "
                output.write("$itemLine$padding$priceStr\n".toByteArray())
            } else {
                // 58mm paper - two lines
                output.write("$itemLine\n".toByteArray())
                output.write("${" ".repeat(charsPerLine - priceStr.length)}$priceStr\n".toByteArray())
            }
            
            // Modifiers (if any)
            val modifiers = item["modifiers"] as? List<Map<String, Any>>
            if (modifiers != null && modifiers.isNotEmpty()) {
                for (mod in modifiers) {
                    val modName = mod["name"] as? String ?: ""
                    val modPrice = toDoubleSafe(mod["priceAdjustment"]) 
                    if (modName.isNotEmpty()) {
                        val modText = if (modPrice != 0.0) {
                            "  + $modName ($currency ${String.format("%.2f", modPrice)})"
                        } else {
                            "  + $modName"
                        }
                        output.write("$modText\n".toByteArray())
                    }
                }
            }
        }
        
        // Separator
        output.write(repeatChar('-', charsPerLine).toByteArray())
        output.write('\n'.code)
        
        // Totals
        printTotalLine(output, "Subtotal:", subtotal, currency, charsPerLine)
        if (tax > 0) {
            printTotalLine(output, "Tax:", tax, currency, charsPerLine)
        }
        if (serviceCharge > 0) {
            printTotalLine(output, "Service Charge:", serviceCharge, currency, charsPerLine)
        }
        
        output.write(repeatChar('-', charsPerLine).toByteArray())
        output.write('\n'.code)
        
        // Total (Bold)
        bold(output)
        printTotalLine(output, "TOTAL:", total, currency, charsPerLine)
        resetFormatting(output)
        
        output.write('\n'.code)
        
        // Payment Info
        printTotalLine(output, "Payment:", 0.0, paymentMethod, charsPerLine, true)
        printTotalLine(output, "Amount Paid:", amountPaid, currency, charsPerLine)
        if (change > 0) {
            printTotalLine(output, "Change:", change, currency, charsPerLine)
        }
        
        // Footer
        output.write('\n'.code)
        output.write(repeatChar('=', charsPerLine).toByteArray())
        output.write('\n'.code)
        output.write('\n'.code)
        centerAlign(output)
        output.write("Thank You!\n".toByteArray())
        output.write("Please Come Again\n".toByteArray())
        
        // Feed lines (cut command will be added by caller)
        output.write('\n'.code)
        output.write('\n'.code)
        output.write('\n'.code)
    }

    // Public helper for unit tests - safely build structured or fallback to content formatting if structured fails
    fun buildStructuredReceiptSafe(data: Map<String, Any>, charsPerLine: Int): ByteArray {
        val output = java.io.ByteArrayOutputStream()
        try {
            buildStructuredReceipt(output, data, charsPerLine)
        } catch (e: Exception) {
            // Capture error and fallback to unstructured formatting
            postLog("buildStructuredReceiptSafe: exception during structured build: ${e.message}, falling back to content formatting")
            val content = data["content"] as? String ?: ""
            try {
                formatReceiptContent(output, content, charsPerLine)
            } catch (inner: Exception) {
                postLog("buildStructuredReceiptSafe: fallback formatting also failed: ${inner.message}")
            }
        }
        return output.toByteArray()
    }
    
    private fun printTotalLine(output: java.io.ByteArrayOutputStream, label: String, amount: Double, currency: String, charsPerLine: Int, isText: Boolean = false) {
        val valueStr = if (isText) {
            currency // When isText=true, currency parameter is actually the text value
        } else {
            "$currency ${String.format("%.2f", amount)}"
        }
        val spaces = charsPerLine - label.length - valueStr.length
        val padding = if (spaces > 0) " ".repeat(spaces) else " "
        output.write("$label$padding$valueStr\n".toByteArray())
    }
}

