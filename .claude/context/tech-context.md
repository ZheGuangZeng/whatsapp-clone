---
created: 2025-09-05T13:56:24Z
last_updated: 2025-09-05T13:56:24Z
version: 1.0
author: Claude Code PM System
---

# Technology Context

## Primary Technology Stack

### Frontend Framework
- **Flutter**: Cross-platform mobile development
  - **Target Platforms**: iOS, Android (Web optional for later)
  - **Language**: Dart
  - **Architecture**: Clean Architecture with feature-based module organization
  - **Minimum Flutter Version**: 3.16+ (latest stable)

### Backend Services
- **Supabase**: Backend-as-a-Service platform
  - **Database**: PostgreSQL with real-time subscriptions
  - **Authentication**: Built-in user management with RLS (Row Level Security)
  - **Storage**: File and media storage with CDN
  - **Real-time**: WebSocket-based real-time data synchronization
  - **Edge Functions**: Serverless functions for custom business logic

### State Management
- **Riverpod**: Chosen over Bloc for modern, reactive state management
  - **Version**: 2.4.9+ (flutter_riverpod)
  - **Code Generation**: riverpod_generator for boilerplate reduction
  - **Benefits**: Better testability, compile-time safety, reduced boilerplate

### Real-time Communication
- **LiveKit**: WebRTC infrastructure for video/audio meetings
  - **Client SDK**: livekit_client for Flutter
  - **Scale**: Supports 50-100 person meetings (core requirement)
  - **Features**: Screen sharing, recording, breakout rooms
  - **Deployment**: Self-hosted or cloud-hosted LiveKit server

### Database & Storage
- **PostgreSQL**: Primary database (via Supabase)
  - **Real-time Features**: Built-in change data capture
  - **Schema**: Row Level Security for multi-tenant data isolation
  - **Extensions**: Full-text search, JSON operations, spatial data support

- **File Storage**: Supabase Storage
  - **Media Types**: Images, documents, audio recordings, video files
  - **CDN**: Global content delivery for media files
  - **Limits**: 100MB per file (configurable)

## Development Tools & Dependencies

### Core Flutter Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Backend Integration
  supabase_flutter: ^2.0.2
  
  # Real-time Communication
  livekit_client: ^1.6.4
  
  # UI Framework
  flutter_chat_ui: ^1.6.9
  flutter_supabase_chat_core: ^0.1.2
  
  # Navigation
  go_router: ^12.1.3
  
  # Media Handling
  image_picker: ^1.0.4
  file_picker: ^6.1.1
  
  # Permissions
  permission_handler: ^11.0.1
  
  # Utilities
  equatable: ^2.0.5
  json_annotation: ^4.8.1
```

### Development Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  
  # Testing
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter
  
  # Linting
  flutter_lints: ^3.0.0
  
  # Analysis
  dart_code_metrics: ^5.7.6
```

### Build Tools
- **Flutter SDK**: 3.16+ with Dart 3.2+
- **Build Runner**: For code generation (Riverpod, JSON serialization)
- **Gradle**: Android build system (Android 7.0+ API 24)
- **Xcode**: iOS build system (iOS 12.0+)

### Development Environment

#### Local Development
- **OS Support**: macOS, Linux, Windows
- **IDE**: VS Code with Flutter/Dart extensions
- **Supabase CLI**: Local development server and database management
- **Flutter Doctor**: Environment validation

#### Version Control
- **Git**: Source code management
- **GitHub**: Repository hosting and issue tracking
- **GitHub CLI**: CCMP integration for issue management
- **Branch Strategy**: Feature branches with main branch protection

#### Testing Framework
- **Unit Tests**: flutter_test + mocktail for mocking
- **Widget Tests**: Flutter widget testing framework  
- **Integration Tests**: integration_test package
- **Test Runner**: Custom sub-agent for test execution and analysis

## External Service Integration

