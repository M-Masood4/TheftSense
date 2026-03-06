export 'settings.dart';

import 'package:flutter/material.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'cameras.dart';
import 'pages/change_password_page.dart';
import 'services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pushNotificationsEnabled = true;
  bool _isRequestingPermission = false;
  String? _fcmToken;

  final NotificationService _notificationService = NotificationService();

  String? _selectedCameraToDelete;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final settings = await _notificationService.getNotificationSettings();
      final token = await _notificationService.getSavedToken();

      if (mounted) {
        setState(() {
          _fcmToken = token ?? _notificationService.fcmToken;
          pushNotificationsEnabled =
              settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
        });
      }
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
    }
  }

  Future<void> _togglePushNotifications(bool enable) async {
    if (enable) {
      setState(() {
        _isRequestingPermission = true;
      });

      try {
        final granted = await _notificationService.requestPermission();

        if (mounted) {
          setState(() {
            pushNotificationsEnabled = granted;
            _isRequestingPermission = false;
            _fcmToken = _notificationService.fcmToken;

            if (granted) {
              _statusMessage = 'Push notifications enabled!';
              // Subscribe to shoplifting alerts topic
              _notificationService.subscribeToTopic('shoplifting_alerts');
            } else {
              _statusMessage =
                  'Permission denied. Please enable notifications in browser settings.';
            }
          });
        }

        await _saveSettings();
      } catch (e) {
        debugPrint('Error enabling notifications: $e');
        if (mounted) {
          setState(() {
            _isRequestingPermission = false;
            _statusMessage = 'Error enabling notifications: $e';
          });
        }
      }
    } else {
      // Disable notifications
      try {
        await _notificationService.unsubscribeFromTopic('shoplifting_alerts');
        await _notificationService.deleteToken();

        if (mounted) {
          setState(() {
            pushNotificationsEnabled = false;
            _fcmToken = null;
            _statusMessage = 'Push notifications disabled.';
          });
        }

        await _saveSettings();
      } catch (e) {
        debugPrint('Error disabling notifications: $e');
        if (mounted) {
          setState(() {
            _statusMessage = 'Error disabling notifications: $e';
          });
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // Load saved settings from local storage
    try {
      final factory = getIdbFactory();
      final db = await factory!.open(
        'user_settings',
        version: 1,
        onUpgradeNeeded: (e) {
          final db = e.database;
          if (!db.objectStoreNames.contains('settings')) {
            db.createObjectStore('settings', keyPath: 'key');
          }
        },
      );

      final txn = db.transaction('settings', idbModeReadOnly);
      final store = txn.objectStore('settings');

      final notifSetting = await store.getObject('pushNotifications');

      await txn.completed;

      if (mounted) {
        setState(() {
          if (notifSetting != null) {
            pushNotificationsEnabled = (notifSetting as Map)['value'] ?? true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final factory = getIdbFactory();
      final db = await factory!.open(
        'user_settings',
        version: 1,
        onUpgradeNeeded: (e) {
          final db = e.database;
          if (!db.objectStoreNames.contains('settings')) {
            db.createObjectStore('settings', keyPath: 'key');
          }
        },
      );

      final txn = db.transaction('settings', idbModeReadWrite);
      final store = txn.objectStore('settings');

      await store.put({
        'key': 'pushNotifications',
        'value': pushNotificationsEnabled,
      });

      await txn.completed;

      if (mounted) {
        setState(() {
          _statusMessage = 'Settings saved successfully!';
        });
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error saving settings';
        });
      }
    }
  }

  Future<void> _deleteCamera(String cameraName) async {
    try {
      final factory = getIdbFactory();
      final db = await factory!.open('setup_cameras', version: 6);

      final txn = db.transaction('setup_cameras', idbModeReadWrite);
      final store = txn.objectStore('setup_cameras');

      final items = await store.getAll();
      final keys = await store.getAllKeys();

      for (int i = 0; i < items.length; i++) {
        final map = items[i] as Map;
        if (map['camName'] == cameraName) {
          await store.delete(keys[i]);
          break;
        }
      }

      await txn.completed;

      // Update the global lists
      final index = cameraNames.indexOf(cameraName);
      if (index != -1) {
        cameraNames.removeAt(index);
        cameraDetails.removeAt(index);
        thumbnails.removeAt(index);
      }

      if (mounted) {
        setState(() {
          _selectedCameraToDelete = null;
          _statusMessage = 'Camera "$cameraName" deleted successfully!';
        });
      }
    } catch (e) {
      debugPrint('Error deleting camera: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error deleting camera';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Status message
          if (_statusMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color:
                    _statusMessage.contains('Error') ||
                        _statusMessage.contains('do not match')
                    ? Colors.red.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusMessage.contains('Error') ||
                            _statusMessage.contains('do not match')
                        ? Icons.error
                        : Icons.check_circle,
                    color:
                        _statusMessage.contains('Error') ||
                            _statusMessage.contains('do not match')
                        ? Colors.red
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_statusMessage)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _statusMessage = ''),
                  ),
                ],
              ),
            ),

          // Push Notifications Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: Text(
                      _isRequestingPermission
                          ? 'Requesting permission...'
                          : 'Receive alerts when suspicious activity is detected',
                    ),
                    value: pushNotificationsEnabled,
                    onChanged: _isRequestingPermission
                        ? null
                        : (value) => _togglePushNotifications(value),
                    secondary: _isRequestingPermission
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications),
                  ),
                  if (_fcmToken != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.key, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text(
                          'Device Token:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Copy this token to send test notifications via Firebase Console or your backend.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Change Password Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Change Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Delete Camera Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Cameras',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (cameraNames.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No cameras configured',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCameraToDelete,
                          decoration: const InputDecoration(
                            labelText: 'Select Camera to Delete',
                            prefixIcon: Icon(Icons.videocam),
                            border: OutlineInputBorder(),
                          ),
                          items: cameraNames.map((name) {
                            return DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCameraToDelete = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _selectedCameraToDelete != null
                                ? () => _showDeleteConfirmation(context)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Selected Camera'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Camera'),
        content: Text(
          'Are you sure you want to delete "$_selectedCameraToDelete"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCamera(_selectedCameraToDelete!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
