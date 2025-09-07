---
created: 2025-09-05T13:56:24Z
last_updated: 2025-09-07T12:33:09Z
version: 2.3
author: Claude Code PM System
---

# Project Structure

## Current Directory Structure

```
whatsapp-clone/
├── .claude/                           # CCPM System Files
│   ├── agents/                        # Sub-agent configurations
│   ├── commands/                      # PM command definitions
│   ├── context/                       # Project context documentation
│   ├── epics/                         # Epic decomposition files
│   │   ├── archived/                  # Completed epics archive
│   │   │   ├── production-ready-2025-09-07/  # Production readiness epic (completed)
│   │   │   └── tdd-refactor-2025-09-07/      # TDD refactor epic (completed)
│   │   └── local-real-env-validation/ # Current local real environment epic ✅ COMPLETE
│   │       ├── epic.md                # Epic overview and GitHub Issue #26
│   │       ├── 27.md → 34.md          # Tasks 27-34: Real environment implementation
│   │       ├── execution-status.md    # Epic execution tracking
│   │       ├── github-mapping.md      # GitHub issue mappings
│   │       └── updates/               # Task progress updates
│   ├── prds/                          # Product Requirements Documents
│   │   ├── local-real-env-validation.md  # Local environment validation PRD ✅
│   │   └── production-ready.md        # Production readiness PRD ✅
│   ├── rules/                         # CCMP workflow rules
│   ├── scripts/                       # Automation scripts
│   └── tracking/                      # Project monitoring & health reports ✅
├── install/                           # CCPM installation utilities
├── .gitignore                         # Git ignore patterns
├── docker-compose.local.yml          # 🆕 Local development Docker stack (Supabase + LiveKit)
├── docker-compose.livekit.yml        # 🆕 Standalone LiveKit configuration
├── .env.local                         # 🆕 Local environment configuration
├── LOCAL_DEV_README.md               # 🆕 Local development setup guide
├── LOCAL_REAL_ENV_VALIDATION_PRD.md  # 🆕 Local environment validation PRD
├── VERIFICATION_GUIDE.md             # 🆕 Step-by-step verification guide
├── AGENTS.md                          # Sub-agent documentation
├── CLAUDE.md                          # Project development rules
├── COMMANDS.md                        # CCPM command reference
├── LICENSE                            # MIT License
├── Notes.md                           # Development notes
├── README.md                          # CCPM system documentation
├── WHATSAPP_CLONE_DEVELOPMENT_GUIDE.md # Complete implementation guide
└── screenshot.webp                    # CCPM workflow illustration
```

## Current Flutter Project Structure

The Flutter project has been fully implemented with Clean Architecture:

