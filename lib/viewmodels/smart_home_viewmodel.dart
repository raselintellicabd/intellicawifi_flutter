import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/smart_home_repository.dart';
import '../utils/ui_state.dart';

class SmartHomeViewModel extends ChangeNotifier {
  final SmartHomeRepository _repository = SmartHomeRepository();

  UiState<List<SmartDevice>> _devices = UiState.loading();
  UiState<List<SmartDevice>> get devices => _devices;

  UiState<String>? _operationResult;
  UiState<String>? get operationResult => _operationResult;

  bool _isOperationLoading = false;
  bool get isOperationLoading => _isOperationLoading;

  String? _ssid;
  String? _password;
  String get ssid => _ssid ?? "";
  String get password => _password ?? "";
  bool get isWifiConfigured => _ssid != null && _ssid!.isNotEmpty;

  void loadDevices() async {
    _devices = UiState.loading();
    notifyListeners();
    try {
      final deviceList = await _repository.listDevices();
      _devices = UiState.success(deviceList);
    } catch (e) {
      _devices = UiState.error(e.toString());
    }
    notifyListeners();
  }

  Future<void> loadWifiConfig() async {
    try {
      final config = await _repository.getBartonWifiConfig();
      if (config.isNotEmpty) {
        _ssid = config[0];
        _password = config[1];
      } else {
        _ssid = null;
        _password = null;
      }
    } catch (e) {
      _ssid = null;
      _password = null;
    }
    notifyListeners();
  }

  Future<bool> saveWifiConfig(String ssid, String password) async {
    _isOperationLoading = true;
    notifyListeners();
    
    bool success = false;
    try {
      success = await _repository.setBartonWifiConfig(ssid, password);
      if (success) {
        _ssid = ssid;
        _password = password;
        _operationResult = UiState.success("WiFi configured successfully");
      } else {
        _operationResult = UiState.error("Failed to configure WiFi");
      }
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }
    
    _isOperationLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> toggleDevice(String nodeId, bool currentStatus) async {
    final setLight = currentStatus ? "OFF" : "ON";
    _isOperationLoading = true;
    notifyListeners();

    try {
      final success = await _repository.setDeviceStatus("$nodeId,$setLight");
      if (success) {
        // Optimistic update
        if (_devices.status == UiStatus.success) {
           final currentList = _devices.data!;
           final updatedList = currentList.map((d) {
             if (d.nodeId == nodeId) {
               return d.copyWith(isOn: !currentStatus);
             }
             return d;
           }).toList();
           _devices = UiState.success(updatedList);
        }
        _operationResult = UiState.success("Device ${!currentStatus ? "turned on" : "turned off"}");
      } else {
        _operationResult = UiState.error("Failed to toggle device");
      }
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }
    
    _isOperationLoading = false;
    notifyListeners();
  }

  Future<void> removeDevice(String nodeId) async {
    _isOperationLoading = true;
    notifyListeners();

    if (!isWifiConfigured) {
       _operationResult = UiState.error("WiFi not configured. Cannot remove device.");
       _isOperationLoading = false;
       notifyListeners();
       return;
    }

    try {
      final success = await _repository.removeDevice(nodeId);
      if (success) {
        _operationResult = UiState.success("Device removed successfully");
        // Future.delayed(const Duration(seconds: 2), () {
        //   loadDevices();
        // });
        loadDevices();
      } else {
         _operationResult = UiState.error("Failed to remove device");
      }
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }

    _isOperationLoading = false;
    notifyListeners();
  }

  Future<void> commissionDevice(String pairingCode) async {
    _isOperationLoading = true;
    notifyListeners();

    try {
      final success = await _repository.commissionDevice(pairingCode);
      if (success) {
        // Wait 23 seconds for the device to join
        await Future.delayed(const Duration(seconds: 23));
        
        // Trigger status check
        await _repository.setBartonTemp("commission");
        
        // Wait 1 second for status to update
        await Future.delayed(const Duration(seconds: 1));
        
        // Get commissioning status
        final status = await _repository.getBartonTemp();
        print(status);
        if (status == "CommissionedSuccessfully") {
           _operationResult = UiState.success("Device commissioned successfully");
        } else {
           _operationResult = UiState.error("Failed to commission device");
        }
      } else {
        _operationResult = UiState.error("Failed to initiate commissioning");
      }
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }
    
    // Always load devices at the end
    loadDevices();
    
    _isOperationLoading = false;
    notifyListeners();
  }

  Future<void> setDeviceColor(String nodeId, int hueValue) async {
    _isOperationLoading = true;
    notifyListeners();

    try {
      final value = "$nodeId,$hueValue";
      final success = await _repository.setDeviceColor(value);
      if (success) {
        _operationResult = UiState.success("Color updated successfully");
      } else {
        _operationResult = UiState.error("Failed to update color");
      }
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }

    _isOperationLoading = false;
    notifyListeners();
  }

  Future<void> setDeviceBrightness(String nodeId, int brightnessPercent) async {
    _isOperationLoading = true;
    notifyListeners();

    try {
      // Convert 0-100 to 0-254
      final brightnessApi = ((brightnessPercent / 100.0) * 254).toInt().toString();
      final value = "$nodeId,$brightnessApi";
      final success = await _repository.setDeviceBrightness(value);
      print("Viewmodel: $success");
      if (success) {
        _operationResult = UiState.success("Brightness updated successfully");
      } else {
        _operationResult = UiState.error("Failed to update brightness");
      }
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }

    _isOperationLoading = false;
    notifyListeners();
  }

  Future<void> setDeviceSaturation(String nodeId, int saturationPercent) async {
    _isOperationLoading = true;
    notifyListeners();

    try {
      // Convert 0-100 to 0-254
      final saturationApi = ((saturationPercent / 100.0) * 254).toInt().toString();
      final value = "$nodeId,$saturationApi";
      final success = await _repository.setDeviceSaturation(value);
      if (success) {
        _operationResult = UiState.success("Saturation updated successfully");
      } else {
        _operationResult = UiState.error("Failed to update saturation");
      }
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }

    _isOperationLoading = false;
    notifyListeners();
  }

  void clearOperationResult() {
    _operationResult = null;
    notifyListeners();
  }
}
