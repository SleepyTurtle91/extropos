#define FLUTTER_PLUGIN_IMPL
#include "windows_printer_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <windows.h>
#include <winspool.h>
#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
#include <cstdio>

namespace {

class WindowsPrinterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  WindowsPrinterPlugin();
  bool debugEnabled_ = false;

  virtual ~WindowsPrinterPlugin();

  // Helper functions for device enumeration/capabilities
  flutter::EncodableList DiscoverUsbPrinters();
  flutter::EncodableList DiscoverNetworkPrinters();
  flutter::EncodableList DiscoverLocalPrinters();
  flutter::EncodableMap GetPrinterCapabilities(const std::string& printer_name);
  bool IsPrinterOnline(const std::string& printer_name);
  bool IsThermalPrinter(const std::string& driver_name, const std::string& printer_name);
  bool PrintToWindowsPrinter(const std::string& printer_name, const std::string& content);
  std::string GetPrinterDriverName(const std::string& printer_name);
  std::string ConvertToEscPos(const std::string& receipt_text);
  std::string WideToUtf8(const wchar_t* wide_string);

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  // Channel used to send logs back to Dart
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> log_channel_;
  // Helper to send logs back to Dart as well as stdout
  void PostLog(const std::string& message) {
    try {
      OutputDebugStringA(message.c_str());
      std::cout << message << std::endl;
      if (log_channel_) {
        flutter::EncodableMap m;
        m[flutter::EncodableValue("message")] = flutter::EncodableValue(message);
        log_channel_->InvokeMethod("printerLog", std::make_unique<flutter::EncodableValue>(m));
      }
    } catch (...) {
      // ignore logging failures
    }
  }
};

// static
void WindowsPrinterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
    auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        registrar->messenger(), "net.nfet.printing",
        &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WindowsPrinterPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  // Save channel for log forwarding
  plugin->log_channel_ = std::move(channel);

  registrar->AddPlugin(std::move(plugin));
  // Log registration for debugging
  try { plugin->PostLog("WindowsPrinterPlugin: Registered with registrar"); } catch(...){}
}

WindowsPrinterPlugin::WindowsPrinterPlugin() {}

WindowsPrinterPlugin::~WindowsPrinterPlugin() {}

void WindowsPrinterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("initialize") == 0) {
    try { PostLog("WindowsPrinterPlugin: initialize called"); } catch(...){}
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("getPluginName") == 0) {
    result->Success(flutter::EncodableValue(std::string("WindowsPrinterPlugin")));
    return;
  } else if (method_call.method_name().compare("setDebugEnabled") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto enabled_it = arguments->find(flutter::EncodableValue("enabled"));
      if (enabled_it != arguments->end()) {
        const auto* enabled = std::get_if<bool>(&enabled_it->second);
        if (enabled) {
          debugEnabled_ = *enabled;
          PostLog(std::string("setDebugEnabled -> ") + (*enabled ? "true" : "false"));
          result->Success(flutter::EncodableValue(true));
          return;
        }
      }
    }
    result->Success(flutter::EncodableValue(false));
  } else if (method_call.method_name().compare("discoverUsbPrinters") == 0) {
    auto printers = DiscoverUsbPrinters();
    result->Success(flutter::EncodableValue(printers));
  } else if (method_call.method_name().compare("discoverNetworkPrinters") == 0) {
    auto printers = DiscoverNetworkPrinters();
    result->Success(flutter::EncodableValue(printers));
  } else if (method_call.method_name().compare("discoverLocalPrinters") == 0) {
    auto printers = DiscoverLocalPrinters();
    result->Success(flutter::EncodableValue(printers));
  } else if (method_call.method_name().compare("getPrinterCapabilities") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto printer_name_it = arguments->find(flutter::EncodableValue("printerName"));
      if (printer_name_it != arguments->end()) {
        auto printer_name = std::get<std::string>(printer_name_it->second);
        auto capabilities = GetPrinterCapabilities(printer_name);
        result->Success(flutter::EncodableValue(capabilities));
      } else {
        result->Error("INVALID_ARGUMENTS", "printerName is required");
      }
    } else {
      result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
    }
  } else if (method_call.method_name().compare("isPrinterOnline") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto printer_name_it = arguments->find(flutter::EncodableValue("printerName"));
      if (printer_name_it != arguments->end()) {
        auto printer_name = std::get<std::string>(printer_name_it->second);
        auto is_online = IsPrinterOnline(printer_name);
        result->Success(flutter::EncodableValue(is_online));
      } else {
        result->Error("INVALID_ARGUMENTS", "printerName is required");
      }
    } else {
      result->Error("INVALID_ARGUMENTS", "Arguments must be a map");
    }
  } else if (method_call.method_name().compare("printReceipt") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // Get printer ID and receipt data
    auto printer_id_it = arguments->find(flutter::EncodableValue("printerId"));
    auto receipt_data_it = arguments->find(flutter::EncodableValue("receiptData"));

    if (printer_id_it == arguments->end() || receipt_data_it == arguments->end()) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    const auto* printer_id = std::get_if<std::string>(&printer_id_it->second);
    const auto* receipt_data_map = std::get_if<flutter::EncodableMap>(&receipt_data_it->second);

    if (!printer_id || !receipt_data_map) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    auto content_it = receipt_data_map->find(flutter::EncodableValue("content"));
    if (content_it == receipt_data_map->end()) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    const auto* content = std::get_if<std::string>(&content_it->second);
    if (!content) {
      result->Success(flutter::EncodableValue(false));
      return;
    }

    // For local Windows printers, use Windows API printing
    if (printer_id->find("win_local_") == 0) {
      // Extract printer name from platformSpecificId if available
      auto connection_details_it = arguments->find(flutter::EncodableValue("connectionDetails"));
      std::string printer_name;
      
      if (connection_details_it != arguments->end()) {
        const auto* connection_details = std::get_if<flutter::EncodableMap>(&connection_details_it->second);
        if (connection_details) {
          auto platform_specific_it = connection_details->find(flutter::EncodableValue("platformSpecificId"));
          if (platform_specific_it != connection_details->end()) {
            const auto* platform_specific = std::get_if<std::string>(&platform_specific_it->second);
            if (platform_specific) {
              printer_name = *platform_specific;
            }
          }
        }
      }

      if (!printer_name.empty()) {
        bool success = PrintToWindowsPrinter(printer_name, *content);
        result->Success(flutter::EncodableValue(success));
      } else {
        result->Success(flutter::EncodableValue(false));
      }
    } else {
      // For other printer types, not supported in this plugin
      result->Success(flutter::EncodableValue(false));
    }
  } else {
    result->NotImplemented();
  }
}

flutter::EncodableList WindowsPrinterPlugin::DiscoverUsbPrinters() {
  flutter::EncodableList printers;

  // Enumerate all printers and filter for USB ones
  DWORD needed = 0;
  DWORD returned = 0;

  // First call to get buffer size
  EnumPrinters(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, NULL, 2, NULL, 0, &needed, &returned);

  if (needed == 0) {
    return printers;
  }

  std::vector<BYTE> buffer(needed);
  if (!EnumPrinters(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, NULL, 2,
                   buffer.data(), needed, &needed, &returned)) {
    return printers;
  }

  PRINTER_INFO_2* printer_info = reinterpret_cast<PRINTER_INFO_2*>(buffer.data());

  for (DWORD i = 0; i < returned; ++i) {
    std::string port_name = WideToUtf8(printer_info[i].pPortName);
    std::string printer_name = WideToUtf8(printer_info[i].pPrinterName);
    std::string driver_name = WideToUtf8(printer_info[i].pDriverName);

    // Check if it's a USB printer (port name contains USB)
    if (port_name.find("USB") != std::string::npos ||
        port_name.find("usb") != std::string::npos) {

      // Check if it's a thermal/receipt printer
      if (IsThermalPrinter(driver_name, printer_name)) {
        flutter::EncodableMap printer;
        printer[flutter::EncodableValue("id")] = flutter::EncodableValue("win_usb_" + std::to_string(i));
        printer[flutter::EncodableValue("name")] = flutter::EncodableValue(printer_name);
        printer[flutter::EncodableValue("type")] = flutter::EncodableValue("receipt");
        printer[flutter::EncodableValue("connectionType")] = flutter::EncodableValue("posmac");
        printer[flutter::EncodableValue("platformSpecificId")] = flutter::EncodableValue(printer_name);
        printer[flutter::EncodableValue("modelName")] = flutter::EncodableValue(driver_name);
        printer[flutter::EncodableValue("portName")] = flutter::EncodableValue(port_name);
        printer[flutter::EncodableValue("paperSize")] = flutter::EncodableValue("mm80");

        printers.push_back(flutter::EncodableValue(printer));
      }
    }
  }

  return printers;
}

