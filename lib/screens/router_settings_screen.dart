import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/router_viewmodel.dart';
import '../utils/ui_state.dart';

class RouterSettingsScreen extends StatefulWidget {
  const RouterSettingsScreen({super.key});

  @override
  State<RouterSettingsScreen> createState() => _RouterSettingsScreenState();
}

class _RouterSettingsScreenState extends State<RouterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RouterViewModel>();
      vm.loadSsidName(10001);
      vm.loadSsidName(10101);
      vm.loadSsidName(10201);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Router Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSsidSection(10001, "SSID 1 (2.4GHz)"),
            const SizedBox(height: 16),
            _buildSsidSection(10101, "SSID 2 (5GHz)"),
            const SizedBox(height: 16),
            _buildSsidSection(10201, "SSID 3 (Guest)"),
          ],
        ),
      ),
    );
  }

  Widget _buildSsidSection(int index, String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Consumer<RouterViewModel>(
              builder: (context, vm, child) {
                final state = vm.getSsidNameState(index);
                if (state.status == UiStatus.loading) {
                   return const Center(child: CircularProgressIndicator());
                }
                
                final currentSsid = state.data ?? "Error";
                return Column(
                  children: [
                    ListTile(
                      title: const Text("Current SSID"),
                      subtitle: Text(currentSsid),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditSsidDialog(context, index, currentSsid),
                      ),
                    ),
                    ListTile(
                      title: const Text("Password"),
                      subtitle: const Text("********"),
                      trailing: IconButton(
                        icon: const Icon(Icons.lock),
                        onPressed: () => _showEditPasswordDialog(context, index),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSsidDialog(BuildContext context, int index, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Change SSID Name"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "New SSID")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              context.read<RouterViewModel>().changeSsidName(index, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showEditPasswordDialog(BuildContext context, int index) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Change Password"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "New Password")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              context.read<RouterViewModel>().changeSsidPassword(index, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
