import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/persistence_service.dart';
import '../../services/json_import_service.dart';
import '../../widgets/common/json_paste_dialog.dart';
import '../settings/help_center_sheet.dart';
import 'reboot_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _channel = MethodChannel('com.aurexa.core/fingerprints');

  final _apiKeyController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _dbUrlController = TextEditingController();
  final _appIdController = TextEditingController();
  final _senderIdController = TextEditingController();
  final _webClientIdController = TextEditingController();

  String _packageName = 'Loading...';
  String _sha1 = 'Loading...';
  String _sha256 = 'Loading...';
  bool _isLoading = false;
  String? _errorMessage;

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
      final Map<dynamic, dynamic> fingerprints = await _channel.invokeMethod('getFingerprints');
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

  Future<void> _handleGoogleSignIn() async {
    if (!mounted || _isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final Completer<bool> authCompleter = Completer<bool>();
    
    // Show RebootScreen (splash) after login starts
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RebootScreen(authFuture: authCompleter.future),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    try {
      await ref.read(authProvider.notifier).signIn().timeout(
        const Duration(seconds: 45), // Increased timeout
        onTimeout: () => throw Exception('Sign-in timed out. Please try again.'),
      );
      
      authCompleter.complete(true);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!authCompleter.isCompleted) {
        authCompleter.complete(false);
      }
      if (!mounted) return;
      setState(() {
        String msg = e.toString().replaceAll('Exception:', '').trim();
        if (msg.contains('not registered') || msg.contains('12500')) {
          msg = 'Firebase Auth Failed! Please add this SHA-1 to your Firebase Project Settings: \n\n$_sha1\n\nEnsure your Web Client ID and Package Name (com.aurexa.app) match exactly.';
        }
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  Future<void> _importJson() async {
    final jsonService = JsonImportService();
    final json = await jsonService.pickJsonFile();
    if (json == null) return;
    
    if (!jsonService.validateGoogleServicesJson(json)) {
      setState(() => _errorMessage = 'Invalid google-services.json format');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });
    final Completer<bool> authCompleter = Completer<bool>();
    
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RebootScreen(authFuture: authCompleter.future),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    try {
      await ref.read(authProvider.notifier).signInWithJson(json);
      authCompleter.complete(true);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!authCompleter.isCompleted) authCompleter.complete(false);
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pasteJson() async {
    final json = await showDialog(
      context: context,
      builder: (context) => const JsonPasteDialog(),
    );
    if (json == null || !mounted) return;

    setState(() { _isLoading = true; _errorMessage = null; });
    final Completer<bool> authCompleter = Completer<bool>();
    
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RebootScreen(authFuture: authCompleter.future),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    try {
      await ref.read(authProvider.notifier).signInWithJson(json);
      authCompleter.complete(true);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!authCompleter.isCompleted) authCompleter.complete(false);
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showEditDialog(String title, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          title: Text('Edit $title', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Enter $title',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.cyanAccent : Colors.green)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.cyanAccent : Colors.green)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
            ),
            TextButton(
              onPressed: () {
                setState(() {});
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Text('SAVE', style: TextStyle(color: isDark ? Colors.cyanAccent : Colors.green)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF040608) : const Color(0xFFF7F8FA);
    final cardColor = isDark ? const Color(0xFF0A0D11) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next == AuthState.authenticated) {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: textColor, size: 20),
                  ),
                  GestureDetector(
                    onTap: () {
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'Dismiss',
                        barrierColor: Colors.black.withValues(alpha: 0.6),
                        transitionDuration: const Duration(milliseconds: 250),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return const Align(
                            alignment: Alignment.bottomCenter,
                            child: Material(
                              color: Colors.transparent,
                              child: HelpCenterSheet(),
                            ),
                          );
                        },
                        transitionBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.help_outline, color: textColor, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'AUR',
                            style: GoogleFonts.outfit(
                              color: textColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: isDark
                                  ? [Colors.cyanAccent, Colors.blueAccent]
                                  : [const Color(0xFF00C853), const Color(0xFF009688)],
                            ).createShader(bounds),
                            child: Text(
                              'EXA',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PRODUCTION SETUP',
                        style: GoogleFonts.outfit(
                          color: subtextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'CONNECT\\nCONTROL\\nBELONG',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(
                      color: subtextColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Configure your Firebase project to connect\nAurexa with your devices.',
                style: GoogleFonts.outfit(
                  color: subtextColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.outfit(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // BUTTONS
              GestureDetector(
                onTap: _isLoading ? null : _handleGoogleSignIn,
                child: _buildActionTile(
                  iconBgColor: Colors.white,
                  icon: Center(
                    child: _isLoading 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(
                              strokeWidth: 2, 
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black)
                            )
                          )
                        : Text('G', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  title: _isLoading ? 'Signing in...' : 'Sign in with Google',
                  subtitle: 'Recommended • Sync across devices',
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  showBorder: isDark,
                  shadowColor: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _importJson,
                child: _buildActionTile(
                  iconBgColor: Colors.purpleAccent.withValues(alpha: 0.15),
                  icon: const Icon(Icons.cloud_upload_rounded, color: Colors.purpleAccent, size: 24),
                  title: 'Import Google-Services.json',
                  subtitle: 'Upload your Firebase config file',
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  showBorder: isDark,
                  shadowColor: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _pasteJson,
                  child: Text(
                    'Paste JSON manually',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.greenAccent : const Color(0xFF00C853),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // FIREBASE CONSOLE INFO
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.greenAccent : const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'FIREBASE CONSOLE INFO',
                    style: GoogleFonts.outfit(
                      color: subtextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: isDark ? Border.all(color: borderColor) : null,
                  boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Firebase Console Info', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text('App verification details', style: GoogleFonts.outfit(color: subtextColor, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
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
                    _buildFingerprintRow('Package Name', _packageName, textColor, subtextColor, isDark),
                    const SizedBox(height: 16),
                    _buildFingerprintRow('SHA-1', _sha1, textColor, subtextColor, isDark),
                    const SizedBox(height: 16),
                    _buildFingerprintRow('SHA-256', _sha256, textColor, subtextColor, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // CONFIG TILES
              _buildConfigTile(
                icon: Icons.vpn_key_rounded,
                iconColor: Colors.blueAccent,
                title: 'API Key',
                subtitle: _apiKeyController.text.isEmpty ? 'Add your Web API key' : 'Configured',
                onTap: () => _showEditDialog('API Key', _apiKeyController),
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildConfigTile(
                icon: Icons.folder_rounded,
                iconColor: Colors.amberAccent,
                title: 'Project ID',
                subtitle: _projectIdController.text.isEmpty ? 'Enter your Firebase Project ID' : 'Configured',
                onTap: () => _showEditDialog('Project ID', _projectIdController),
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildConfigTile(
                icon: Icons.info_outline_rounded,
                iconColor: Colors.blueAccent,
                title: 'Need help?',
                subtitle: 'Check our setup guide or watch the video tutorial.',
                onTap: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'Dismiss',
                    barrierColor: Colors.black.withValues(alpha: 0.6),
                    transitionDuration: const Duration(milliseconds: 250),
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const Align(
                        alignment: Alignment.bottomCenter,
                        child: Material(
                          color: Colors.transparent,
                          child: HelpCenterSheet(),
                        ),
                      );
                    },
                    transitionBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                  );
                },
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
              ),
              
              const SizedBox(height: 40),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: subtextColor, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'YOUR DATA STAYS YOURS',
                      style: GoogleFonts.outfit(color: subtextColor, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required Color iconBgColor,
    required Widget icon,
    required String title,
    required String subtitle,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required bool showBorder,
    required Color shadowColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: showBorder ? Border.all(color: borderColor) : null,
        boxShadow: showBorder ? null : [BoxShadow(color: shadowColor, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
            ),
            child: icon,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.outfit(color: subtextColor, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: subtextColor, size: 16),
        ],
      ),
    );
  }

  Widget _buildConfigTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: borderColor) : null,
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.outfit(color: subtextColor, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: subtextColor, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerprintRow(String label, String value, Color textColor, Color subtextColor, bool isDark) {
    final copyColor = isDark ? Colors.cyanAccent : const Color(0xFF00C853);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: GoogleFonts.outfit(color: subtextColor, fontSize: 12)),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.outfit(color: textColor, fontSize: 11, fontWeight: FontWeight.w500)),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied!'), backgroundColor: copyColor));
          },
          child: Icon(Icons.copy, color: copyColor, size: 18),
        ),
      ],
    );
  }
}