flutter::EncodableList WindowsPrinterPlugin::DiscoverNetworkPrinters() {
  flutter::EncodableList printers;

  // Enumerate network printers
  DWORD needed = 0;
  DWORD returned = 0;

  EnumPrinters(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS | PRINTER_ENUM_NETWORK, NULL, 2, NULL, 0, &needed, &returned);

  if (needed == 0) {
    return printers;
  }

  std::vector<BYTE> buffer(needed);
  if (!EnumPrinters(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS | PRINTER_ENUM_NETWORK, NULL, 2,
                   buffer.data(), needed, &needed, &returned)) {
    return printers;
  }

  PRINTER_INFO_2* printer_info = reinterpret_cast<PRINTER_INFO_2*>(buffer.data());

  for (DWORD i = 0; i < returned; ++i) {
    std::string port_name = WideToUtf8(printer_info[i].pPortName);
    std::string printer_name = WideToUtf8(printer_info[i].pPrinterName);
    std::string driver_name = WideToUtf8(printer_info[i].pDriverName);

    // Check if it's a network printer
    if (port_name.find("IP_") != std::string::npos ||
        port_name.find("TCP") != std::string::npos ||
        port_name.find("LPT") == std::string::npos) {  // Exclude local ports

      if (IsThermalPrinter(driver_name, printer_name)) {
        flutter::EncodableMap printer;
        printer[flutter::EncodableValue("id")] = flutter::EncodableValue("win_net_" + std::to_string(i));
        printer[flutter::EncodableValue("name")] = flutter::EncodableValue(printer_name);
        printer[flutter::EncodableValue("type")] = flutter::EncodableValue("receipt");
        printer[flutter::EncodableValue("connectionType")] = flutter::EncodableValue("posmac");
        printer[flutter::EncodableValue("platformSpecificId")] = flutter::EncodableValue(printer_name);
        printer[flutter::EncodableValue("modelName")] = flutter::EncodableValue(driver_name);
        printer[flutter::EncodableValue("portName")] = flutter::EncodableValue(port_name);
        printer[flutter::EncodableValue("paperSize")] = flutter::EncodableValue("mm80");

        printers.push_back(flutter::EncodableValue(printer));
      }
    }
  }

  return printers;
}

flutter::EncodableList WindowsPrinterPlugin::DiscoverLocalPrinters() {
  flutter::EncodableList printers;

  // Enumerate all local printers
  DWORD needed = 0;
  DWORD returned = 0;

  EnumPrinters(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, NULL, 2, NULL, 0, &needed, &returned);

  if (needed == 0) {
    return printers;
  }

  std::vector<BYTE> buffer(needed);
  if (!EnumPrinters(PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS, NULL, 2,
                   buffer.data(), needed, &needed, &returned)) {
    return printers;
  }

  PRINTER_INFO_2* printer_info = reinterpret_cast<PRINTER_INFO_2*>(buffer.data());

  for (DWORD i = 0; i < returned; ++i) {
    std::string printer_name = WideToUtf8(printer_info[i].pPrinterName);
    std::string driver_name = WideToUtf8(printer_info[i].pDriverName);
    std::string port_name = WideToUtf8(printer_info[i].pPortName);

    if (IsThermalPrinter(driver_name, printer_name)) {
      flutter::EncodableMap printer;
      printer[flutter::EncodableValue("id")] = flutter::EncodableValue("win_local_" + std::to_string(i));
      printer[flutter::EncodableValue("name")] = flutter::EncodableValue(printer_name);
      printer[flutter::EncodableValue("type")] = flutter::EncodableValue("receipt");
      printer[flutter::EncodableValue("connectionType")] = flutter::EncodableValue("posmac");
      printer[flutter::EncodableValue("platformSpecificId")] = flutter::EncodableValue(printer_name);
      printer[flutter::EncodableValue("modelName")] = flutter::EncodableValue(driver_name);
      printer[flutter::EncodableValue("portName")] = flutter::EncodableValue(port_name);
      printer[flutter::EncodableValue("paperSize")] = flutter::EncodableValue("mm80");

      printers.push_back(flutter::EncodableValue(printer));
    }
  }

  return printers;
}

