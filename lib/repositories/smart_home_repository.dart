import '../api/api_service.dart';
import '../models/models.dart';
import '../utils/router_mac_manager.dart';

class SmartHomeRepository {
  final ApiService _api = ApiService();

  Future<List<SmartDevice>> listDevices() async {
    final deviceMac = await RouterMacManager.getMac();
    try {
      final response = await _api.getDeviceParameter(deviceMac, "Device.Light.ListDevice");
      final value = response.parameters?.firstOrNull?.getStringValue();
      
      if (value == null || value.isEmpty || value == "N/A") {
        return [];
      }
      return _parseDeviceList(value);
    } catch (e) {
      // Logic from Kotlin: if empty list executed (not sure if error or empty string)
      return [];
    }
  }
  
  // Reuse getDeviceParameter but looking for specific status
  Future<bool> getDeviceStatus(String nodeId) async {
    final deviceMac = await RouterMacManager.getMac();
    try {
      final response = await _api.getDeviceParameter(deviceMac, "Device.Light.Status");
      final status = response.parameters?.firstOrNull?.getStringValue() ?? "OFF";
      return status == "ON";
    } catch (e) {
      return false;
    }
  }

  Future<bool> setDeviceStatus(String value) async {
    return _sendSetRequest("Device.Light.Status", value);
  }

  Future<bool> commissionDevice(String value) async {
    return _sendSetRequest("Device.Light.Commission", value);
  }

  Future<bool> removeDevice(String value) async {
    return _sendSetRequest("Device.Light.Remove", value);
  }

  Future<bool> setDeviceColor(String hueValue) async {
    return _sendSetRequest("Device.Light.Color", hueValue);
  }

  Future<bool> setDeviceBrightness(String value) async {
    return _sendSetRequest("Device.Light.Level", value);
  }

  Future<bool> setDeviceSaturation(String saturation) async {
    return _sendSetRequest("Device.Light.Saturation", saturation);
  }

  Future<List<String>> getBartonWifiConfig() async {
    final deviceMac = await RouterMacManager.getMac();
    try {
      final response = await _api.getDeviceParameter(deviceMac, "Device.Barton.SSID");
      final value = response.parameters?.firstOrNull?.getStringValue();

      if (value == null || value.isEmpty || value == "N/A") {
        return [];
      }
      
      // Split by comma. Assuming format "ssid,password"
      final parts = value.split(',');
      if (parts.length >= 2) {
        // changing join logic in case password has commas, though prompt implies simple split
        final ssid = parts[0];
        final password = parts.sublist(1).join(','); 
        return [ssid, password];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> setBartonWifiConfig(String ssid, String password) async {
    return _sendSetRequest("Device.Barton.SSID", "$ssid,$password");
  }

  Future<bool> _sendSetRequest(String name, String value) async {
    final deviceMac = await RouterMacManager.getMac();
    final req = SetParameterRequest(
      parameters: [
        SetParameter(name: name, value: value, dataType: 0)
      ],
    );

    try {
      final response = await _api.setDeviceParameter(deviceMac, req);
       // Check for "Success" or 520
       if (response.statusCode == 200) {
         return true;
       } else {
         return false;
       }
       // final respValue = response.parameters?.firstOrNull?.getStringValue();
       // return respValue == "Success";
    } catch (e) {
      throw Exception("Failed to set parameter: $e");
    }
  }

  List<SmartDevice> _parseDeviceList(String raw) {
    if (raw.contains("No devices") || raw.trim() == "barton-core>") {
        return [];
    }

    // Check if it's the new verbose format
    if (raw.contains("Class:")) {
      final lines = raw.split('\n');
      final devices = <SmartDevice>[];
      String? currentId;

      final idRegex = RegExp(r'^([0-9a-fA-F]+): Class:');
      final labelRegex = RegExp(r'Label: (.*)');

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;
        if (line.startsWith("barton-core>")) continue;

        final idMatch = idRegex.firstMatch(line);
        if (idMatch != null) {
          currentId = idMatch.group(1);
          if (currentId != null) {
             devices.add(SmartDevice(nodeId: currentId, label: "Unknown Device"));
          }
        } else if (currentId != null && line.contains("Label:")) {
             final labelMatch = labelRegex.firstMatch(line);
             if (labelMatch != null) {
                 var label = labelMatch.group(1)?.trim() ?? "Unknown Device";
                 if (label.endsWith(',')) {
                     label = label.substring(0, label.length - 1);
                 }
                 if (devices.isNotEmpty && devices.last.nodeId == currentId) {
                    devices[devices.length - 1] = devices.last.copyWith(label: label);
                 }
             }
        }
      }
      return devices;
    } else {
      // Legacy format (comma/space separated IDs)
      return raw
          .split(RegExp(r'[, \n\t]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s != "barton-core>")
          .map((id) => SmartDevice(nodeId: id))
          .toList();
    }
  }
}

extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
