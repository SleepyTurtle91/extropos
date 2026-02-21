#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
// Include JsPrinterDll.h first (which includes winsock2.h and windows.h)
#include "JsPrinterDll.h"

// Windows API headers for printer enumeration
#include <winspool.h>
#include <stringapiset.h>

namespace {

class PrinterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  PrinterPlugin();

  virtual ~PrinterPlugin();

  // Channel for sending logs back to Dart
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
    // Additional channel to support the 'net.nfet.printing' API surface for parity with web plugin
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> net_channel_;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // POSMAC USB printer handle
  HANDLE usbHandle_;
  bool isPrinterConnected_;
  
  // Network printer socket
  SOCKET networkSocket_;
  bool isNetworkPrinterConnected_;
  SOCKADDR_IN networkAddr_;

    // Store the MethodChannel so we can post logs back to Dart
    // Post a log to the dart side using the stored channel
    void PostLog(const std::string& level, const std::string& message);
    // Build a structured ESC/POS bytes vector from the given receipt map
    std::vector<uint8_t> BuildStructuredEscPosBytes(const flutter::EncodableMap& receipt_map, int charsPerLine);
    // Debug toggle to enable hex previews in logs
    void SetDebugEnabled(bool enabled);
    bool debugEnabled_ = false;
};

}  // namespace