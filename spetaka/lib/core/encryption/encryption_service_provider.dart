import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'encryption_service.dart';

part 'encryption_service_provider.g.dart';

@Riverpod(keepAlive: true)
EncryptionService encryptionService(Ref ref) {
  final service = EncryptionService(widgetsBinding: WidgetsBinding.instance);
  ref.onDispose(service.dispose);
  return service;
}