```
whatsapp-clone/
├── .claude/                           # CCPM System
│   ├── epics/whatsapp-clone/          # Epic decomposition and progress tracking
│   ├── context/                       # Updated project context documentation
│   └── tracking/                      # Project health reports and monitoring ✅
├── android/                           # Android-specific configurations ✅
├── ios/                               # iOS-specific configurations ✅
├── lib/                               # Flutter application source ✅
│   ├── main_local.dart               # 🆕 Local development app entry point
│   ├── main_dev.dart                 # 🆕 Development environment entry point
│   ├── app/                           # Application-level components ✅
│   │   ├── pages/                     # App shell pages (splash, home, settings)
│   │   ├── router/                    # GoRouter configuration
│   │   └── theme/                     # App theming and styling
│   ├── core/                          # Core utilities and constants ✅
│   │   ├── config/                    # 🆕 Environment configuration
│   │   │   └── environment_config.dart  # Service mode switching
│   │   ├── constants/                 # App constants (Supabase URLs, etc.)
│   │   ├── errors/                    # Error handling (failures, exceptions)
│   │   ├── utils/                     # Result wrapper and utilities
│   │   ├── providers/                 # 🆕 Enhanced service providers
│   │   │   ├── service_factory.dart    # Service creation and validation
│   │   │   └── service_providers.dart  # Riverpod service providers
│   │   └── services/                  # 🆕 Real service implementations
│   │       ├── real_supabase_auth_service.dart    # Real Supabase Auth adapter
│   │       ├── real_supabase_message_service.dart # Real messaging service
│   │       ├── real_livekit_meeting_service.dart  # Real LiveKit adapter
│   │       ├── mock_services.dart                 # Mock service implementations
│   │       ├── service_manager.dart               # Service lifecycle management
│   │       └── livekit_token_service.dart         # LiveKit JWT token generation
│   ├── features/                      # Feature-based organization ✅
│   │   ├── auth/                      # Authentication feature ✅ COMPLETE
│   │   │   ├── data/                  # Auth repository, models, sources
│   │   │   ├── domain/                # User/session entities, use cases
│   │   │   └── presentation/          # Login/register pages, providers
│   │   ├── chat/                      # Messaging feature ✅ COMPLETE
│   │   │   ├── data/                  # Message models, chat repository
│   │   │   ├── domain/                # Message/room entities, use cases
│   │   │   └── presentation/          # Chat UI, message bubbles, providers
│   │   ├── file_storage/              # File sharing feature ✅ COMPLETE
│   │   │   ├── data/                  # File models, storage repository
│   │   │   ├── domain/                # File entities, upload/download use cases
│   │   │   └── presentation/          # File picker, preview widgets
│   │   ├── meetings/                  # LiveKit video meetings ✅ COMPLETE
│   │   │   ├── data/                  # Meeting models, LiveKit integration
│   │   │   ├── domain/                # Meeting entities, join/leave use cases
│   │   │   └── presentation/          # Meeting UI, participant grid
│   │   └── community/                 # Community channels ✅ COMPLETE
│   │       ├── data/                  # Community models, permissions
│   │       ├── domain/                # Channel/role entities, moderation
│   │       └── presentation/          # Community dashboard, admin tools
│   └── main.dart                      # Application entry point ✅
├── test/                              # Unit and widget tests ✅
│   └── features/                      # Comprehensive test coverage
│       ├── auth/                      # Auth entity and use case tests
│       ├── chat/                      # Message entity and use case tests
│       └── file_storage/              # File entity and use case tests
├── scripts/                           # 🆕 Automation and validation scripts
│   ├── validate-real-env.sh          # Environment validation script
│   ├── reset-test-data.sh            # Test data management
│   ├── generate-test-data.py         # Advanced test data generation
│   ├── start-local-dev.sh            # Local development startup
│   └── verify-local-env.sh           # Service verification
├── supabase/                          # Supabase configuration ✅
│   ├── config.toml                   # 🆕 Supabase project configuration
│   ├── seed.sql                      # 🆕 Realistic test data seeding
│   ├── functions/                     # Edge Functions (LiveKit tokens)
│   └── migrations/                    # 🆕 Production-identical database schema
│       ├── 20250907000001_create_user_profiles.sql
│       ├── 20250907000002_create_messaging_tables.sql
│       ├── 20250907000003_create_messaging_rls_policies.sql
│       ├── 20250907000004_create_helper_functions.sql
│       ├── 20250907000005_create_meeting_tables.sql
│       └── 20250907000006_create_meeting_rls_policies.sql
├── volumes/                           # 🆕 Docker volume configurations
│   ├── api/kong.yml                  # Kong API Gateway config
│   ├── db/                           # Database initialization scripts
│   ├── functions/                    # Function configurations
│   ├── livekit/                      # LiveKit server config
│   └── logs/                         # Logging configurations
├── web/                               # Web platform support ✅
├── pubspec.yaml                       # Dependencies with LiveKit, Riverpod ✅
└── pubspec.lock                       # Locked dependencies ✅
```

## Key Directory Patterns

### CCPM Organization
- **`.claude/prds/`**: Product Requirements Documents with YAML frontmatter
- **`.claude/epics/`**: Technical implementation plans decomposed from PRDs
- **`.claude/context/`**: Living project documentation for context preservation
- **`.claude/scripts/pm/`**: Automation scripts for project management workflows

### Flutter Clean Architecture
- **`lib/core/`**: Cross-cutting concerns, shared utilities, app-wide providers
- **`lib/features/{feature}/`**: Feature modules with clear layer separation
- **`lib/shared/`**: Reusable components that don't belong to specific features

