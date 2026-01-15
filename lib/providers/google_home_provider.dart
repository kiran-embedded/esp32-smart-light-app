import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_home_service.dart';

final googleHomeServiceProvider = Provider<GoogleHomeService>((ref) {
  return GoogleHomeService();
});

final googleHomeLinkedProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(googleHomeServiceProvider);
  return service.linkStatusStream();
});
