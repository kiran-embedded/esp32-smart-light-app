import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import '../../services/persistence_service.dart';
import '../../services/json_import_service.dart';
import '../../widgets/setup/setup_guide_dialog.dart';
import '../../widgets/common/frosted_glass.dart';
import '../../widgets/common/nebula_space_background.dart';

class FirebaseSetupScreen extends ConsumerStatefulWidget {
  const FirebaseSetupScreen({super.key});

  @override
  ConsumerState<FirebaseSetupScreen> createState() =>
      _FirebaseSetupScreenState();
}

class _FirebaseSetupScreenState extends ConsumerState<FirebaseSetupScreen> {
  static const _channel = MethodChannel('com.nebula.core/fingerprints');

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: NebulaSpaceBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'NEBULA CORE',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Production Setup',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const SetupGuideDialog(),
                          );
                        },
                        icon: const Icon(
                          Icons.help_outline,
                          color: Colors.cyanAccent,
                        ),
                        tooltip: 'How to setup?',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildImportButton(),
                  const SizedBox(height: 20),
                  _buildRegistrationForm(),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFingerprintCard() {
    return FrostedGlass(
      padding: const EdgeInsets.all(20),
      radius: BorderRadius.circular(28),
      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'FOR FIREBASE CONSOLE:',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Package Name', _packageName),
          const SizedBox(height: 8),
          _buildInfoRow('SHA-1', _sha1),
          const SizedBox(height: 8),
          _buildInfoRow('SHA-256', _sha256),
        ],
      ),
    );
  }

  Widget _buildImportButton() {
    return Column(
      children: [
        _buildFingerprintCard(),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _importJson,
            icon: const Icon(Icons.file_upload, color: Colors.cyanAccent),
            label: const Text(
              'IMPORT GOOGLE-SERVICES.JSON',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: Colors.cyanAccent, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Fast setup: Upload your Firebase config file',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied!'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: const Icon(Icons.copy, size: 16, color: Colors.cyanAccent),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _apiKeyController,
            label: 'API Key',
            hint: 'AIzaSy...',
            icon: Icons.api,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _projectIdController,
            label: 'Project ID',
            hint: 'my-nebula-project',
            icon: Icons.folder,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _dbUrlController,
            label: 'Database URL',
            hint: 'https://....firebasedatabase.app',
            icon: Icons.storage,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _appIdController,
            label: 'App ID',
            hint: '1:123456:android:...',
            icon: Icons.app_registration,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _senderIdController,
            label: 'Messaging Sender ID',
            hint: '123456789',
            icon: Icons.message,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _webClientIdController,
            label: 'Google Web Client ID (for Auth)',
            hint: '123456789-abc.apps.googleusercontent.com',
            icon: Icons.web,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return FrostedGlass(
      padding: EdgeInsets.zero,
      radius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.cyanAccent),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(icon, color: Colors.cyanAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveConfig,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 10,
          shadowColor: Colors.cyanAccent.withOpacity(0.5),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.black)
            : const Text(
                'INITIALIZE NEBULA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }
}
