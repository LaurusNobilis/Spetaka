import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../lifecycle/app_lifecycle_service.dart';
import 'encryption_service.dart';

part 'encryption_service_provider.g.dart';

@Riverpod(keepAlive: true)
EncryptionService encryptionService(Ref ref) {
  final service = EncryptionService(
    lifecycleService: ref.watch(appLifecycleServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
}
