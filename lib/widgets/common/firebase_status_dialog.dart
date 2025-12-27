import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import '../common/frosted_glass.dart';

class FirebaseStatusDialog extends StatelessWidget {
  const FirebaseStatusDialog({super.key});

  Future<Map<String, String>> _checkFirebaseStatus() async {
    final status = <String, String>{};

    // Check Firebase initialization
    try {
      if (Firebase.apps.isEmpty) {
        status['Firebase Init'] = '❌ Not initialized';
      } else {
        status['Firebase Init'] = '✅ Initialized';
        status['Firebase App'] = Firebase.app().name;
      }
    } catch (e) {
      status['Firebase Init'] = '❌ Error: $e';
    }

    // Check Authentication
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      status['Auth Status'] = user != null ? '✅ Signed in' : '❌ Not signed in';
      if (user != null) {
        status['User Email'] = user.email ?? 'No email';
      }
    } catch (e) {
      status['Auth Status'] = '❌ Error: $e';
    }

    // Check Google Sign-In
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signInSilently();
      status['Google Sign-In'] = account != null
          ? '✅ Available'
          : '⚠️ Not signed in';
    } catch (e) {
      status['Google Sign-In'] = '❌ Error: $e';
    }

    // Get App Fingerprints
    try {
      const channel = MethodChannel('com.nebula.core/fingerprints');
      final Map<dynamic, dynamic> fingerprints = await channel.invokeMethod(
        'getFingerprints',
      );
      status['SHA-1'] = fingerprints['sha1'] ?? 'Not Available';
      status['SHA-256'] = fingerprints['sha256'] ?? 'Not Available';
    } catch (e) {
      status['Fingerprints'] = '❌ Error: $e';
    }

    return status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FrostedGlass(
        padding: const EdgeInsets.all(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.2,
        ),
        child: FutureBuilder<Map<String, String>>(
          future: _checkFirebaseStatus(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking Firebase status...'),
                ],
              );
            }

            final status = snapshot.data!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Firebase Status', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 20),
                ...status.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            entry.key,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Troubleshooting:', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '1. Check Firebase Console → Authentication → Enable Google\n'
                  '2. Add SHA-1 fingerprint in Firebase Console\n'
                  '3. Verify google-services.json is in android/app/\n'
                  '4. Rebuild app after adding SHA-1',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
