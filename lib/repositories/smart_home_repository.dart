import '../api/api_service.dart';
import '../models/models.dart';
import '../utils/router_mac_manager.dart';

class SmartHomeRepository {
  final ApiService _api = ApiService();

  Future<List<String>> listDevices() async {
    final deviceMac = await RouterMacManager.getMac();
    try {
      final response = await _api.getDeviceParameter(deviceMac, "Device.Light.ListDevice");
      final value = response.parameters?.firstOrNull?.getStringValue();
      
      if (value == null || value.isEmpty || value == "N/A") {
        return [];
      }
      return _parseIds(value);
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
       if (response.statusCode == 520) return true;
       
       final respValue = response.parameters?.firstOrNull?.getStringValue();
       return respValue == "Success";
    } catch (e) {
      throw Exception("Failed to set parameter: $e");
    }
  }

  List<String> _parseIds(String raw) {
    return raw
        .split(RegExp(r'[, \n\t]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