flutter::EncodableMap WindowsPrinterPlugin::GetPrinterCapabilities(const std::string& printer_name) {
  flutter::EncodableMap capabilities;

  HANDLE hPrinter = NULL;
  if (!OpenPrinterA(const_cast<char*>(printer_name.c_str()), &hPrinter, NULL)) {
    return capabilities;
  }

  DWORD needed = 0;
  GetPrinterA(hPrinter, 2, NULL, 0, &needed);

  if (needed > 0) {
    std::vector<BYTE> buffer(needed);
    if (GetPrinterA(hPrinter, 2, buffer.data(), needed, &needed)) {
      PRINTER_INFO_2* printer_info = reinterpret_cast<PRINTER_INFO_2*>(buffer.data());

      capabilities[flutter::EncodableValue("status")] = flutter::EncodableValue(static_cast<int>(printer_info->Status));
      capabilities[flutter::EncodableValue("isOnline")] = flutter::EncodableValue((printer_info->Status & PRINTER_STATUS_OFFLINE) == 0);
      capabilities[flutter::EncodableValue("isBusy")] = flutter::EncodableValue((printer_info->Status & PRINTER_STATUS_BUSY) != 0);
      capabilities[flutter::EncodableValue("hasPaper")] = flutter::EncodableValue((printer_info->Status & PRINTER_STATUS_PAPER_OUT) == 0);
      capabilities[flutter::EncodableValue("hasError")] = flutter::EncodableValue((printer_info->Status & PRINTER_STATUS_ERROR) != 0);
    }
  }

  ClosePrinter(hPrinter);
  return capabilities;
}

bool WindowsPrinterPlugin::IsPrinterOnline(const std::string& printer_name) {
  auto capabilities = GetPrinterCapabilities(printer_name);
  auto is_online_it = capabilities.find(flutter::EncodableValue("isOnline"));
  if (is_online_it != capabilities.end()) {
    return std::get<bool>(is_online_it->second);
  }
  return false;
}

bool WindowsPrinterPlugin::IsThermalPrinter(const std::string& driver_name, const std::string& printer_name) {
  std::string lower_driver = driver_name;
  std::string lower_printer = printer_name;
  std::transform(lower_driver.begin(), lower_driver.end(), lower_driver.begin(), ::tolower);
  std::transform(lower_printer.begin(), lower_printer.end(), lower_printer.begin(), ::tolower);

  // Check for thermal printer keywords
  std::vector<std::string> thermal_keywords = {
    "thermal", "receipt", "pos", "epson", "tm-", "t88", "t20", "imin", "star", "citizen"
  };

  for (const auto& keyword : thermal_keywords) {
    if (lower_driver.find(keyword) != std::string::npos ||
        lower_printer.find(keyword) != std::string::npos) {
      return true;
    }
  }

  return false;
}

std::string WindowsPrinterPlugin::GetPrinterDriverName(const std::string& printer_name) {
  HANDLE hPrinter = NULL;
  if (!OpenPrinterA(const_cast<char*>(printer_name.c_str()), &hPrinter, NULL)) {
    return "";
  }

  DWORD needed = 0;
  GetPrinterA(hPrinter, 2, NULL, 0, &needed);

  if (needed > 0) {
    std::vector<BYTE> buffer(needed);
    if (GetPrinterA(hPrinter, 2, buffer.data(), needed, &needed)) {
      PRINTER_INFO_2* printer_info = reinterpret_cast<PRINTER_INFO_2*>(buffer.data());
      std::string driver_name = WideToUtf8(printer_info->pDriverName);
      ClosePrinter(hPrinter);
      return driver_name;
    }
  }

  ClosePrinter(hPrinter);
  return "";
}

