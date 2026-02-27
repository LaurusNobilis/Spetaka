// Core barrel — cross-cutting infrastructure and shared domain services.
// Sub-packages added story-by-story.

// Database layer (Story 1.2)
// Only AppDatabase is exported — DAOs are internal to the repository layer
// and must NOT be imported directly by feature code.
export 'database/app_database.dart';

// Encryption layer (Story 1.3)
export 'encryption/encryption_service.dart';
export 'encryption/encryption_service_provider.dart';

// Domain errors (Story 1.3)
export 'errors/app_error.dart';
export 'errors/error_messages.dart';
