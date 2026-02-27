// Core barrel — cross-cutting infrastructure and shared domain services.
// Sub-packages added story-by-story.

// Database layer (Story 1.2)
// Only AppDatabase is exported — DAOs are internal to the repository layer
// and must NOT be imported directly by feature code.
export 'database/app_database.dart';