### Supabase Configuration
```
Environment Tiers:
├── Local Development
│   ├── supabase start (Docker-based local stack)
│   ├── Local PostgreSQL instance
│   └── Local file storage
├── Cloud Staging
│   ├── Supabase cloud instance
│   ├── Managed PostgreSQL
│   └── Global CDN storage
└── Self-hosted Production
    ├── Custom Supabase deployment
    ├── Dedicated PostgreSQL cluster
    └── Regional CDN optimization
```

### LiveKit Infrastructure
```
Deployment Options:
├── Cloud Option: LiveKit Cloud
│   ├── Managed infrastructure
│   ├── Global edge locations
│   └── SLA guarantees
└── Self-hosted Option: LiveKit Server
    ├── Docker deployment
    ├── Kubernetes orchestration
    └── Custom scaling policies
```

### Infrastructure Considerations

#### Geographic Distribution
- **Primary Regions**: Japan, Singapore (Asia-Pacific)
- **CDN**: Global distribution with Asia-Pacific optimization
- **Latency Requirements**: <150ms for real-time features
- **Compliance**: Data residency outside China mainland

#### Scalability Targets
- **Users**: 10,000+ concurrent users (Year 1 target)
- **Meetings**: 100+ concurrent large meetings (50-100 participants each)
- **Messages**: 1M+ messages per day at scale
- **Storage**: 10TB+ multimedia content storage

#### Performance Requirements
- **App Startup**: <3 seconds cold start
- **Message Delivery**: <500ms end-to-end latency
- **Meeting Join**: <5 seconds from tap to video
- **File Upload**: Progressive upload with background processing

## Development Methodology

### Code Quality Tools
- **Linting**: flutter_lints with custom rules
- **Formatting**: dart format with 100-character line limit
- **Analysis**: Static analysis with custom metrics
- **Coverage**: 80%+ test coverage requirement

### CI/CD Pipeline
```
Pipeline Stages:
├── Code Quality
│   ├── Lint checking
│   ├── Format validation
│   └── Static analysis
├── Testing
│   ├── Unit test execution
│   ├── Widget test execution
│   ├── Integration test execution
│   └── Coverage reporting
├── Building
│   ├── Android APK/AAB build
│   ├── iOS IPA build
│   └── Web build (optional)
└── Deployment
    ├── Staging environment
    ├── Production deployment
    └── Rollback capability
```

### Testing Strategy
- **TDD Approach**: Tests written before implementation
- **Test Pyramid**: 70% unit, 20% integration, 10% E2E
- **Mock Strategy**: External services mocked, business logic tested in isolation
- **Performance Testing**: Load testing for meeting scenarios

## Architecture Decisions

### Why Riverpod over Bloc?
1. **Modern Syntax**: Less boilerplate, more intuitive API
2. **Compile-time Safety**: Better error catching at build time
3. **Testing**: Easier to test with provider overrides
4. **Performance**: More efficient rebuilds with fine-grained reactivity

### Why Supabase over Firebase?
1. **Real-time**: PostgreSQL-based real-time is more reliable
2. **SQL**: Full SQL capabilities vs NoSQL limitations
3. **Self-hosting**: Option to migrate to self-hosted infrastructure
4. **Cost**: More predictable pricing model

### Why LiveKit over Agora/Twilio?
1. **Open Source**: Can self-host for better control
2. **WebRTC**: Direct peer-to-peer when possible
3. **Scalability**: Designed for large meetings (50-100+ participants)
4. **Features**: Built-in screen sharing, recording, breakout rooms

## Security Considerations

### Authentication & Authorization
- **Supabase Auth**: JWT-based authentication with refresh tokens
- **Row Level Security**: Database-level authorization policies
- **API Security**: All endpoints protected with proper authentication

### Data Protection
- **Transport Security**: TLS 1.3 for all communications
- **Storage Encryption**: Encrypted at rest and in transit
- **Meeting Privacy**: Meeting rooms with access controls

### Compliance
- **GDPR**: User data handling and privacy controls
- **Data Residency**: Non-China servers for Chinese users
- **Content Moderation**: Basic content filtering and reporting

This technology context provides the foundation for all technical decisions and implementation strategies throughout the project lifecycle.