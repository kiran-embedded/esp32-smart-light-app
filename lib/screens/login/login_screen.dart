import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/frosted_glass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/json_import_service.dart';
import '../../widgets/common/json_paste_dialog.dart';
import '../../widgets/common/firebase_status_dialog.dart';
import '../../widgets/robo/robo_assistant.dart';
import '../../widgets/common/nebula_space_background.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'reboot_screen.dart'; // Added

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  String _sha1 = 'Loading...';
  String _sha256 = 'Loading...';
  String _packageName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadFingerprints();
  }

  Future<void> _loadFingerprints() async {
    try {
      const channel = MethodChannel('com.nebula.core/fingerprints');
      final Map<dynamic, dynamic> fingerprints = await channel.invokeMethod(
        'getFingerprints',
      );
      final packageInfo = await PackageInfo.fromPlatform();

      if (mounted) {
        setState(() {
          _sha1 = fingerprints['sha1'] ?? 'Not Available';
          _sha256 = fingerprints['sha256'] ?? 'Not Available';
          _packageName = packageInfo.packageName;
        });
      }
    } catch (e) {
      debugPrint('Error loading fingerprints: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    // 1. Show Visual Fluff (Reboot Screen) immediately
    // usage: Navigator.push(... RebootScreen ...)
    if (!mounted) return;

    // We push the reboot screen. It runs its own timer.
    // However, if login fails, we must POP it.
    // If login succeeds, the RebootScreen will trigger RestartWidget.restartApp
    // which effectively "wipes" the navigator, so we don't need to pop.

    // Show Reboot Screen (It looks cool !)
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RebootScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    try {
      // 2. Perform background login while user watches the show
      await ref
          .read(authProvider.notifier)
          .signIn()
          .timeout(
            const Duration(seconds: 25), // Give plenty of time
            onTimeout: () {
              throw Exception('Sign-in timed out.');
            },
          );

      // Check if actually authenticated
      if (ref.read(authProvider) == AuthState.authenticated) {
        // User stays on RebootScreen, which eventually calls RestartWidget.restartApp(context)
      } else {
        throw Exception("Auth failed state check");
      }
    } catch (e) {
      if (!mounted) return;

      // If we failed, we must HIDE the cool reboot screen and show error
      Navigator.of(context).pop();

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // FORCE DARK MODE for Login Screen because it uses a dark space background
    // This allows the text to be correctly colored (white) even if the app is in "Apple Glass" (light) mode.
    final theme = AppTheme.getTheme(AppThemeMode.darkNeon);
    final authState = ref.watch(authProvider);

    // Watchdog: If state becomes authenticated, ensure loading stops immediately
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next == AuthState.authenticated) {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
          // Main.dart will switch the widget automatically
        }
      }
    });

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Background handles it
        resizeToAvoidBottomInset: true,
        body: NebulaSpaceBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const RoboAssistant(),
                    const SizedBox(height: 40),
                    FrostedGlass(
                      padding: const EdgeInsets.all(32),
                      radius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1.2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Let's connect your home ✨",
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          _buildGoogleSignInButton(context, theme),
                          const SizedBox(height: 16),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: theme.dividerColor.withOpacity(0.3),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'OR',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: theme.dividerColor.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });

                              try {
                                final jsonService = JsonImportService();
                                final json = await jsonService.pickJsonFile();

                                if (json != null &&
                                    jsonService.validateGoogleServicesJson(
                                      json,
                                    )) {
                                  await ref
                                      .read(authProvider.notifier)
                                      .signInWithJson(json);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'JSON imported successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else if (json != null) {
                                  setState(() {
                                    _errorMessage =
                                        'Invalid google-services.json format';
                                    _isLoading = false;
                                  });
                                } else {
                                  setState(() => _isLoading = false);
                                }
                              } catch (e) {
                                setState(() {
                                  _errorMessage = e.toString();
                                  _isLoading = false;
                                });
                              }
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Import Settings JSON'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () async {
                              final json = await showDialog(
                                context: context,
                                builder: (context) => const JsonPasteDialog(),
                              );

                              if (json != null && mounted) {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = null;
                                });

                                try {
                                  await ref
                                      .read(authProvider.notifier)
                                      .signInWithJson(json);
                                } catch (e) {
                                  setState(() {
                                    _errorMessage = e.toString();
                                    _isLoading = false;
                                  });
                                }
                              }
                            },
                            child: const Text('Paste JSON manually'),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.error.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            const FirebaseStatusDialog(),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.info_outline,
                                      size: 16,
                                    ),
                                    label: const Text('Check Firebase Status'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildFingerprintInfo(theme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : const Icon(Icons.login),
        label: Text(_isLoading ? 'Connecting...' : 'Sign in with Google'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFingerprintInfo(ThemeData theme) {
    return FrostedGlass(
      padding: const EdgeInsets.all(16),
      radius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fingerprint,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Firebase Link Info',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFingerprintRow('Package', _packageName, theme),
          const SizedBox(height: 8),
          _buildFingerprintRow('SHA-1', _sha1, theme),
          const SizedBox(height: 8),
          _buildFingerprintRow('SHA-256', _sha256, theme),
        ],
      ),
    );
  }

  Widget _buildFingerprintRow(String label, String value, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16, color: Colors.cyanAccent),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label copied to clipboard'),
                duration: const Duration(seconds: 1),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          },
          tooltip: 'Copy $label',
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
