---
name: local-real-env-validation
description: Replace Mock services with real local Supabase and LiveKit for deployment-ready validation
status: backlog
created: 2025-09-07T10:06:50Z
---

# PRD: Local Real Environment Validation

## Executive Summary

Transform the local development environment from Mock service-based testing to real Supabase and LiveKit integration. This ensures deployment confidence by validating against actual database schemas, RLS policies, and real-time services before production deployment.

**Value Proposition**: Eliminate deployment surprises by catching integration issues early in local development environment.

## Problem Statement

### Current Pain Points
- **Mock Service Blindness**: Local Mock services pass tests but production fails due to database constraints, RLS policies, or real-time subscription issues
- **Integration Risk**: No validation of Supabase schema, authentication flows, or LiveKit video/audio functionality in local environment  
- **Debugging Gap**: Production issues cannot be reproduced locally due to Mock/real service differences
- **Deployment Uncertainty**: Teams lack confidence that local validation predicts production behavior

### Why Now?
- Production-ready WhatsApp Clone requires reliable deployment pipeline
- Current Mock-based approach has already shown limitations in previous deployment attempts
- Real local validation is prerequisite for confident production releases

## User Stories

### Primary Persona: Flutter Developer
**As a Flutter developer working on the WhatsApp Clone**
- I want to test against real Supabase database locally
- So that I catch RLS policy issues, constraint violations, and schema problems before deployment
- **Acceptance Criteria**: All database operations work identically in local and production environments

**As a developer implementing new features**
- I want LiveKit video/audio calls to work in local environment
- So that I can validate meeting functionality without deploying to production
- **Acceptance Criteria**: Complete audio/video call flow works locally with real LiveKit server

**As a team member reviewing code**
- I want local environment to match production behavior
- So that code reviews can validate actual functionality, not Mock approximations
- **Acceptance Criteria**: Local testing results directly predict production behavior

### User Journey: Feature Development Flow
1. **Development**: Write new messaging feature against real local Supabase
2. **Testing**: Validate RLS policies, real-time subscriptions work locally
3. **Integration**: Test with LiveKit for video message features
4. **Validation**: Confirm end-to-end functionality before deployment
5. **Deployment**: Deploy with confidence knowing local environment validated all integrations

## Requirements

### Functional Requirements

**FR1: Real Supabase Integration**
- Replace Mock database with local Supabase instance
- Implement complete database schema matching production
- Configure RLS policies identical to production environment
- Support real-time subscriptions for messaging and presence

**FR2: LiveKit Real Service**
- Configure local LiveKit server for video/audio testing
- Implement room creation, participant management
- Support audio/video streaming in local environment
- Match production LiveKit configuration and capabilities

**FR3: Flutter App Real Service Connection**
- Remove all Mock service dependencies
- Configure Flutter app to connect to local real services
- Maintain all existing UI functionality with real backend
- Support offline/online state management with real services

**FR4: Data Management**
- Seed local database with realistic test data
- Support easy database reset/refresh for testing
- Maintain data consistency across service restarts
- Provide migration path for schema updates

**FR5: Authentication & Authorization**
- Real Supabase Auth integration in local environment
- Test user registration, login, password reset flows
- Validate RLS policies prevent unauthorized access
- Support multiple test user accounts

### Non-Functional Requirements

**NFR1: Performance**
- Local real environment response times < 2x Mock services
- Database queries execute within reasonable timeframes
- LiveKit video/audio latency suitable for development testing

**NFR2: Reliability**
- Local services maintain 99%+ uptime during development sessions
- Automatic service recovery from Docker container failures
- Data persistence across container restarts

**NFR3: Developer Experience**
- Single command startup: `docker-compose up -d`
- Clear error messages for configuration issues
- Hot reload support maintained with real services
- Comprehensive logging for debugging

**NFR4: Resource Usage**
- Total local environment RAM usage < 4GB
- CPU usage allows concurrent Flutter development
- Disk space requirements clearly documented

## Success Criteria

### Primary Success Metrics
- **Zero Deployment Surprises**: Features validated locally deploy successfully to production without backend integration issues
- **RLS Policy Validation**: All database security policies work identically locally and in production
- **Real-time Feature Parity**: Messaging, presence, and notifications work consistently across environments
- **LiveKit Integration Success**: Video/audio calls function properly in local environment

### Measurable Outcomes
- 100% of database operations that pass locally also pass in production
- Audio/video call success rate >95% in local environment
- Local environment startup time <60 seconds
- Developer onboarding time reduced by eliminating production environment dependencies

### Quality Gates
- All existing Flutter tests pass with real services
- Database schema migrations apply cleanly
- No authentication/authorization bypass in local environment
- Complete feature functionality validation before any production deployment

## Constraints & Assumptions

### Technical Constraints
- Must use Docker for service orchestration
- Supabase version must match production instance
- LiveKit server version compatibility with Flutter SDK
- Local environment must work on macOS development machines

### Resource Constraints
- Development timeline: 7-10 hours total effort
- Single developer implementation
- Existing Docker infrastructure and knowledge

### Assumptions
- Docker Desktop installed and functioning
- Sufficient local machine resources (8GB+ RAM recommended)
- Network connectivity for initial Docker image pulls
- Existing Flutter app architecture supports service switching

## Out of Scope

**Explicitly NOT Included**:
- Production deployment automation (separate concern)
- Load testing or performance benchmarking beyond basic functionality
- Multi-developer environment setup (focus on single developer workflow)
- Migration from existing Mock services (both will coexist initially)
- Advanced monitoring/observability beyond basic logging
- Backup/restore procedures for local data

## Dependencies

### External Dependencies
- Docker Desktop installed and running
- Supabase CLI for database management
- LiveKit server Docker image availability
- Stable internet connection for initial setup

### Internal Dependencies
- Existing Flutter app codebase
- Current docker-compose.local.yml configuration
- Supabase project configuration and credentials
- LiveKit service account and API keys

### Blocking Dependencies
- None identified - all dependencies are currently available

## Risk Assessment

### High Risk
- **Supabase RLS Complexity**: Local RLS policies may behave differently than production
- **LiveKit Configuration**: Complex video/audio configuration may require extensive troubleshooting

### Medium Risk  
- **Docker Resource Usage**: Local environment may consume more resources than Mock setup
- **Data Seeding Complexity**: Creating realistic test data for all features

### Low Risk
- **Flutter Integration**: Existing architecture should support service switching with minimal changes

## Implementation Phases

### Phase 1: Infrastructure (2-3 hours)
- Set up local Supabase with complete database schema
- Configure LiveKit server in Docker environment
- Validate service connectivity and basic functionality

### Phase 2: Application Integration (3-4 hours)
- Remove Mock service dependencies from Flutter app
- Implement real service connections and configuration
- Update dependency injection and service initialization

### Phase 3: Validation & Testing (2-3 hours)
- Comprehensive functionality testing across all features
- Performance validation and resource usage optimization
- Documentation and developer workflow refinement

---

**Next Steps**: Ready to create implementation epic with `/pm:prd-parse local-real-env-validation`