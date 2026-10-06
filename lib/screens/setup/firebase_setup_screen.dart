import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import '../../services/persistence_service.dart';
import '../../services/json_import_service.dart';
import '../../widgets/common/aurexa_space_background.dart';

class FirebaseSetupScreen extends ConsumerStatefulWidget {
  const FirebaseSetupScreen({super.key});

  @override
  ConsumerState<FirebaseSetupScreen> createState() =>
      _FirebaseSetupScreenState();
}

class _FirebaseSetupScreenState extends ConsumerState<FirebaseSetupScreen> {
  static const _channel = MethodChannel('com.aurexa.core/fingerprints');

  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _dbUrlController = TextEditingController();
  final _appIdController = TextEditingController();
  final _senderIdController = TextEditingController();
  final _webClientIdController = TextEditingController();

  String _packageName = 'Loading...';
  String _sha1 = 'Loading...';
  String _sha256 = 'Loading...';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    String sha1 = 'Not Available';
    String sha256 = 'Not Available';

    try {
      final Map<dynamic, dynamic> fingerprints = await _channel.invokeMethod(
        'getFingerprints',
      );
      sha1 = fingerprints['sha1'] ?? 'Not Available';
      sha256 = fingerprints['sha256'] ?? 'Not Available';
    } catch (e) {
      debugPrint('Error getting signing info via MethodChannel: $e');
    }

    if (mounted) {
      setState(() {
        _packageName = info.packageName;
        _sha1 = sha1;
        _sha256 = sha256;
      });

      // Populate controllers with existing config if available
      final config = await PersistenceService.getFirebaseConfig();
      if (config != null) {
        _apiKeyController.text = config['apiKey'] ?? '';
        _projectIdController.text = config['projectId'] ?? '';
        _dbUrlController.text = config['databaseURL'] ?? '';
        _appIdController.text = config['appId'] ?? '';
        _senderIdController.text = config['messagingSenderId'] ?? '';
        _webClientIdController.text = config['googleWebClientId'] ?? '';
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final config = {
        'apiKey': _apiKeyController.text.trim(),
        'projectId': _projectIdController.text.trim(),
        'databaseURL': _dbUrlController.text.trim(),
        'appId': _appIdController.text.trim(),
        'messagingSenderId': _senderIdController.text.trim(),
        'googleWebClientId': _webClientIdController.text.trim(),
      };

      await PersistenceService.saveFirebaseConfig(config);

      // Notify user to restart app for initialization
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Configuration Saved',
              style: TextStyle(color: Colors.cyanAccent),
            ),
            content: const Text(
              'Please restart the application to initialize your custom Firebase backend.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text(
                  'RESTART NOW',
                  style: TextStyle(color: Colors.cyanAccent),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving config: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _importJson() async {
    try {
      final jsonService = JsonImportService();
      final json = await jsonService.pickJsonFile();

      if (json != null) {
        final config = jsonService.extractFirebaseConfig(json);
        if (config != null) {
          setState(() {
            _apiKeyController.text = config['apiKey'] ?? '';
            _projectIdController.text = config['projectId'] ?? '';
            _dbUrlController.text = config['databaseURL'] ?? '';
            _appIdController.text = config['appId'] ?? '';
            _senderIdController.text = config['messagingSenderId'] ?? '';
            _webClientIdController.text = config['googleWebClientId'] ?? '';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Firebase config imported! Now click INITIALIZE.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Could not extract config from this JSON file.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.getTheme(AppThemeMode.dark),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AurexaSpaceBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: RepaintBoundary(
                child: Form(
                  key: _formKey,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.help_outline, color: Colors.white70, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // HEADER
                    Row(
                      children: [
                        Text(
                          'AUREXA ',
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.cyanAccent, Colors.purpleAccent],
                          ).createShader(bounds),
                          child: Text(
                            'CORE',
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PRODUCTION SETUP',
                      style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Configure your Firebase project to connect Aurexa Home with your devices.',
                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 30),

                    // FIREBASE CONSOLE INFO
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Firebase Console Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 2),
                                    const Text('App verification details', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    const Text('Ready', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildFingerprintRow('Package Name', _packageName),
                          const SizedBox(height: 16),
                          _buildFingerprintRow('SHA-1', _sha1),
                          const SizedBox(height: 16),
                          _buildFingerprintRow('SHA-256', _sha256),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // IMPORT JSON
                    GestureDetector(
                      onTap: _importJson,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.5), width: 1.5),
                          gradient: LinearGradient(
                            colors: [Colors.purpleAccent.withOpacity(0.05), Colors.transparent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.purpleAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.cloud_upload_rounded, color: Colors.purpleAccent, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Import Google-Services.json', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  const Text('Upload your Firebase config file', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // API KEY
                    _buildConfigTile(
                      icon: Icons.key_rounded,
                      iconColor: Colors.blueAccent,
                      title: 'API Key',
                      subtitle: _apiKeyController.text.isEmpty ? 'Add your Web API Key' : 'Configured',
                      onTap: () => _showEditDialog('API Key', _apiKeyController),
                    ),
                    const SizedBox(height: 16),

                    // PROJECT ID
                    _buildConfigTile(
                      icon: Icons.folder_rounded,
                      iconColor: Colors.amberAccent,
                      title: 'Project ID',
                      subtitle: _projectIdController.text.isEmpty ? 'Enter your Firebase Project ID' : 'Configured',
                      onTap: () => _showEditDialog('Project ID', _projectIdController),
                    ),
                    const SizedBox(height: 16),

                    // DATABASE URL
                    _buildConfigTile(
                      icon: Icons.storage_rounded,
                      iconColor: Colors.cyanAccent,
                      title: 'Database URL',
                      subtitle: _dbUrlController.text.isEmpty ? 'Enter your Realtime Database URL' : 'Configured',
                      onTap: () => _showEditDialog('Database URL', _dbUrlController),
                    ),
                    const SizedBox(height: 16),
                    
                    // APP ID & OTHER
                    _buildConfigTile(
                      icon: Icons.app_registration_rounded,
                      iconColor: Colors.pinkAccent,
                      title: 'App ID',
                      subtitle: _appIdController.text.isEmpty ? 'Enter your Firebase App ID' : 'Configured',
                      onTap: () => _showEditDialog('App ID', _appIdController),
                    ),
                    const SizedBox(height: 16),

                    // SECURE STORED
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield_rounded, color: Colors.greenAccent, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your credentials are stored securely', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                SizedBox(height: 2),
                                Text('Only on this device', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.white38, size: 20),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text('INITIALIZE AUREXA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(String title, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Edit $title', style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter $title',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                setState(() {});
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text('SAVE', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfigTile({required IconData icon, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerprintRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied!'), backgroundColor: Colors.cyanAccent));
          },
          child: const Icon(Icons.copy, color: Colors.cyanAccent, size: 18),
        ),
      ],
    );
  }
}
