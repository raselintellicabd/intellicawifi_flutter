import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/router_viewmodel.dart';
import '../utils/ui_state.dart';

class ConnectedDevicesScreen extends StatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  State<ConnectedDevicesScreen> createState() => _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends State<ConnectedDevicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouterViewModel>().loadConnectedDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connected Devices")),
      body: Consumer<RouterViewModel>(
        builder: (context, viewModel, child) {
          final state = viewModel.connectedDevices;

          if (state.status == UiStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == UiStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text("Error: ${state.message}"),
                   ElevatedButton(onPressed: viewModel.loadConnectedDevices, child: const Text("Retry"))
                ],
              ),
            );
          }

          final devices = state.data ?? [];
          if (devices.isEmpty) {
            return const Center(child: Text("No connected devices found."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text("${index + 1}"),
                ),
                title: Text(device.hostname.isEmpty ? "Unknown Device" : device.hostname),
                subtitle: Text("MAC: ${device.macAddress}"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/device_details', 
                    arguments: device.id
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
