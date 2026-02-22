#include "printer_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <vector>

#include "utils.h"
#include <sstream>
#include <iomanip>
#include <cstdint>

void PrinterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
    auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "com.extrotarget.extropos/printer",
        &flutter::StandardMethodCodec::GetInstance());
    auto netChannel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "net.nfet.printing",
            &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<PrinterPlugin>();
  // Keep channel so plugin can post logs back to Dart
  plugin->channel_ = std::move(channel);
  // Add a second channel to support existing Windows flutter plugin API surface
  plugin->net_channel_ = std::move(netChannel);

  plugin->channel_->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  plugin->net_channel_->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  // Post a registration log before adding the plugin to the registrar so the message
  // can be observed in Dart logs if the channels are set up properly.
  try {
    plugin->PostLog("RUNNER", "PrinterPlugin: Registered with registrar");
  } catch(...) {
    // Ignore logging failures during registration
  }
  registrar->AddPlugin(std::move(plugin));
}

PrinterPlugin::PrinterPlugin() : usbHandle_(NULL), isPrinterConnected_(false), 
                               networkSocket_(INVALID_SOCKET), isNetworkPrinterConnected_(false) {}

PrinterPlugin::~PrinterPlugin() {
  if (usbHandle_ != NULL) {
    CloseUsb(usbHandle_);
    usbHandle_ = NULL;
  }
  
  if (networkSocket_ != INVALID_SOCKET) {
    CloseNetPor(&networkSocket_);
    networkSocket_ = INVALID_SOCKET;
  }
  
  CloseNetServ();
}

void PrinterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("discoverPrinters") == 0) {
    // Try to open USB printer
    if (usbHandle_ == NULL) {
      usbHandle_ = OpenUsb();
    }
    
    flutter::EncodableList printers;
    if (usbHandle_ != NULL && usbHandle_ != INVALID_HANDLE_VALUE) {
      isPrinterConnected_ = true;
      
      // Create printer info map
      flutter::EncodableMap printerInfo;
      printerInfo[flutter::EncodableValue("name")] = flutter::EncodableValue("POSMAC USB Printer");
      printerInfo[flutter::EncodableValue("address")] = flutter::EncodableValue("USB");
      printerInfo[flutter::EncodableValue("type")] = flutter::EncodableValue("posmac");
      
      printers.push_back(flutter::EncodableValue(printerInfo));
    } else {
      isPrinterConnected_ = false;
    }
    
    result->Success(flutter::EncodableValue(printers));
  } else if (method_call.method_name().compare("initialize") == 0) {
    // Simple initialize used by Windows provider channels; return success to indicate plugin is alive
    result->Success(flutter::EncodableValue(true));
    return;
  } else if (method_call.method_name().compare("getPluginName") == 0) {
    result->Success(flutter::EncodableValue(std::string("RunnerPrinterPlugin")));
    return;
  } else if (method_call.method_name().compare("printReceipt") == 0) {
    // Get the arguments
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Check printer type and connection details
    auto printerType_it = arguments->find(flutter::EncodableValue("printerType"));
    auto connectionDetails_it = arguments->find(flutter::EncodableValue("connectionDetails"));
    
    if (printerType_it == arguments->end() || connectionDetails_it == arguments->end()) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    const auto* printerType = std::get_if<std::string>(&printerType_it->second);
    const auto* connectionDetails = std::get_if<flutter::EncodableMap>(&connectionDetails_it->second);
    
    if (!printerType || !connectionDetails) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Get receipt data
    auto receipt_it = arguments->find(flutter::EncodableValue("receiptData"));
    if (receipt_it == arguments->end()) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    const auto* receipt_data_map = std::get_if<flutter::EncodableMap>(&receipt_it->second);
    if (!receipt_data_map) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    auto content_it = receipt_data_map->find(flutter::EncodableValue("content"));
    if (content_it == receipt_data_map->end()) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    const auto* receipt_content = std::get_if<std::string>(&content_it->second);
    if (!receipt_content) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    bool success = false;
    // Determine approximate chars per line from paper size if available (default 48)
    int charsPerLine = 48;
    auto paperSize_it = arguments->find(flutter::EncodableValue("paperSize"));
    if (paperSize_it != arguments->end()) {
      const auto* paperSize = std::get_if<std::string>(&paperSize_it->second);
      if (paperSize) {
        if (*paperSize == "mm58") charsPerLine = 32;
        else if (*paperSize == "mm80") charsPerLine = 48;
      }
    }

    // Handle different printer types
    if (*printerType == "network") {
      // Network printer
      auto ip_it = connectionDetails->find(flutter::EncodableValue("ipAddress"));
      auto port_it = connectionDetails->find(flutter::EncodableValue("port"));
      
      if (ip_it != connectionDetails->end() && port_it != connectionDetails->end()) {
        const auto* ipAddress = std::get_if<std::string>(&ip_it->second);
        const auto* port = std::get_if<int32_t>(&port_it->second);
        
        if (ipAddress && port) {
          // Initialize network service if not already done
          if (!InitNetSev()) {
            result->Success(flutter::EncodableValue(false));
            return;
          }
          
          // Set up network address
          memset(&networkAddr_, 0, sizeof(networkAddr_));
          networkAddr_.sin_family = AF_INET;
          networkAddr_.sin_port = htons(static_cast<u_short>(*port));
          networkAddr_.sin_addr.s_addr = inet_addr(ipAddress->c_str());
          
          // Set timeout
          timeval timeout;
          timeout.tv_sec = 5;  // 5 second timeout
          timeout.tv_usec = 0;
          
          // Connect to network printer
          int connectResult = ConnectNetPort(&networkSocket_, &networkAddr_, &timeout);
            if (connectResult == 0) {  // Success
            isNetworkPrinterConnected_ = true;
            
            // If structured data present, try to build ESC/POS bytes; fallback to raw content
            std::vector<uint8_t> bytesToSend;
            try {
              auto itemsIt = receipt_data_map->find(flutter::EncodableValue("items"));
              if (itemsIt != receipt_data_map->end()) {
                // Build structured ESC/POS text (or fallback to content)
                std::vector<uint8_t> structured = BuildStructuredEscPosBytes(*receipt_data_map, charsPerLine);
                if (structured.empty()) {
                  PostLog("NETWORK", "buildStructured receipt returned empty; falling back to content");
                  for (char c: *receipt_content) bytesToSend.push_back(static_cast<uint8_t>(c));
                } else {
                  PostLog("NETWORK", "Using structured receipt content for printing (preview) ");
                  bytesToSend = structured;
                }
              } else {
                for (char c: *receipt_content) bytesToSend.push_back(static_cast<uint8_t>(c));
              }
            } catch (const std::exception& e) {
              PostLog("NETWORK", std::string("Structured build failed: ") + e.what() + ". Falling back to content.");
              for (char c: *receipt_content) bytesToSend.push_back(static_cast<uint8_t>(c));
            } catch (...) {
              PostLog("NETWORK", "Structured build failed with unknown exception; falling back to content.");
              for (char c: *receipt_content) bytesToSend.push_back(static_cast<uint8_t>(c));
            }

            int writeResult = WriteToNetPort(&networkSocket_, 
                                           reinterpret_cast<char*>(bytesToSend.data()), 
                                           static_cast<DWORD>(bytesToSend.size()));
            success = (writeResult == 0);  // 0 = success
            if (success) {
              PostLog("NETWORK", "Printed to network printer successfully");
              if (debugEnabled_) {
                PostLog("NETWORK", "ESC/POS bytes (hex): " + HexPreview(bytesToSend, 128));
              }
            } else {
              PostLog("NETWORK", std::string("Failed to write to network printer, code: ") + std::to_string(writeResult));
              if (debugEnabled_) PostLog("NETWORK", "ESC/POS bytes (hex): " + HexPreview(bytesToSend, 128));
            }
            
            // Close connection
            CloseNetPor(&networkSocket_);
            networkSocket_ = INVALID_SOCKET;
            isNetworkPrinterConnected_ = false;
          }
        }
      }
    } else if (*printerType == "usb" || *printerType == "posmac") {
      // USB or POSMAC printer
      if (!isPrinterConnected_ || usbHandle_ == NULL) {
        result->Success(flutter::EncodableValue(false));
        return;
      }

      // Send data to USB printer; attempt structured ESC/POS bytes when available
      std::vector<uint8_t> bytesToSend;
      try {
        auto itemsIt = receipt_data_map->find(flutter::EncodableValue("items"));
        if (itemsIt != receipt_data_map->end()) {
          bytesToSend = BuildStructuredEscPosBytes(*receipt_data_map, charsPerLine);
          if (bytesToSend.empty()) {
            PostLog("USB", "Structured build returned empty; using content text");
            for (char c: *receipt_content) bytesToSend.push_back(static_cast<uint8_t>(c));
          } else {
            PostLog("USB", "Using structured receipt content for USB printing");
          }
        } else {
          for (char c: *receipt_content) bytesToSend.push_back(static_cast<uint8_t>(c));
        }
      } catch (const std::exception& e) {
        PostLog("USB", std::string("Structured build failed: ") + e.what() + ", falling back to content");
        for (char c: *receipt_content) bytesToSend.push_back(static_cast<uint8_t>(c));
      } catch (...) {
        PostLog("USB", "Structured build failed with unknown exception; falling back to content");
        for (char c: *receipt_content) bytesToSend.push_back(static_cast<uint8_t>(c));
      }
      // Send bytes
      DWORD bytesWritten = 0;
      BOOL usbSuccess = WriteUsb(usbHandle_, 
               reinterpret_cast<char*>(bytesToSend.data()), 
               static_cast<DWORD>(bytesToSend.size()), 
               &bytesWritten);
      success = (usbSuccess == TRUE);
      if (success) {
        PostLog("USB", std::string("Printed to USB device, bytes: ") + std::to_string(bytesWritten));
        if (debugEnabled_) PostLog("USB", std::string("ESC/POS bytes (hex): ") + HexPreview(bytesToSend, 128));
      } else {
        PostLog("USB", "USB write failed");
        if (debugEnabled_) PostLog("USB", std::string("ESC/POS bytes (hex): ") + HexPreview(bytesToSend, 128));
      }
    } else {
      // For other printer types (like local Windows printers), return false for now
      // TODO: Implement Windows API printing for local printers
      result->Success(flutter::EncodableValue(false));
      return;
    }

    result->Success(flutter::EncodableValue(success));
  } else if (method_call.method_name().compare("printOrder") == 0) {
    // Get the arguments
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Check printer type and connection details
    auto printerType_it = arguments->find(flutter::EncodableValue("printerType"));
    auto connectionDetails_it = arguments->find(flutter::EncodableValue("connectionDetails"));
    
    if (printerType_it == arguments->end() || connectionDetails_it == arguments->end()) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    const auto* printerType = std::get_if<std::string>(&printerType_it->second);
    const auto* connectionDetails = std::get_if<flutter::EncodableMap>(&connectionDetails_it->second);
    
    if (!printerType || !connectionDetails) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Get order data
    auto order_it = arguments->find(flutter::EncodableValue("orderData"));
    if (order_it == arguments->end()) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    const auto* order_data = std::get_if<std::string>(&order_it->second);
    if (!order_data) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    bool success = false;

    // Handle different printer types
    if (*printerType == "network") {
      // Network printer
      auto ip_it = connectionDetails->find(flutter::EncodableValue("ipAddress"));
      auto port_it = connectionDetails->find(flutter::EncodableValue("port"));
      
      if (ip_it != connectionDetails->end() && port_it != connectionDetails->end()) {
        const auto* ipAddress = std::get_if<std::string>(&ip_it->second);
        const auto* port = std::get_if<int32_t>(&port_it->second);
        
        if (ipAddress && port) {
          // Initialize network service if not already done
          if (!InitNetSev()) {
            result->Success(flutter::EncodableValue(false));
            return;
          }
          
          // Set up network address
          memset(&networkAddr_, 0, sizeof(networkAddr_));
          networkAddr_.sin_family = AF_INET;
          networkAddr_.sin_port = htons(static_cast<u_short>(*port));
          networkAddr_.sin_addr.s_addr = inet_addr(ipAddress->c_str());
          
          // Set timeout
          timeval timeout;
          timeout.tv_sec = 5;  // 5 second timeout
          timeout.tv_usec = 0;
          
          // Connect to network printer
          int connectResult = ConnectNetPort(&networkSocket_, &networkAddr_, &timeout);
          if (connectResult == 0) {  // Success
            isNetworkPrinterConnected_ = true;
            
            // Send order data
            int writeResult = WriteToNetPort(&networkSocket_, 
                                           const_cast<char*>(order_data->c_str()), 
                                           static_cast<DWORD>(order_data->length()));
            success = (writeResult == 0);  // 0 = success
            
            // Close connection
            CloseNetPor(&networkSocket_);
            networkSocket_ = INVALID_SOCKET;
            isNetworkPrinterConnected_ = false;
          }
        }
      }
    } else if (*printerType == "usb" || *printerType == "posmac") {
      // USB or POSMAC printer
      if (!isPrinterConnected_ || usbHandle_ == NULL) {
        result->Success(flutter::EncodableValue(false));
        return;
      }

      DWORD bytesWritten = 0;
      success = (WriteUsb(usbHandle_, 
                         const_cast<char*>(order_data->c_str()), 
                         static_cast<DWORD>(order_data->length()), 
                         &bytesWritten) == TRUE);
    } else {
      // For other printer types (like local Windows printers), return false for now
      // TODO: Implement Windows API printing for local printers
      result->Success(flutter::EncodableValue(false));
      return;
    }

    result->Success(flutter::EncodableValue(success));
  } else if (method_call.method_name().compare("testPrint") == 0) {
    // Get the arguments
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Check printer type and connection details
    auto printerType_it = arguments->find(flutter::EncodableValue("printerType"));
    auto connectionDetails_it = arguments->find(flutter::EncodableValue("connectionDetails"));
    
    if (printerType_it == arguments->end() || connectionDetails_it == arguments->end()) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    const auto* printerType = std::get_if<std::string>(&printerType_it->second);
    const auto* connectionDetails = std::get_if<flutter::EncodableMap>(&connectionDetails_it->second);
    
    if (!printerType || !connectionDetails) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    bool success = false;

    // Handle different printer types
    if (*printerType == "network") {
      // Network printer
      auto ip_it = connectionDetails->find(flutter::EncodableValue("ipAddress"));
      auto port_it = connectionDetails->find(flutter::EncodableValue("port"));
      
      if (ip_it != connectionDetails->end() && port_it != connectionDetails->end()) {
        const auto* ipAddress = std::get_if<std::string>(&ip_it->second);
        const auto* port = std::get_if<int32_t>(&port_it->second);
        
        if (ipAddress && port) {
          // Initialize network service if not already done
          if (!InitNetSev()) {
            result->Success(flutter::EncodableValue(false));
            return;
          }
          
          // Set up network address
          memset(&networkAddr_, 0, sizeof(networkAddr_));
          networkAddr_.sin_family = AF_INET;
          networkAddr_.sin_port = htons(static_cast<u_short>(*port));
          networkAddr_.sin_addr.s_addr = inet_addr(ipAddress->c_str());
          
          // Set timeout
          timeval timeout;
          timeout.tv_sec = 5;  // 5 second timeout
          timeout.tv_usec = 0;
          
          // Connect to network printer
          int connectResult = ConnectNetPort(&networkSocket_, &networkAddr_, &timeout);
          if (connectResult == 0) {  // Success
            isNetworkPrinterConnected_ = true;
            
            // Send test print data
            const char* testData = "\x1B\x40\x1B\x61\x01Hello POSMAC Printer\x0A\x0A\x1B\x64\x03"; // Initialize, center, print text, feed paper
            int writeResult = WriteToNetPort(&networkSocket_, 
                                           const_cast<char*>(testData), 
                                           static_cast<DWORD>(strlen(testData)));
            success = (writeResult == 0);  // 0 = success
            
            // Close connection
            CloseNetPor(&networkSocket_);
            networkSocket_ = INVALID_SOCKET;
            isNetworkPrinterConnected_ = false;
          }
        }
      }
    } else {
      // USB printer (existing logic)
      if (!isPrinterConnected_ || usbHandle_ == NULL) {
        result->Success(flutter::EncodableValue(false));
        return;
      }

      // Send a simple test print command (ESC/POS test print)
      const char* testData = "\x1B\x40\x1B\x61\x01Hello POSMAC Printer\x0A\x0A\x1B\x64\x03"; // Initialize, center, print text, feed paper
      DWORD bytesWritten = 0;
      DWORD dataLength = static_cast<DWORD>(strlen(testData));
      success = (WriteUsb(usbHandle_,
                         const_cast<char*>(testData),
                         dataLength,
                         &bytesWritten) == TRUE);
    }

    result->Success(flutter::EncodableValue(success));
  } else if (method_call.method_name().compare("checkPrinterStatus") == 0) {
    // Get the arguments
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Success(flutter::EncodableValue("unknown"));
      return;
    }

    // Check printer type and connection details
    auto printerType_it = arguments->find(flutter::EncodableValue("printerType"));
    auto connectionDetails_it = arguments->find(flutter::EncodableValue("connectionDetails"));
    
    if (printerType_it == arguments->end() || connectionDetails_it == arguments->end()) {
      result->Success(flutter::EncodableValue("unknown"));
      return;
    }

    const auto* printerType = std::get_if<std::string>(&printerType_it->second);
    const auto* connectionDetails = std::get_if<flutter::EncodableMap>(&connectionDetails_it->second);
    
    if (!printerType || !connectionDetails) {
      result->Success(flutter::EncodableValue("unknown"));
      return;
    }

    std::string status = "offline";

    // Handle different printer types
    if (*printerType == "network") {
      // Network printer - try a quick connection test
      auto ip_it = connectionDetails->find(flutter::EncodableValue("ipAddress"));
      auto port_it = connectionDetails->find(flutter::EncodableValue("port"));
      
      if (ip_it != connectionDetails->end() && port_it != connectionDetails->end()) {
        const auto* ipAddress = std::get_if<std::string>(&ip_it->second);
        const auto* port = std::get_if<int32_t>(&port_it->second);
        
        if (ipAddress && port) {
          // Initialize network service if not already done
          if (InitNetSev()) {
            // Set up network address
            memset(&networkAddr_, 0, sizeof(networkAddr_));
            networkAddr_.sin_family = AF_INET;
            networkAddr_.sin_port = htons(static_cast<u_short>(*port));
            networkAddr_.sin_addr.s_addr = inet_addr(ipAddress->c_str());
            
            // Set short timeout for status check
            timeval timeout;
            timeout.tv_sec = 2;  // 2 second timeout
            timeout.tv_usec = 0;
            
            // Try to connect
            int connectResult = ConnectNetPort(&networkSocket_, &networkAddr_, &timeout);
            if (connectResult == 0) {  // Success
              status = "online";
              // Close connection immediately
              CloseNetPor(&networkSocket_);
              networkSocket_ = INVALID_SOCKET;
            }
          }
        }
      }
    } else {
      // USB printer (existing logic)
      status = isPrinterConnected_ ? "online" : "offline";
    }

    result->Success(flutter::EncodableValue(status));
  } else if (method_call.method_name().compare("setDebugEnabled") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto enabled_it = arguments->find(flutter::EncodableValue("enabled"));
      if (enabled_it != arguments->end()) {
        const auto* enabled = std::get_if<bool>(&enabled_it->second);
        if (enabled) {
          debugEnabled_ = *enabled;
          PostLog("DEBUG", std::string("Set debugEnabled to ") + (*enabled ? "true" : "false"));
          result->Success(flutter::EncodableValue(true));
          return;
        }
      }
    }
    result->Success(flutter::EncodableValue(false));
  } else if (method_call.method_name().compare("isPrinterOnline") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Success(flutter::EncodableValue(false));
      return;
    }
    auto printerNameIt = arguments->find(flutter::EncodableValue("printerName"));
    if (printerNameIt == arguments->end()) {
      result->Success(flutter::EncodableValue(false));
      return;
    }
    const auto* printerName = std::get_if<std::string>(&printerNameIt->second);
    if (!printerName) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Very basic online check: for network printers, attempt a quick connect, for USB check cached state
    bool online = false;
    // Network printers: look for 'ipAddress' and 'port'
    // If any printer name includes ip:port we can attempt a quick check
    try {
      // If network socket is connected or we have isNetworkPrinterConnected_ true, return true
      if (isNetworkPrinterConnected_) {
        online = true;
      } else if (isPrinterConnected_) {
        online = true;
      }
    } catch (...) { online = false; }

    result->Success(flutter::EncodableValue(online));
  } else if (method_call.method_name().compare("discoverUsbPrinters") == 0) {
    // Discover USB printers specifically
    flutter::EncodableList printers;

    // Try to enumerate USB printers using Windows API
    // For now, return a basic USB printer if one is connected
    if (usbHandle_ != NULL || TryOpenUsbPrinter()) {
      flutter::EncodableMap printer;
      printer[flutter::EncodableValue("id")] = flutter::EncodableValue("usb_printer");
      printer[flutter::EncodableValue("name")] = flutter::EncodableValue("USB Thermal Printer");
      printer[flutter::EncodableValue("connectionType")] = flutter::EncodableValue("usb");
      printer[flutter::EncodableValue("usbDeviceId")] = flutter::EncodableValue("usb_printer");
      printer[flutter::EncodableValue("platformSpecificId")] = flutter::EncodableValue("usb_printer");
      printer[flutter::EncodableValue("printerType")] = flutter::EncodableValue("receipt");
      printer[flutter::EncodableValue("status")] = flutter::EncodableValue(isPrinterConnected_ ? "online" : "offline");
      printer[flutter::EncodableValue("modelName")] = flutter::EncodableValue("USB Thermal Printer");
      printers.push_back(flutter::EncodableValue(printer));
    }

    result->Success(flutter::EncodableValue(printers));
  } else if (method_call.method_name().compare("discoverNetworkPrinters") == 0) {
    // Discover network printers
    flutter::EncodableList printers;

    // For now, return empty list - network printer discovery
    // can be implemented later with proper network scanning

    result->Success(flutter::EncodableValue(printers));
  } else if (method_call.method_name().compare("discoverLocalPrinters") == 0) {
    // Discover local Windows printers
    flutter::EncodableList printers;

    // Enumerate local printers using Windows Print API
    DWORD needed = 0, returned = 0;
    PRINTER_INFO_2* printerInfo = NULL;

    // First call to get buffer size
    EnumPrinters(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, NULL, 2, NULL, 0, &needed, &returned);

    if (needed > 0) {
      printerInfo = (PRINTER_INFO_2*)malloc(needed);
      if (printerInfo) {
        if (EnumPrinters(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, NULL, 2,
                        (LPBYTE)printerInfo, needed, &needed, &returned)) {
          for (DWORD i = 0; i < returned; i++) {
            flutter::EncodableMap printer;
            std::string printerName = Utf8FromUtf16(printerInfo[i].pPrinterName);
            std::string portName = Utf8FromUtf16(printerInfo[i].pPortName);

            printer[flutter::EncodableValue("id")] = flutter::EncodableValue("local_" + std::to_string(i));
            printer[flutter::EncodableValue("name")] = flutter::EncodableValue(printerName);
            printer[flutter::EncodableValue("connectionType")] = flutter::EncodableValue("posmac"); // Windows local printers
            printer[flutter::EncodableValue("platformSpecificId")] = flutter::EncodableValue(printerName);
            printer[flutter::EncodableValue("printerType")] = flutter::EncodableValue("receipt");
            printer[flutter::EncodableValue("status")] = flutter::EncodableValue("offline");
            printer[flutter::EncodableValue("modelName")] = flutter::EncodableValue(printerName + " (" + portName + ")");

            printers.push_back(flutter::EncodableValue(printer));
          }
        }
        free(printerInfo);
      }
    }

    result->Success(flutter::EncodableValue(printers));
  } else {
    result->NotImplemented();
  }
}

void PrinterPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  PrinterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

// Helper to post logs to the Flutter side via the stored channel
void PrinterPlugin::PostLog(const std::string& level, const std::string& message) {
  try {
    flutter::EncodableMap m;
    m[flutter::EncodableValue("message")] = flutter::EncodableValue(level + ": " + message);
    if (channel_) {
      channel_->InvokeMethod("printerLog", std::make_unique<flutter::EncodableValue>(m));
    }
    if (net_channel_) {
      net_channel_->InvokeMethod("printerLog", std::make_unique<flutter::EncodableValue>(m));
    }
  } catch (...) {
    // suppress errors
  }
}

static double getDoubleFromEncodable(const flutter::EncodableValue& v) {
  if (const double* d = std::get_if<double>(&v)) return *d;
  if (const int64_t* i64 = std::get_if<int64_t>(&v)) return static_cast<double>(*i64);
  if (const int32_t* i32 = std::get_if<int32_t>(&v)) return static_cast<double>(*i32);
  return 0.0;
}

static std::string getStringFromEncodable(const flutter::EncodableValue& v) {
  if (const std::string* s = std::get_if<std::string>(&v)) return *s;
  return std::string();
}

// Convert byte vector to hex preview limited to n bytes
static std::string HexPreview(const std::vector<uint8_t>& bytes, size_t maxBytes=64) {
  std::ostringstream oss;
  size_t display = std::min(bytes.size(), maxBytes);
  oss << std::hex << std::setfill('0');
  for (size_t i = 0; i < display; ++i) {
    oss << std::setw(2) << static_cast<int>(bytes[i]);
    if (i < display - 1) oss << ' ';
  }
  if (bytes.size() > display) oss << " ...";
  return oss.str();
}