### Layer Separation Pattern
Each feature follows Clean Architecture:
```
feature/
├── data/           # External concerns (API, database, cache)
│   ├── models/     # Data transfer objects
│   ├── repositories/ # Repository implementations
│   └── sources/    # Data sources (local, remote)
├── domain/         # Business logic layer
│   ├── entities/   # Business objects
│   ├── repositories/ # Repository abstractions
│   └── usecases/   # Business use cases
└── presentation/   # UI layer
    ├── controllers/ # Riverpod controllers/notifiers
    ├── pages/      # Screen widgets
    └── widgets/    # Feature-specific UI components
```

## File Naming Conventions

### Dart Files
- **Snake case**: `user_profile.dart`, `chat_message.dart`
- **Feature prefix**: `auth_repository.dart`, `meeting_service.dart`
- **Layer suffix**: `_controller.dart`, `_provider.dart`, `_page.dart`

### Test Files
- **Mirror structure**: `test/features/auth/auth_repository_test.dart`
- **Test suffix**: `_test.dart` for unit tests
- **Integration prefix**: `integration_test/app_test.dart`

### CCPM Files
- **Kebab case**: `whatsapp-clone.md`, `meeting-system.md`
- **Descriptive names**: Include feature scope in filename
- **Versioning**: Handled through git and frontmatter metadata

## Module Organization Strategy

### By Feature (Primary)
Features are self-contained modules with all three layers:
- `auth/` - User authentication and authorization
- `chat/` - 1-on-1 and group messaging  
- `meetings/` - Video/audio conferencing with LiveKit
- `groups/` - Group management and administration
- `communities/` - Community channels and broadcasting

### By Layer (Secondary)
Within each feature, organize by architectural layer:
- `data/` - External integrations (Supabase, LiveKit)
- `domain/` - Pure business logic, testable in isolation
- `presentation/` - Flutter UI and Riverpod state management

### Shared Components (Tertiary)
Cross-cutting concerns that support multiple features:
- `core/` - App initialization, constants, utilities
- `shared/` - Reusable UI components, common services

## Integration Points

### External Services
- **Supabase Integration**: Centralized in `lib/core/services/supabase_service.dart`
- **LiveKit Integration**: Isolated in `lib/features/meetings/data/sources/`
- **Storage Integration**: Abstracted through repository pattern

### State Management
- **Riverpod Providers**: Co-located with feature modules
- **Global State**: Managed in `lib/core/providers/`
- **Local State**: Component-level using Flutter's built-in state

## Development Workflow Integration

### CCPM Integration
- PRD changes trigger epic updates
- Epic decomposition creates GitHub issues  
- Issues link to specific feature modules
- Code changes traced back to original requirements

### Testing Integration  
- Unit tests mirror source structure
- Integration tests cover complete user flows
- Test-runner sub-agent manages execution and reporting

### CI/CD Integration
- Lint and format checks on every commit
- Automated testing on pull requests
- Deploy pipeline triggered by main branch updates

## Implementation Status

### ✅ Completed Features (100%)
- **Authentication System**: JWT + OTP with Supabase Auth
- **Real-time Messaging**: WebSocket chat with typing indicators
- **File Storage**: Multi-bucket system with compression  
- **Video Meetings**: LiveKit integration for 50-100 participants
- **Community Management**: Hierarchical channels with role permissions
- **Mobile UI**: Complete responsive interface with theming

### ⏳ Next Phase Features
- **Advanced Meeting Features**: Breakout rooms, recording, whiteboard
- **Infrastructure**: Kubernetes deployment with monitoring
- **Testing & QA**: Comprehensive test automation
- **Performance Optimization**: Load testing and optimization

This structure has proven effective for rapid parallel development while maintaining Clean Architecture principles and comprehensive test coverage. The CCPM methodology successfully coordinated 6 concurrent agents working across different feature modules.

## Update History
- 2025-09-05T23:20:00Z: Updated to reflect complete Flutter project implementation with all core features developed. Changed from "planned" to "current" structure with completion status.
- 2025-09-06T12:49:11Z: Added `.claude/tracking/` directory containing project health monitoring infrastructure: project_health_report.md, performance_trends.md, next_iteration_plan.md, and tracking_summary.md for comprehensive project monitoring.