import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/router_viewmodel.dart';
import '../utils/ui_state.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final String deviceId;
  const DeviceDetailsScreen({super.key, required this.deviceId});

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouterViewModel>().loadDeviceDetails(widget.deviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Device Details")),
      body: Consumer<RouterViewModel>(
        builder: (context, viewModel, child) {
          final state = viewModel.deviceDetails;
          
          if (state.status == UiStatus.loading) {
             return const Center(child: CircularProgressIndicator());
          }
          
          if (state.status == UiStatus.error) {
             return Center(child: Text("Error: ${state.message}"));
          }
          
          final device = state.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
             child: Column(
               children: [
                 _buildDetailRow("Hostname", device.hostname),
                 _buildDetailRow("IP Address", device.ipAddress),
                 _buildDetailRow("MAC Address", device.macAddress),
                 _buildDetailRow("Signal Strength", device.signalStrength),
                 _buildDetailRow("Download Rate", device.downloadRate),
                 _buildDetailRow("Upload Rate", device.uploadRate),
                 _buildDetailRow("Connection Type", device.connectionType),
               ],
             ),
          );
        },
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value),
      ),
    );
  }
}
