import 'package:flutter/material.dart';
import '../common/frosted_glass.dart';

class SetupGuideDialog extends StatelessWidget {
  const SetupGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: FrostedGlass(
        opacity: 0.2,
        blur: 40,
        radius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.2),
          width: 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Colors.cyanAccent),
                  const SizedBox(width: 12),
                  Text(
                    'Setup Guide',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStep(
                      '1',
                      'Create Firebase Project',
                      'Go to Firebase Console and create a new project. Name it "Nebula Home" or whatever you like.',
                    ),
                    _buildStep(
                      '2',
                      'Authentication',
                      'In Firebase Console, go to Build -> Authentication. Enable "Google" as a sign-in provider.',
                    ),
                    _buildStep(
                      '3',
                      'Add Android App',
                      'Add an Android app using your Package Name shown on the setup screen. Generate and add SHA-1/SHA-256 fingerprints.',
                    ),
                    _buildStep(
                      '4',
                      'Download Config',
                      'Download the "google-services.json" file from your project settings.',
                    ),
                    _buildStep(
                      '5',
                      'Import in App',
                      'Click the "IMPORT GOOGLE-SERVICES.JSON" button on the setup screen and select the file you downloaded.',
                    ),
                    _buildStep(
                      '6',
                      'Restart',
                      'Click "INITIALIZE NEBULA" and restart the app. You are now connected!',
                    ),
                    const SizedBox(height: 10),
                    FrostedGlass(
                      padding: const EdgeInsets.all(12),
                      radius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.2),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.cyanAccent,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tip: You can also find the detailed guide (FIREBASE_PRODUCTION_GUIDE.md) in the project folder.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('GOT IT'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.cyanAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
