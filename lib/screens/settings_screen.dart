import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_apps/device_apps.dart';
import '../providers/quest_provider.dart';
import '../services/lock_service.dart';
import '../models/settings.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Application> _apps = [];
  bool _isLoading = true;
  String? _selectedAppPackage;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadApps();
  }

  Future<void> _checkPermissionsAndLoadApps() async {
    bool usageGranted = await UsageStats.checkUsagePermission() ?? false;
    if (!usageGranted) {
      await UsageStats.grantUsagePermission();
    }

    bool overlayGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!overlayGranted) {
      await FlutterOverlayWindow.requestPermission();
    }

    final apps = await LockService.instance.fetchInstalledApps();
    setState(() {
      _apps = apps;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuestProvider>(context);
    _selectedAppPackage ??= provider.settings?.targetAppPackage;

    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SELECT TARGET APP', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('This app will be locked tomorrow if you do not complete 100% of your quests today.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _apps.length,
                      itemBuilder: (context, index) {
                        final app = _apps[index];
                        final isSelected = app.packageName == _selectedAppPackage;
                        return ListTile(
                          leading: app is ApplicationWithIcon
                              ? Image.memory(app.icon, width: 40, height: 40)
                              : const Icon(Icons.android),
                          title: Text(app.appName, style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Colors.white)),
                          subtitle: Text(app.packageName, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
                          onTap: () {
                            setState(() {
                              _selectedAppPackage = app.packageName;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                      onPressed: () {
                        if (_selectedAppPackage != null) {
                          provider.saveSettings(Settings(
                            targetAppPackage: _selectedAppPackage!,
                            lockActiveStatus: true,
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Saved!')));
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('SAVE SETTINGS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
