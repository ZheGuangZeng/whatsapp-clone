---
name: local-real-env-validation
status: backlog
created: 2025-09-07T10:10:25Z
updated: 2025-09-07T10:16:23Zprogress: 0%
prd: .claude/prds/local-real-env-validation.md
github: https://github.com/ZheGuangZeng/whatsapp-clone/issues/26
---

# Epic: Local Real Environment Validation

## Overview

Replace Mock services with real local Supabase and LiveKit integration to achieve deployment-ready validation. This technical implementation leverages existing Docker infrastructure while introducing real service connections that mirror production environment behavior.

**Core Strategy**: Parallel service approach - maintain existing Mock services while introducing real service variants, allowing gradual transition and fallback capabilities.

## Architecture Decisions

**Service Architecture**: Dual-mode local environment
- Keep existing Mock services for rapid development
- Add real Supabase + LiveKit services for pre-deployment validation
- Use environment switching to toggle between Mock/real services

**Database Strategy**: Local Supabase with production parity
- Use official Supabase Docker stack for local development
- Implement identical schema, RLS policies, and triggers
- Seed with realistic test data matching production patterns

**Flutter Integration Pattern**: Service abstraction layer
- Leverage existing service interfaces in Flutter app
- Implement real service adapters alongside Mock implementations
- Use dependency injection to switch between service types

## Technical Approach

### Infrastructure Components
**Docker Service Stack**:
- Supabase: PostgreSQL + Auth + Realtime + API Gateway
- LiveKit: Standalone server for video/audio streaming
- Networking: Shared Docker network for service communication

**Configuration Management**:
- Environment-specific Docker Compose files
- Centralized .env configuration for service endpoints
- Health check endpoints for service validation

### Frontend Integration
**Service Layer Refactoring**:
- Extract service interfaces from existing Mock implementations
- Create real service adapters implementing same interfaces
- Update dependency injection to support service switching

**State Management**:
- Maintain existing Riverpod providers
- Add real service providers alongside Mock providers
- Environment-based provider selection logic

### Backend Services
**Supabase Integration**:
- Complete database schema with all tables, indexes, RLS policies
- Realtime subscription setup for messaging and presence
- Authentication service configuration matching production

**LiveKit Integration**:
- Room management API integration
- Participant handling and permissions
- Audio/video stream configuration

## Implementation Strategy

**Risk Mitigation**:
- Implement real services alongside existing Mock services (no replacement initially)
- Validate each service independently before Flutter integration
- Maintain rollback capability to Mock services if issues arise

**Development Phases**:
1. **Infrastructure Setup**: Docker services running and validated
2. **Service Integration**: Flutter app connecting to real services
3. **Validation Testing**: End-to-end functionality verification

**Testing Approach**:
- Unit tests for new service adapters
- Integration tests with real services
- Comparison testing between Mock and real service behavior

## Task Breakdown Preview

High-level task categories (≤10 tasks total):

- [ ] **Infrastructure Setup**: Configure Docker Compose with Supabase + LiveKit services
- [ ] **Database Schema**: Create production-identical database schema and RLS policies
- [ ] **Service Adapters**: Implement real Supabase and LiveKit service adapters
- [ ] **Flutter Integration**: Connect Flutter app to real services with environment switching
- [ ] **Authentication Flow**: Implement real Supabase Auth integration
- [ ] **Messaging System**: Real-time messaging with Supabase Realtime
- [ ] **Meeting Functionality**: LiveKit video/audio integration
- [ ] **Data Seeding**: Create realistic test data for all features
- [ ] **Validation Testing**: End-to-end functionality verification
- [ ] **Documentation**: Update developer workflow and troubleshooting guides

## Dependencies

**External Dependencies**:
- Docker Desktop (already installed)
- Supabase CLI (already installed)
- LiveKit Docker images (publicly available)
- Flutter SDK and existing app architecture

**Internal Dependencies**:
- Current docker-compose.local.yml as foundation
- Existing Flutter service interfaces and Mock implementations
- Supabase project configuration and API keys
- LiveKit service configuration

**Critical Path Dependencies**:
- Docker service health validation must complete before Flutter integration
- Database schema must be validated before real service adapter implementation
- Service adapters must be tested before production environment comparison

## Success Criteria (Technical)

**Performance Benchmarks**:
- Local Supabase response time <500ms for database queries
- LiveKit room creation and joining <2 seconds
- Flutter app startup with real services <5 seconds
- Real-time message delivery latency <100ms

**Quality Gates**:
- All existing Flutter tests pass with real services
- Zero authentication bypass vulnerabilities in local environment
- Database migrations apply cleanly without manual intervention
- Video/audio calls establish successfully >95% of attempts

**Acceptance Criteria**:
- Complete feature parity between local real environment and Mock environment
- All messaging, authentication, and meeting features function identically
- Developer can switch between Mock/real services with single configuration change

## Estimated Effort

**Overall Timeline**: 7-10 hours
- Infrastructure Setup: 2-3 hours
- Service Integration: 3-4 hours  
- Validation & Testing: 2-3 hours

**Resource Requirements**:
- Single developer implementation
- 4GB+ RAM for local Docker services
- Stable internet for initial Docker image pulls

**Critical Path Items**:
1. Supabase Docker stack configuration and health validation
2. Flutter service adapter implementation and testing
3. End-to-end functionality validation with real services

---

## Tasks Created
- [ ] #27 - Configure Docker Infrastructure for Real Services (parallel: false)
- [ ] #28 - Create Production-Identical Database Schema (parallel: false)
- [ ] #29 - Implement Real Service Adapters (parallel: false)
- [ ] #30 - Implement Environment-Based Service Switching (parallel: false)
- [ ] #31 - Integrate Real Authentication Flow (parallel: true)
- [ ] #32 - Implement Real-Time Messaging System (parallel: true)
- [ ] #33 - Integrate LiveKit Video/Audio Meetings (parallel: true)
- [ ] #34 - Create Comprehensive Test Data and Validation (parallel: false)

Total tasks: 8
Parallel tasks: 3
Sequential tasks: 5
