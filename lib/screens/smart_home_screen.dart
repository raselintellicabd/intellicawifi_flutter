import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../viewmodels/smart_home_viewmodel.dart';
import '../utils/ui_state.dart';
import '../models/models.dart';
import '../widgets/circular_color_picker.dart';

import 'qr_scanner_screen.dart';

class SmartHomeScreen extends StatefulWidget {
  const SmartHomeScreen({super.key});

  @override
  State<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  // Local state for wifi is now in ViewModel

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWifiConfig();
    });
  }

  Future<void> _checkWifiConfig() async {
    if (!mounted) return;
    final vm = context.read<SmartHomeViewModel>();
    
    // Check config
    await vm.loadWifiConfig();

    if (!vm.isWifiConfigured) {
      if (mounted) {
        _showWifiConfigDialog();
      }
    }
    
    if (mounted) {
      vm.loadDevices();
    }
  }

  void _showWifiConfigDialog() {
    final vm = context.read<SmartHomeViewModel>();
    final ssidController = TextEditingController(text: vm.ssid);
    final passController = TextEditingController(text: vm.password);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isObscured = true;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Configure WiFi"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Enter WiFi details for smart devices."),
                  const SizedBox(height: 12),
                  TextField(
                      controller: ssidController,
                      decoration: const InputDecoration(labelText: "SSID")),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passController,
                    decoration: InputDecoration(
                      labelText: "Password",
                      suffixIcon: IconButton(
                        icon: Icon(isObscured
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setDialogState(() {
                            isObscured = !isObscured;
                          });
                        },
                      ),
                    ),
                    obscureText: isObscured,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (vm.isWifiConfigured) Navigator.pop(ctx);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (ssidController.text.isNotEmpty &&
                        passController.text.isNotEmpty) {
                      
                      final success = await vm.saveWifiConfig(
                          ssidController.text, passController.text);
                      
                      if (success && mounted) {
                        Navigator.pop(ctx);
                        vm.loadDevices();
                      }
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
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
                    return _buildDeviceCard(device, vm);
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

  Widget _buildDeviceCard(SmartDevice device, SmartHomeViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, size: 32, color: Colors.orange),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("ID: ${device.nodeId}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Switch(
                  value: device.isOn,
                  onChanged: (val) {
                    vm.toggleDevice(device.nodeId, device.isOn);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => vm.removeDevice(device.nodeId),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showColorPickerWithDialog(device),
                    icon: const Icon(Icons.palette, size: 18),
                    label: const Text("", style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBrightnessDialog(device),
                    icon: const Icon(Icons.wb_sunny, size: 18),
                    label: const Text("", style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSaturationDialog(device),
                    icon: const Icon(Icons.contrast, size: 18), // Use nearest material icon
                    label: const Text("", style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showColorPickerWithDialog(SmartDevice device) {
    String selectedColor = "Red";
    int selectedHue = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Select Color"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Device: ${device.nodeId}", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              CircularColorPicker(
                selectedColorName: selectedColor,
                onColorSelected: (name, hue) {
                  selectedColor = name;
                  selectedHue = hue;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<SmartHomeViewModel>().setDeviceColor(
                    device.nodeId, selectedHue);
                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showBrightnessDialog(SmartDevice device) {
    double value = 50;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Adjust Brightness"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Device: ${device.nodeId}", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Text("${value.round()}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: value.round().toString(),
                    onChanged: (val) {
                      setState(() {
                        value = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<SmartHomeViewModel>().setDeviceBrightness(
                        device.nodeId, value.round());
                    Navigator.pop(ctx);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showSaturationDialog(SmartDevice device) {
    double value = 50;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Adjust Saturation"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Device: ${device.nodeId}", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Text("${value.round()}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: value.round().toString(),
                    onChanged: (val) {
                      setState(() {
                        value = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<SmartHomeViewModel>().setDeviceSaturation(
                        device.nodeId, value.round());
                    Navigator.pop(ctx);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          }
        );
      },
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
                       context.read<SmartHomeViewModel>().commissionDevice(result);
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
              context.read<SmartHomeViewModel>().commissionDevice(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