// Build a simple structured ESC/POS text for receipts. This will be a best-effort plain-text
// representation, and not raw ESC/POS binary. For Windows runner/raw socket printing, plain
// text is usually sufficient to print via network/USB if the printer accepts raw text.
std::string PrinterPlugin::BuildStructuredEscPosString(const flutter::EncodableMap& receipt_map, int charsPerLine) {
  try {
    // If the content is already present, we will convert it to ESC/POS formatted bytes
    auto content_it = receipt_map.find(flutter::EncodableValue("content"));
    // Note: convert content into ESC/POS bytes if provided
    if (content_it != receipt_map.end()) {
      const auto* content = std::get_if<std::string>(&content_it->second);
      if (content) {
        std::ostringstream csb;
        csb << "\x1B\x40";
        std::istringstream iss(*content);
        std::string line;
        while (std::getline(iss, line)) {
          if (line.find("RM") == std::string::npos && line.find("$") == std::string::npos) {
            csb << "\x1B\x61\x01"; // center
          } else {
            csb << "\x1B\x61\x00"; // left
          }
          csb << line << "\n";
        }
        csb << "\x0A\x1D\x56\x42\x00";
        return csb.str();
      }
    }

    std::ostringstream sb;
    // Begin ESC/POS initialize sequence
    sb << "\x1B\x40";
    std::string currency = "RM";
    auto currency_it = receipt_map.find(flutter::EncodableValue("currency"));
    if (currency_it != receipt_map.end()) {
      const auto* cs = std::get_if<std::string>(&currency_it->second);
      if (cs) currency = *cs;
    }

    // Header
    sb << "\x1B\x61\x01"; // center align
    sb << std::string(charsPerLine, '=') << "\n";
    auto title_it = receipt_map.find(flutter::EncodableValue("title"));
    if (title_it != receipt_map.end()) {
      const auto* title = std::get_if<std::string>(&title_it->second);
      if (title) {
        sb << *title << "\n";
      }
    }
    sb << std::string(charsPerLine, '-') << "\n";

    // Items
    auto items_it = receipt_map.find(flutter::EncodableValue("items"));
    if (items_it != receipt_map.end()) {
      const auto* items = std::get_if<flutter::EncodableList>(&items_it->second);
      if (items) {
        for (const auto& iv : *items) {
          const auto* itemMap = std::get_if<flutter::EncodableMap>(&iv);
          if (!itemMap) continue;
          std::string name;
          int qty = 1;
          double price = 0.0;
          auto nIt = itemMap->find(flutter::EncodableValue("name"));
          if (nIt != itemMap->end()) {
            name = getStringFromEncodable(nIt->second);
          }
          auto qIt = itemMap->find(flutter::EncodableValue("quantity"));
          if (qIt != itemMap->end()) {
            qty = static_cast<int>(getDoubleFromEncodable(qIt->second));
          }
          auto pIt = itemMap->find(flutter::EncodableValue("price"));
          if (pIt != itemMap->end()) {
            price = getDoubleFromEncodable(pIt->second);
          }
          std::ostringstream priceStr;
          priceStr << currency << " " << std::fixed << std::setprecision(2) << (price * qty);

          std::string leftPart = name;
          if (qty != 1) {
            leftPart += " x" + std::to_string(qty);
          }
          if (charsPerLine >= 48) {
            // Put name + qty left, price right
            if ((int)leftPart.length() + (int)priceStr.str().length() + 1 > charsPerLine) {
              sb << leftPart << "\n" << std::string(charsPerLine - (int)priceStr.str().length(), ' ') << priceStr.str() << "\n";
            } else {
              sb << "\x1B\x61\x00"; // left align for items
              sb << leftPart << std::string(charsPerLine - (int)leftPart.length() - (int)priceStr.str().length(), ' ') << priceStr.str() << "\n";
            }
          } else {
            sb << "\x1B\x61\x00";
            sb << leftPart << "\n" << std::string(charsPerLine - (int)priceStr.str().length(), ' ') << priceStr.str() << "\n";
          }
        }
      }
    }

    sb << std::string(charsPerLine, '-') << "\n";

    // Totals (subtotal, tax, serviceCharge, total) if available
    auto printTotal = [&](const std::string& label, const flutter::EncodableValue& v) {
      double val = getDoubleFromEncodable(v);
      std::ostringstream s;
      s << currency << " " << std::fixed << std::setprecision(2) << val;
      const std::string valStr = s.str();
      if ((int)label.length() + (int)valStr.length() + 1 > charsPerLine) {
        sb << label << "\n" << std::string(charsPerLine - (int)valStr.length(), ' ') << valStr << "\n";
      } else {
        sb << label << std::string(charsPerLine - (int)label.length() - (int)valStr.length(), ' ') << valStr << "\n";
      }
    };

    auto subtotal_it = receipt_map.find(flutter::EncodableValue("subtotal"));
    if (subtotal_it != receipt_map.end()) printTotal("Subtotal:", subtotal_it->second);
    auto tax_it = receipt_map.find(flutter::EncodableValue("tax"));
    if (tax_it != receipt_map.end()) printTotal("Tax:", tax_it->second);
    auto service_it = receipt_map.find(flutter::EncodableValue("serviceCharge"));
    if (service_it != receipt_map.end()) printTotal("Service:", service_it->second);
    auto total_it = receipt_map.find(flutter::EncodableValue("total"));
    if (total_it != receipt_map.end()) printTotal("TOTAL:", total_it->second);

    // Feed and cut paper
    sb << "\x0A\x1D\x56\x42\x00"; // line feed + full cut
    return sb.str();
  } catch (...) {
    return std::string();
  }
}

