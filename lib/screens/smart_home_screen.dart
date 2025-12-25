import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../viewmodels/smart_home_viewmodel.dart';
import '../utils/ui_state.dart';

import 'qr_scanner_screen.dart';

class SmartHomeScreen extends StatefulWidget {
  const SmartHomeScreen({super.key});

  @override
  State<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  String _wifiSsid = "";
  String _wifiPassword = "";
  bool _wifiConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkWifiConfig();
  }

  Future<void> _checkWifiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final ssid = prefs.getString('wifi_ssid');
    final password = prefs.getString('wifi_password');

    if (ssid != null && password != null && ssid.isNotEmpty && password.isNotEmpty) {
      if (mounted) {
        setState(() {
          _wifiSsid = ssid;
          _wifiPassword = password;
          _wifiConfigured = true;
        });
      }
    } else {
      if (mounted) {
        _showWifiConfigDialog();
      }
    }
    
    if (mounted) {
      context.read<SmartHomeViewModel>().loadDevices();
    }
  }

  void _showWifiConfigDialog() {
    final ssidController = TextEditingController(text: _wifiSsid);
    final passController = TextEditingController(text: _wifiPassword);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Configure WiFi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter WiFi details for smart devices."),
            const SizedBox(height: 12),
            TextField(controller: ssidController, decoration: const InputDecoration(labelText: "SSID")),
            const SizedBox(height: 8),
            TextField(controller: passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
          ],
        ),
        actions: [
          TextButton(
             onPressed: () {
               // Allow closing only if we already have config.
               // But original code didn't allow closing initially. 
               // The logic below ensures it saves if valid, but if user just wants to cancel 'Settings' changes, we might want a cancel button.
               // For now, I'll add Cancel only if _wifiConfigured is true.
               if (_wifiConfigured) Navigator.pop(ctx);
             },
             child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ssidController.text.isNotEmpty && passController.text.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('wifi_ssid', ssidController.text);
                await prefs.setString('wifi_password', passController.text);

                if (mounted) {
                  setState(() {
                    _wifiSsid = ssidController.text;
                    _wifiPassword = passController.text;
                    _wifiConfigured = true;
                  });
                  Navigator.pop(ctx);
                  context.read<SmartHomeViewModel>().loadDevices(); // Reload with new config if needed
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showWifiConfigDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SmartHomeViewModel>().loadDevices(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<SmartHomeViewModel>(
        builder: (context, vm, child) {
          // Listen for operation result
          if (vm.operationResult != null) {
            final result = vm.operationResult!;
            // Using addPostFrameCallback to avoid setstate during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (result.status == UiStatus.success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.data!), backgroundColor: Colors.green));
                  vm.clearOperationResult();
              } else if (result.status == UiStatus.error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message!), backgroundColor: Colors.red));
                  vm.clearOperationResult();
              }
            });
          }
        
          if (vm.devices.status == UiStatus.loading && !vm.isOperationLoading) { // don't hide list if just op loading
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.devices.status == UiStatus.error) {
            return Center(child: Text("Error: ${vm.devices.message}"));
          }

          final devices = vm.devices.data ?? [];
          
          return Stack(
            children: [
              if (devices.isEmpty)
                const Center(child: Text("No smart devices found.")),
              if (devices.isNotEmpty)
                ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb, size: 32, color: Colors.orange),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Light Device", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text("ID: ${device.nodeId}", style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Switch(
                              value: device.isOn,
                              onChanged: (val) {
                                vm.toggleDevice(device.nodeId, device.isOn, _wifiSsid, _wifiPassword);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => vm.removeDevice(device.nodeId, _wifiSsid, _wifiPassword),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
              if (vm.isOperationLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             CircularProgressIndicator(),
                             SizedBox(height: 16),
                             Text("Processing..."),
                           ],
                         ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.keyboard),
                title: const Text('Enter Code'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddDeviceDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('Scan QR Code'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                  );
                  if (result != null && result is String) {
                     if (mounted) {
                       context.read<SmartHomeViewModel>().commissionDevice(result, _wifiSsid, _wifiPassword);
                     }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddDeviceDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Device"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Device Pairing Code"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              context.read<SmartHomeViewModel>().commissionDevice(controller.text, _wifiSsid, _wifiPassword);
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
