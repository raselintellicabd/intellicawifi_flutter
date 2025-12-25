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

  void loadDevices() async {
    _devices = UiState.loading();
    notifyListeners();
    try {
      final nodeIds = await _repository.listDevices();
      final deviceList = nodeIds.map((id) => SmartDevice(nodeId: id, isOn: true)).toList();
      _devices = UiState.success(deviceList);
    } catch (e) {
      _devices = UiState.error(e.toString());
    }
    notifyListeners();
  }

  Future<void> toggleDevice(String nodeId, bool currentStatus, String ssid, String password) async {
    final setLight = currentStatus ? "OFF" : "ON";
    _isOperationLoading = true;
    notifyListeners();

    try {
      final success = await _repository.setDeviceStatus("$setLight,$nodeId,$ssid,$password");
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

  Future<void> removeDevice(String nodeId, String wifiSsid, String wifiPassword) async {
    _isOperationLoading = true;
    notifyListeners();

    try {
      final success = await _repository.removeDevice("$nodeId,$wifiSsid,$wifiPassword");
      if (success) {
        _operationResult = UiState.success("Device removed successfully");
        Future.delayed(const Duration(seconds: 7), () {
          loadDevices();
        });
      } else {
         _operationResult = UiState.error("Failed to remove device");
      }
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }

    _isOperationLoading = false;
    notifyListeners();
  }

  Future<void> commissionDevice(String pairingCode, String wifiSsid, String wifiPassword) async {
    _isOperationLoading = true;
    notifyListeners();

    try {
      final success = await _repository.commissionDevice("$pairingCode,$wifiSsid,$wifiPassword");
      if (success) {
        _operationResult = UiState.success("Device commissioned successfully");
        Future.delayed(const Duration(seconds: 10), () {
          loadDevices();
        });
      } else {
        _operationResult = UiState.error("Failed to commission device");
      }
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }
    
    _isOperationLoading = false;
    notifyListeners();
  }

  Future<void> setDeviceColor(String nodeId, int hueValue, String ssid, String password) async {
    _isOperationLoading = true;
    notifyListeners();

    try {
      final value = "$hueValue,$nodeId,$ssid,$password";
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

  Future<void> setDeviceBrightness(String nodeId, int brightnessPercent, String ssid, String password) async {
    _isOperationLoading = true;
    notifyListeners();

    try {
      // Convert 0-100 to 0-254
      final brightnessApi = ((brightnessPercent / 100.0) * 254).toInt().toString();
      final value = "$brightnessApi,$nodeId,$ssid,$password";
      final success = await _repository.setDeviceBrightness(value);
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

  Future<void> setDeviceSaturation(String nodeId, int saturationPercent, String ssid, String password) async {
    _isOperationLoading = true;
    notifyListeners();

    try {
      // Convert 0-100 to 0-254
      final saturationApi = ((saturationPercent / 100.0) * 254).toInt().toString();
      final value = "$saturationApi,$nodeId,$ssid,$password";
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
