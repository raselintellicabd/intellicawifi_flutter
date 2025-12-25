import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/router_viewmodel.dart';
import '../utils/ui_state.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouterViewModel>().loadRouterInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RouterViewModel>().loadRouterInfo(),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () => _showRebootDialog(context),
          )
        ],
      ),
      body: Consumer<RouterViewModel>(
        builder: (context, viewModel, child) {
          final infoState = viewModel.routerInfo;
          
          if (infoState.status == UiStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (infoState.status == UiStatus.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Error: ${infoState.message}", style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: viewModel.loadRouterInfo, 
                    child: const Text("Retry")
                  )
                ],
              ),
            );
          }
          
          final info = infoState.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard("Model", info.modelName, Icons.router),
                const SizedBox(height: 12),
                _buildInfoCard("Serial Number", info.serialNumber, Icons.qr_code),
                const SizedBox(height: 12),
                _buildInfoCard("Software Version", info.softwareVersion, Icons.system_update),
                const SizedBox(height: 12),
                _buildInfoCard("WAN IP", info.wanIpAddress, Icons.public),
                const SizedBox(height: 12),
                _buildInfoCard("Uptime", info.uptime, Icons.timer),
                
                const SizedBox(height: 24),
                const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildActionCard(
                      context, 
                      "Connected Devices", 
                      Icons.devices, 
                      Colors.blue, 
                      () => Navigator.pushNamed(context, '/connected_devices')
                    ),
                    _buildActionCard(
                      context, 
                      "Smart Home", 
                      Icons.home_filled, 
                      Colors.green, 
                      () => Navigator.pushNamed(context, '/smart_home')
                    ),
                    _buildActionCard(
                      context, 
                      "Settings", 
                      Icons.settings, 
                      Colors.orange, 
                      () => Navigator.pushNamed(context, '/router_settings')
                    ),
                    _buildActionCard(
                       context,
                       "Change MAC",
                       Icons.edit,
                       Colors.purple,
                       () => Navigator.pushNamed(context, '/mac_address')),
                  ],
                ),
              ],
            ),
          );
        }, // builder
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showRebootDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reboot Router"),
        content: const Text("Are you sure you want to reboot the router?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<RouterViewModel>().rebootRouter();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Reboot command sent")),
              );
            },
            child: const Text("Reboot", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
