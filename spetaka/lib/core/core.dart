// Core barrel — cross-cutting infrastructure and shared domain services.
// Sub-packages added story-by-story. Exports sorted alphabetically.

// Contact actions gateway — Story 1.5.
// ContactActionService is the ONLY url_launcher gateway; widgets must not call it directly.
export 'actions/contact_action_service.dart';
// Phone normalization — Story 1.5.
// PhoneNormalizer is the ONLY phone-number formatting / parsing entrypoint.
export 'actions/phone_normalizer.dart';
// Database — Story 1.2.
// Only AppDatabase is exported; DAOs are internal to the repository layer.
export 'database/app_database.dart';
// Encryption service — Story 1.3.
export 'encryption/encryption_service.dart';
export 'encryption/encryption_service_provider.dart';
// Domain errors — Story 1.3.
export 'errors/app_error.dart';
export 'errors/error_messages.dart';
// App lifecycle observer — Story 1.5.
// Only AppLifecycleService may use WidgetsBindingObserver; subscribe via provider.
export 'lifecycle/app_lifecycle_service.dart';
