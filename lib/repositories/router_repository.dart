import '../api/api_service.dart';
import '../models/models.dart';
import '../utils/router_mac_manager.dart';

class RouterRepository {
  final ApiService _api = ApiService();

  Future<String> getCurrentMacAddress() async {
    return RouterMacManager.getMac();
  }

  Future<RouterInfo> getRouterInfo() async {
    final deviceMac = await RouterMacManager.getMac();
    
    final results = await Future.wait([
      _api.getDeviceParameter(deviceMac, "Device.DeviceInfo.SoftwareVersion"),
      _api.getDeviceParameter(deviceMac, "Device.DeviceInfo.UpTime"),
      _api.getDeviceParameter(deviceMac, "Device.DeviceInfo.SerialNumber"),
      _api.getDeviceParameter(deviceMac, "Device.DeviceInfo.ModelName"),
      _api.getDeviceParameter(deviceMac, "Device.IP.Interface.1.IPv4Address.1.IPAddress"),
    ]);

    return RouterInfo(
      softwareVersion: results[0].parameters?.firstOrNull?.getStringValue() ?? "N/A",
      uptime: _formatUptime(results[1].parameters?.firstOrNull?.getStringValue() ?? "0"),
      serialNumber: results[2].parameters?.firstOrNull?.getStringValue() ?? "N/A",
      modelName: results[3].parameters?.firstOrNull?.getStringValue() ?? "N/A",
      wanIpAddress: results[4].parameters?.firstOrNull?.getStringValue() ?? "N/A",
      deviceMac: deviceMac,
    );
  }

  Future<List<ConnectedDevice>> getConnectedDevices() async {
    final deviceMac = await RouterMacManager.getMac();
    final response = await _api.getDeviceParameter(
        deviceMac, "Device.WiFi.AccessPoint.10001.AssociatedDevice.");

    final topParams = response.parameters ?? [];
    final parameters = topParams.expand((p) => p.asParameterList()).toList();

    // Group by index
    final deviceMap = <String, List<Parameter>>{};
    final regex = RegExp(r"AssociatedDevice\.(\d+)\.");

    for (var param in parameters) {
      final match = regex.firstMatch(param.name);
      if (match != null) {
        final index = match.group(1)!;
        deviceMap.putIfAbsent(index, () => []).add(param);
      }
    }

    return deviceMap.entries.map((entry) {
      final index = entry.key;
      final params = entry.value;
      
      final macAddress = params
          .firstWhere((p) => p.name.contains("MACAddress"), orElse: () => Parameter(name: "", dataType: 0, value: null))
          .getStringValue();

      if (macAddress == "N/A") return null;

      return ConnectedDevice(
        id: index,
        macAddress: macAddress,
        signalStrength: params.firstWhere((p) => p.name.contains("SignalStrength"), orElse: () => Parameter(name: "", dataType: 0, value: null)).getStringValue(),
        downloadRate: params.firstWhere((p) => p.name.contains("LastDataDownlinkRate"), orElse: () => Parameter(name: "", dataType: 0, value: null)).getStringValue(),
        hostname: "Device-$index",
        connectionType: "WiFi 2.4GHz",
      );
    }).whereType<ConnectedDevice>().toList();
  }

  Future<ConnectedDevice> getDeviceDetails(String deviceIndex) async {
    final deviceMac = await RouterMacManager.getMac();
    
    final results = await Future.wait([
      _api.getDeviceParameter(deviceMac, "Device.WiFi.AccessPoint.10001.AssociatedDevice.$deviceIndex.MACAddress"),
      _api.getDeviceParameter(deviceMac, "Device.WiFi.AccessPoint.10001.AssociatedDevice.$deviceIndex.SignalStrength"),
      _api.getDeviceParameter(deviceMac, "Device.WiFi.AccessPoint.10001.AssociatedDevice.$deviceIndex.LastDataDownlinkRate"),
      _api.getDeviceParameter(deviceMac, "Device.WiFi.AccessPoint.10001.AssociatedDevice.$deviceIndex.LastDataUplinkRate"),
      _api.getDeviceParameter(deviceMac, "Device.WiFi.AccessPoint.10001.AssociatedDevice.$deviceIndex.IPAddress"),
      _api.getDeviceParameter(deviceMac, "Device.Hosts.Host.$deviceIndex.HostName"),
    ]);

    return ConnectedDevice(
      id: deviceIndex,
      macAddress: results[0].parameters?.firstOrNull?.getStringValue() ?? "N/A",
      signalStrength: results[1].parameters?.firstOrNull?.getStringValue() ?? "N/A",
      downloadRate: results[2].parameters?.firstOrNull?.getStringValue() ?? "N/A",
      uploadRate: results[3].parameters?.firstOrNull?.getStringValue() ?? "N/A",
      ipAddress: results[4].parameters?.firstOrNull?.getStringValue() ?? "N/A",
      hostname: results[5].parameters?.firstOrNull?.getStringValue() ?? "N/A",
    );
  }

  Future<String> getSsidName(int ssidIndex) async {
    final deviceMac = await RouterMacManager.getMac();
    final response = await _api.getDeviceParameter(deviceMac, "Device.WiFi.SSID.$ssidIndex.SSID");
    return response.parameters?.firstOrNull?.getStringValue() ?? "N/A";
  }

  Future<bool> setSsidName(int ssidIndex, String newSsid) async {
    final deviceMac = await RouterMacManager.getMac();
    final req = SetParameterRequest(
      parameters: [
        SetParameter(name: "Device.WiFi.SSID.$ssidIndex.SSID", value: newSsid, dataType: 0)
      ],
    );
    await _api.setDeviceParameter(deviceMac, req);
    return true; // If no error thrown
  }

  Future<bool> setSsidPassword(int apIndex, String newPassword) async {
    final deviceMac = await RouterMacManager.getMac();
    final req = SetParameterRequest(
      parameters: [
        SetParameter(name: "Device.WiFi.AccessPoint.$apIndex.Security.KeyPassphrase", value: newPassword, dataType: 0)
      ],
    );
    await _api.setDeviceParameter(deviceMac, req);
    return true;
  }

  Future<void> rebootRouter() async {
    final deviceMac = await RouterMacManager.getMac();
    // In Kotlin: value = JsonPrimitive("Device"). In Dart Models, we pass "Device" as string?
    // Wait, Kotlin used: value = JsonPrimitive("Device"). The model expected JsonElement?.
    // My ApiService should handle this. SetParameterRequest uses SetParameter which takes String?
    // In rebootRouter Kotlin: dataType = 0.
    // I will pass "Device" string.
    
    final req = WebPaRequest(
      parameters: [
        Parameter(name: "Device.X_CISCO_COM_DeviceControl.RebootDevice", value: "Device", dataType: 0)
      ],
    );
    
    // The Kotlin implementation used WebPaRequest for reboot but SetParameterRequest for others?
    // Ah, `rebootRouter` in Kotlin used `WebPaRequest` body. `setSsidName` used `SetParameterRequest`.
    // My `ApiService` has `rebootDevice` which takes `WebPaRequest`.
    
    await _api.rebootDevice(deviceMac, req);
  }

  String _formatUptime(String seconds) {
    final sec = int.tryParse(seconds) ?? 0;
    final days = sec ~/ 86400;
    final hours = (sec % 86400) ~/ 3600;
    final minutes = (sec % 3600) ~/ 60;
    return "${days}d ${hours}h ${minutes}m";
  }
}

extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