std::string WindowsPrinterPlugin::ConvertToEscPos(const std::string& receipt_text) {
  std::string esc_pos;
  
  // Initialize printer
  esc_pos += "\x1B\x40";  // ESC @ - Initialize printer
  
  // Split text into lines and process each line
  std::istringstream iss(receipt_text);
  std::string line;
  while (std::getline(iss, line)) {
    if (line.empty()) {
      esc_pos += "\x0A";  // Line feed
      continue;
    }
    
    // Center align lines that look like headers (no price info)
    if (line.find('$') == std::string::npos && line.find("RM") == std::string::npos) {
      esc_pos += "\x1B\x61\x01";  // ESC a 1 - Center alignment
    } else {
      esc_pos += "\x1B\x61\x00";  // ESC a 0 - Left alignment
    }
    
    esc_pos += line;
    esc_pos += "\x0A";  // Line feed
  }
  
  // Cut paper
  esc_pos += "\x1D\x56\x42\x00";  // GS V B 0 - Full cut
  
  return esc_pos;
}

bool WindowsPrinterPlugin::PrintToWindowsPrinter(const std::string& printer_name, const std::string& content) {
  // Check if this is a thermal printer
  std::string driver_name = GetPrinterDriverName(printer_name);
  bool isThermal = IsThermalPrinter(driver_name, printer_name);
  
  std::string printData;
  if (isThermal) {
    // Convert receipt text to ESC/POS commands for thermal printers
    printData = ConvertToEscPos(content);
  } else {
    // Use plain text for regular printers
    printData = content;
  }

  HANDLE hPrinter = NULL;
  DOC_INFO_1 docInfo;
  DWORD bytesWritten;

  // Open the printer
  if (!OpenPrinterA(const_cast<char*>(printer_name.c_str()), &hPrinter, NULL)) {
    return false;
  }

  // Set up document info
  docInfo.pDocName = "Receipt";
  docInfo.pOutputFile = NULL;
  docInfo.pDatatype = "RAW";

  // Start the document
  if (StartDocPrinter(hPrinter, 1, (LPBYTE)&docInfo) == 0) {
    ClosePrinter(hPrinter);
    return false;
  }

  // Start a page
  if (!StartPagePrinter(hPrinter)) {
    EndDocPrinter(hPrinter);
    ClosePrinter(hPrinter);
    return false;
  }

  // Write the content
  if (!WritePrinter(hPrinter, const_cast<char*>(printData.c_str()), static_cast<DWORD>(printData.length()), &bytesWritten)) {
    EndPagePrinter(hPrinter);
    EndDocPrinter(hPrinter);
    ClosePrinter(hPrinter);
    try { PostLog("Windows: WritePrinter failed while printing to " + printer_name); } catch(...) {}
    return false;
  }

  // End the page and document
  EndPagePrinter(hPrinter);
  EndDocPrinter(hPrinter);
  ClosePrinter(hPrinter);
  try {
    PostLog(std::string("Windows: Printed to ") + printer_name + " (" + std::to_string(bytesWritten) + " bytes)");
  } catch(...) {}

  return true;
}

std::string WindowsPrinterPlugin::WideToUtf8(const wchar_t* wide_string) {
  if (!wide_string) return "";

  int size_needed = WideCharToMultiByte(CP_UTF8, 0, wide_string, -1, NULL, 0, NULL, NULL);
  std::string utf8_string(size_needed - 1, 0);
  WideCharToMultiByte(CP_UTF8, 0, wide_string, -1, &utf8_string[0], size_needed, NULL, NULL);
  return utf8_string;
}

}  // namespace

void WindowsPrinterPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  WindowsPrinterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

// C++ wrapper which accepts flutter::PluginRegistrar* and forwards to the
// plugin's RegisterWithRegistrar method. This is used by generated_plugin_registrant.cc
void WindowsPrinterPluginRegisterWithRegistrar(flutter::PluginRegistrar* registrar) {
  WindowsPrinterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarManager::GetInstance()
      ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}