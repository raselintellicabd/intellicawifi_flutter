import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/router_repository.dart';
import '../utils/ui_state.dart';

class RouterViewModel extends ChangeNotifier {
  final RouterRepository _repository = RouterRepository();

  UiState<RouterInfo> _routerInfo = UiState.loading();
  UiState<RouterInfo> get routerInfo => _routerInfo;

  UiState<List<ConnectedDevice>> _connectedDevices = UiState.loading();
  UiState<List<ConnectedDevice>> get connectedDevices => _connectedDevices;

  UiState<ConnectedDevice> _deviceDetails = UiState.loading();
  UiState<ConnectedDevice> get deviceDetails => _deviceDetails;

  UiState<bool> _operationResult = UiState.loading();
  UiState<bool> get operationResult => _operationResult;

  final Map<int, UiState<String>> _ssidNames = {};
  UiState<String> getSsidNameState(int index) => _ssidNames[index] ?? UiState.loading();

  void loadRouterInfo() async {
    _routerInfo = UiState.loading();
    notifyListeners();
    try {
      final info = await _repository.getRouterInfo();
      _routerInfo = UiState.success(info);
    } catch (e) {
      _routerInfo = UiState.error(e.toString());
    }
    notifyListeners();
  }

  void loadConnectedDevices() async {
    _connectedDevices = UiState.loading();
    notifyListeners();
    try {
      final devices = await _repository.getConnectedDevices();
      _connectedDevices = UiState.success(devices);
    } catch (e) {
      _connectedDevices = UiState.error(e.toString());
    }
    notifyListeners();
  }

  void loadDeviceDetails(String deviceId) async {
    _deviceDetails = UiState.loading();
    notifyListeners();
    try {
      final details = await _repository.getDeviceDetails(deviceId);
      _deviceDetails = UiState.success(details);
    } catch (e) {
      _deviceDetails = UiState.error(e.toString());
    }
    notifyListeners();
  }

  void loadSsidName(int ssidIndex) async {
    _ssidNames[ssidIndex] = UiState.loading();
    notifyListeners();
    try {
      final name = await _repository.getSsidName(ssidIndex);
      _ssidNames[ssidIndex] = UiState.success(name);
    } catch (e) {
      _ssidNames[ssidIndex] = UiState.error(e.toString());
    }
    notifyListeners();
  }

  Future<void> changeSsidName(int ssidIndex, String newSsid) async {
    _operationResult = UiState.loading();
    notifyListeners();
    if (newSsid.isEmpty) {
      _operationResult = UiState.error("Empty SSID Field");
      notifyListeners();
      return;
    }

    try {
      await _repository.setSsidName(ssidIndex, newSsid);
      _operationResult = UiState.success(true);
      loadSsidName(ssidIndex); // Refresh
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }
    notifyListeners();
  }

  Future<void> changeSsidPassword(int apIndex, String newPassword) async {
    if (newPassword.isEmpty) {
      _operationResult = UiState.error("Empty Password Field");
      notifyListeners();
      return;
    }
    
    _operationResult = UiState.loading();
    notifyListeners();

    try {
      await _repository.setSsidPassword(apIndex, newPassword);
      _operationResult = UiState.success(true);
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }
    notifyListeners();
  }

  Future<void> rebootRouter() async {
    _operationResult = UiState.loading();
    notifyListeners();
    try {
      await _repository.rebootRouter();
      _operationResult = UiState.success(true);
    } catch (e) {
      _operationResult = UiState.error(e.toString());
    }
    notifyListeners();
  }
}
