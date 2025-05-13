import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = true;

  // Notification settings
  bool _enableMaintenanceReminders = true;
  bool _enableOverdueAlerts = true;
  int _reminderDaysAhead = 7;
  bool _enableDailyDigest = false;
  TimeOfDay _dailyDigestTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _enableMaintenanceReminders =
            prefs.getBool('enable_maintenance_reminders') ?? true;
        _enableOverdueAlerts = prefs.getBool('enable_overdue_alerts') ?? true;
        _reminderDaysAhead = prefs.getInt('reminder_days_ahead') ?? 7;
        _enableDailyDigest = prefs.getBool('enable_daily_digest') ?? false;

        final hour = prefs.getInt('daily_digest_hour') ?? 8;
        final minute = prefs.getInt('daily_digest_minute') ?? 0;
        _dailyDigestTime = TimeOfDay(hour: hour, minute: minute);

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(
        'enable_maintenance_reminders',
        _enableMaintenanceReminders,
      );
      await prefs.setBool('enable_overdue_alerts', _enableOverdueAlerts);
      await prefs.setInt('reminder_days_ahead', _reminderDaysAhead);
      await prefs.setBool('enable_daily_digest', _enableDailyDigest);
      await prefs.setInt('daily_digest_hour', _dailyDigestTime.hour);
      await prefs.setInt('daily_digest_minute', _dailyDigestTime.minute);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDailyDigestTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dailyDigestTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dailyDigestTime) {
      setState(() {
        _dailyDigestTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Color(0xFF1A1A1A)],
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Maintenance Reminders Section
                    _buildSectionHeader('Maintenance Reminders'),

                    SwitchListTile(
                      title: const Text(
                        'Enable Maintenance Reminders',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Receive notifications for upcoming maintenance',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _enableMaintenanceReminders,
                      onChanged: (value) {
                        setState(() {
                          _enableMaintenanceReminders = value;
                        });
                      },
                      activeColor: Colors.amber,
                    ),

                    const Divider(color: Colors.white24),

                    SwitchListTile(
                      title: const Text(
                        'Overdue Maintenance Alerts',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Receive alerts for overdue maintenance tasks',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _enableOverdueAlerts,
                      onChanged:
                          _enableMaintenanceReminders
                              ? (value) {
                                setState(() {
                                  _enableOverdueAlerts = value;
                                });
                              }
                              : null,
                      activeColor: Colors.amber,
                    ),

                    const Divider(color: Colors.white24),

                    ListTile(
                      title: const Text(
                        'Reminder Days Ahead',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Notify me $_reminderDaysAhead days before due date',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      enabled: _enableMaintenanceReminders,
                    ),

                    Slider(
                      value: _reminderDaysAhead.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: _reminderDaysAhead.toString(),
                      activeColor: Colors.amber,
                      inactiveColor: Colors.grey,
                      onChanged:
                          _enableMaintenanceReminders
                              ? (value) {
                                setState(() {
                                  _reminderDaysAhead = value.round();
                                });
                              }
                              : null,
                    ),

                    const SizedBox(height: 24),

                    // Daily Digest Section
                    _buildSectionHeader('Daily Digest'),

                    SwitchListTile(
                      title: const Text(
                        'Enable Daily Digest',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Receive a daily summary of maintenance tasks',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: _enableDailyDigest,
                      onChanged:
                          _enableMaintenanceReminders
                              ? (value) {
                                setState(() {
                                  _enableDailyDigest = value;
                                });
                              }
                              : null,
                      activeColor: Colors.amber,
                    ),

                    const Divider(color: Colors.white24),

                    ListTile(
                      title: const Text(
                        'Daily Digest Time',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Sent at ${_dailyDigestTime.format(context)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(
                        Icons.access_time,
                        color: Colors.amber,
                      ),
                      enabled:
                          _enableMaintenanceReminders && _enableDailyDigest,
                      onTap:
                          _enableMaintenanceReminders && _enableDailyDigest
                              ? _selectDailyDigestTime
                              : null,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            color: Colors.amber,
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}
