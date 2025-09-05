---
created: 2025-09-05T13:56:24Z
last_updated: 2025-09-05T13:56:24Z
version: 1.0
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
│   └── scripts/                       # Automation scripts
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

## Planned Flutter Project Structure

Once Flutter integration is complete, the structure will expand to:

```
whatsapp-clone/
├── .claude/                           # CCPM System (preserved)
├── android/                           # Android-specific configurations
├── ios/                               # iOS-specific configurations  
├── lib/                               # Flutter application source
│   ├── core/                          # Core utilities and constants
│   │   ├── constants/                 # App-wide constants
│   │   ├── errors/                    # Error handling classes
│   │   ├── utils/                     # Utility functions
│   │   └── providers/                 # Core Riverpod providers
│   ├── features/                      # Feature-based organization
│   │   ├── auth/                      # Authentication feature
│   │   │   ├── data/                  # Data layer (repositories, models)
│   │   │   ├── domain/                # Domain layer (entities, use cases)
│   │   │   └── presentation/          # Presentation layer (UI, controllers)
│   │   ├── chat/                      # Messaging feature
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── meetings/                  # Video/audio meeting feature
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── groups/                    # Group management feature
│   │   └── communities/               # Community/channel feature
│   ├── shared/                        # Shared components and services
│   │   ├── widgets/                   # Reusable UI components
│   │   ├── services/                  # External services integration
│   │   └── repositories/              # Shared repository abstractions
│   └── main.dart                      # Application entry point
├── test/                              # Unit and widget tests
│   ├── features/                      # Feature-specific tests
│   └── helpers/                       # Test utilities
├── integration_test/                  # Integration tests
├── web/                               # Web platform configurations
├── pubspec.yaml                       # Flutter dependencies
└── pubspec.lock                       # Dependency lock file
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

This structure ensures maintainability, testability, and clear separation of concerns while integrating seamlessly with the CCPM workflow for full traceability from requirements to implementation.