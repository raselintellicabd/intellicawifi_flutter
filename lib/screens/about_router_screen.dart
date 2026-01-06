import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/router_viewmodel.dart';
import '../utils/ui_state.dart';

class AboutRouterScreen extends StatelessWidget {
  const AboutRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Router"),
      ),
      body: Consumer<RouterViewModel>(
        builder: (context, viewModel, child) {
          final infoState = viewModel.routerInfo;

          if (infoState.status == UiStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (infoState.status == UiStatus.error) {
            return Center(child: Text("Error: ${infoState.message}"));
          }

          final info = infoState.data;
          if (info == null) {
            return const Center(child: Text("No information available"));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildInfoCard(context, "Device MAC", info.deviceMac, Icons.fingerprint),
              const SizedBox(height: 12),
              _buildInfoCard(context, "Model", info.modelName, Icons.router),
              const SizedBox(height: 12),
              _buildInfoCard(context, "Serial Number", info.serialNumber, Icons.qr_code),
              const SizedBox(height: 12),
              _buildInfoCard(context, "Software Version", info.softwareVersion, Icons.system_update),
              const SizedBox(height: 12),
              _buildInfoCard(context, "WAN IP", info.wanIpAddress, Icons.public),
              const SizedBox(height: 12),
              _buildInfoCard(context, "Uptime", info.uptime, Icons.timer),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
