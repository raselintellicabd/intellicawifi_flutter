import 'package:flutter/material.dart';
import '../utils/router_mac_manager.dart';

class MacAddressScreen extends StatefulWidget {
  const MacAddressScreen({super.key});

  @override
  State<MacAddressScreen> createState() => _MacAddressScreenState();
}

class _MacAddressScreenState extends State<MacAddressScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _savedMacs = [];

  @override
  void initState() {
    super.initState();
    _loadSavedMacs();
  }

  Future<void> _loadSavedMacs() async {
    final list = await RouterMacManager.getMacList();
    setState(() {
      _savedMacs = list;
    });
  }

  Future<void> _saveAndContinue(String mac) async {
    if (mac.trim().isEmpty) return;
    await RouterMacManager.saveMac(mac);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/overview', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Router MAC Setup")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             const Text(
              "Enter your router's MAC address",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Router MAC (e.g., 0201008DA89C)",
                hintText: "0201008DA89C",
                prefixIcon: Icon(Icons.router),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _saveAndContinue(_controller.text),
              icon: const Icon(Icons.save),
              label: const Text("Save and Continue"),
            ),
            const SizedBox(height: 32),
            const Text(
              "Saved MAC Addresses:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: _savedMacs.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final mac = _savedMacs[index];
                  return ListTile(
                    title: Text(mac),
                    leading: const Icon(Icons.history),
                    onTap: () {
                      _controller.text = mac;
                      _saveAndContinue(mac);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
