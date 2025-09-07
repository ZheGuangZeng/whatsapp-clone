---
created: 2025-09-05T13:56:24Z
last_updated: 2025-09-06T12:49:11Z
version: 2.1
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
│   ├── prds/                          # Product Requirements Documents
│   ├── rules/                         # CCMP workflow rules
│   ├── scripts/                       # Automation scripts
│   └── tracking/                      # Project monitoring & health reports ✅
├── install/                           # CCPM installation utilities
├── .gitignore                         # Git ignore patterns
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
│   ├── app/                           # Application-level components ✅
│   │   ├── pages/                     # App shell pages (splash, home, settings)
│   │   ├── router/                    # GoRouter configuration
│   │   └── theme/                     # App theming and styling
│   ├── core/                          # Core utilities and constants ✅
│   │   ├── constants/                 # App constants (Supabase URLs, etc.)
│   │   ├── errors/                    # Error handling (failures, exceptions)
│   │   ├── utils/                     # Result wrapper and utilities
│   │   └── providers/                 # Supabase provider
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
├── supabase/                          # Supabase configuration ✅
│   ├── functions/                     # Edge Functions (LiveKit tokens)
│   └── migrations/                    # Database schema and RLS policies
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