// New: Build structured ESC/POS as raw bytes vector
std::vector<uint8_t> PrinterPlugin::BuildStructuredEscPosBytes(const flutter::EncodableMap& receipt_map, int charsPerLine) {
  std::vector<uint8_t> out;
  try {
    auto items_it = receipt_map.find(flutter::EncodableValue("items"));
    bool hasItems = (items_it != receipt_map.end());
    auto content_it = receipt_map.find(flutter::EncodableValue("content"));
    if (!hasItems && content_it != receipt_map.end()) {
      const auto* content = std::get_if<std::string>(&content_it->second);
      if (content) {
        // Initialize
        out.push_back(0x1B); out.push_back(0x40);
        std::istringstream iss(*content);
        std::string line;
        while (std::getline(iss, line)) {
          if (line.find("RM") == std::string::npos && line.find("$") == std::string::npos) {
            out.push_back(0x1B); out.push_back(0x61); out.push_back(0x01); // center
          } else {
            out.push_back(0x1B); out.push_back(0x61); out.push_back(0x00); // left
          }
          for (char c: line) out.push_back(static_cast<uint8_t>(c));
          out.push_back('\n');
        }
        out.push_back(0x0A);
        out.push_back(0x1D); out.push_back(0x56); out.push_back(0x42); out.push_back(0x00);
        return out;
      }
    }

    auto pushBytes = [&](std::initializer_list<uint8_t> bytes) {
      out.insert(out.end(), bytes.begin(), bytes.end());
    };
    auto pushString = [&](const std::string& value) {
      for (char c: value) out.push_back(static_cast<uint8_t>(c));
    };
    // Initialize
    out.push_back(0x1B); out.push_back(0x40);
    std::string currency = "RM";
    auto currency_it = receipt_map.find(flutter::EncodableValue("currency"));
    if (currency_it != receipt_map.end()) {
      const auto* cs = std::get_if<std::string>(&currency_it->second);
      if (cs) currency = *cs;
    }
    // Header
    out.push_back(0x1B); out.push_back(0x61); out.push_back(0x01);
    for (int i = 0; i < charsPerLine; ++i) out.push_back('=');
    out.push_back('\n');
    auto title_it = receipt_map.find(flutter::EncodableValue("title"));
    if (title_it != receipt_map.end()) {
      const auto* title = std::get_if<std::string>(&title_it->second);
      if (title) for (char c: *title) out.push_back(static_cast<uint8_t>(c));
      out.push_back('\n');
    }
    for (int i = 0; i < charsPerLine; ++i) out.push_back('-');
    out.push_back('\n');
    // Items
    if (items_it != receipt_map.end()) {
      const auto* items = std::get_if<flutter::EncodableList>(&items_it->second);
      if (items) {
        for (const auto& iv : *items) {
          const auto* itemMap = std::get_if<flutter::EncodableMap>(&iv);
          if (!itemMap) continue;
          std::string name;
          int qty = 1;
          double price = 0.0;
          auto nIt = itemMap->find(flutter::EncodableValue("name"));
          if (nIt != itemMap->end()) name = getStringFromEncodable(nIt->second);
          auto qIt = itemMap->find(flutter::EncodableValue("quantity"));
          if (qIt != itemMap->end()) qty = static_cast<int>(getDoubleFromEncodable(qIt->second));
          auto pIt = itemMap->find(flutter::EncodableValue("price"));
          if (pIt != itemMap->end()) price = getDoubleFromEncodable(pIt->second);
          std::ostringstream priceStr;
          priceStr << currency << " " << std::fixed << std::setprecision(2) << (price * qty);
          std::string leftPart = name;
          if (qty != 1) leftPart += " x" + std::to_string(qty);
          if (charsPerLine >= 48) {
            if ((int)leftPart.length() + (int)priceStr.str().length() + 1 > charsPerLine) {
              for (char c: leftPart) out.push_back(static_cast<uint8_t>(c));
              out.push_back('\n');
              for (int k = 0; k < charsPerLine - (int)priceStr.str().length(); ++k) out.push_back(' ');
              for (char c: priceStr.str()) out.push_back(static_cast<uint8_t>(c));
              out.push_back('\n');
            } else {
              out.push_back(0x1B); out.push_back(0x61); out.push_back(0x00);
              for (char c: leftPart) out.push_back(static_cast<uint8_t>(c));
              for (int k = 0; k < charsPerLine - (int)leftPart.length() - (int)priceStr.str().length(); ++k) out.push_back(' ');
              for (char c: priceStr.str()) out.push_back(static_cast<uint8_t>(c));
              out.push_back('\n');
            }
          } else {
            out.push_back(0x1B); out.push_back(0x61); out.push_back(0x00);
            for (char c: leftPart) out.push_back(static_cast<uint8_t>(c));
            out.push_back('\n');
            for (int k = 0; k < charsPerLine - (int)priceStr.str().length(); ++k) out.push_back(' ');
            for (char c: priceStr.str()) out.push_back(static_cast<uint8_t>(c));
            out.push_back('\n');
          }
        }
      }
    }
    for (int i = 0; i < charsPerLine; ++i) out.push_back('-');
    out.push_back('\n');
    auto printTotal = [&](const std::string& label, const flutter::EncodableValue& v) {
      double val = getDoubleFromEncodable(v);
      std::ostringstream s;
      s << currency << " " << std::fixed << std::setprecision(2) << val;
      const std::string valStr = s.str();
      if ((int)label.length() + (int)valStr.length() + 1 > charsPerLine) {
        for (char c: label) out.push_back(static_cast<uint8_t>(c));
        out.push_back('\n');
        for (int k = 0; k < charsPerLine - (int)valStr.length(); ++k) out.push_back(' ');
        for (char c: valStr) out.push_back(static_cast<uint8_t>(c));
        out.push_back('\n');
      } else {
        for (char c: label) out.push_back(static_cast<uint8_t>(c));
        for (int k = 0; k < charsPerLine - (int)label.length() - (int)valStr.length(); ++k) out.push_back(' ');
        for (char c: valStr) out.push_back(static_cast<uint8_t>(c));
        out.push_back('\n');
      }
    };
    auto subtotal_it = receipt_map.find(flutter::EncodableValue("subtotal"));
    if (subtotal_it != receipt_map.end()) printTotal("Subtotal:", subtotal_it->second);
    auto tax_it = receipt_map.find(flutter::EncodableValue("tax"));
    if (tax_it != receipt_map.end()) printTotal("Tax:", tax_it->second);
    auto service_it = receipt_map.find(flutter::EncodableValue("serviceCharge"));
    if (service_it != receipt_map.end()) printTotal("Service:", service_it->second);
    auto total_it = receipt_map.find(flutter::EncodableValue("total"));
    if (total_it != receipt_map.end()) printTotal("TOTAL:", total_it->second);
    for (int i = 0; i < charsPerLine; ++i) out.push_back('=');
    out.push_back('\n');

    auto barcode_it = receipt_map.find(flutter::EncodableValue("barcode"));
    if (barcode_it != receipt_map.end()) {
      std::string barcode = getStringFromEncodable(barcode_it->second);
      if (!barcode.empty()) {
        if (barcode.size() > 255) barcode = barcode.substr(0, 255);
        pushBytes({0x1B, 0x61, 0x01}); // center
        pushBytes({0x1D, 0x48, 0x02}); // HRI below
        pushBytes({0x1D, 0x68, 0x50}); // Height
        pushBytes({0x1D, 0x77, 0x02}); // Module width
        pushBytes({0x1D, 0x6B, 0x49, static_cast<uint8_t>(barcode.size())}); // Code128
        pushString(barcode);
        out.push_back('\n');
      }
    }

    auto qr_it = receipt_map.find(flutter::EncodableValue("qr_data"));
    if (qr_it != receipt_map.end()) {
      std::string qrData = getStringFromEncodable(qr_it->second);
      if (!qrData.empty()) {
        pushBytes({0x1B, 0x61, 0x01}); // center
        pushBytes({0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00}); // Model 2
        pushBytes({0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x06}); // Size 6
        pushBytes({0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x30}); // Error correction L
        int len = static_cast<int>(qrData.size()) + 3;
        uint8_t pL = static_cast<uint8_t>(len & 0xFF);
        uint8_t pH = static_cast<uint8_t>((len >> 8) & 0xFF);
        pushBytes({0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30});
        pushString(qrData);
        pushBytes({0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30});
        out.push_back('\n');
      }
    }

    out.push_back(0x0A);
    out.push_back(0x1D); out.push_back(0x56); out.push_back(0x42); out.push_back(0x00);
    return out;
  } catch (...) {
    return std::vector<uint8_t>();
  }
}

void PrinterPlugin::SetDebugEnabled(bool enabled) {
  debugEnabled_ = enabled;
}