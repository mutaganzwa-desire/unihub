# UniHub – Technical Report

**Version:** 1.0  
**Application:** UniHub – Internship Management Platform  
**Technology Stack:** Flutter, Dart, Firebase  
**Architecture:** Clean Architecture (Feature-First)  
**Backend:** Firebase Authentication, Cloud Firestore, Firebase Storage, Firebase Cloud Messaging (FCM)

---

# Executive Summary

UniHub is a cross-platform mobile application developed using Flutter and Firebase to bridge the gap between university students seeking internship opportunities and startups or organizations looking for interns. The platform provides a secure, scalable, and user-friendly environment where students can discover internships, submit applications, and communicate directly with recruiters, while startups can manage internship postings, review applications, and track recruitment activities.

The application follows a feature-first Clean Architecture with Riverpod for dependency injection and state management. Firebase services provide authentication, real-time database capabilities, cloud storage, notifications, and backend infrastructure.

Following development and comprehensive testing, the application successfully meets its functional requirements and demonstrates stable performance across all major workflows.

---

# Project Overview

## Purpose

UniHub was developed to simplify internship recruitment by providing a centralized digital platform that connects students with startups.

The system eliminates manual application processes by supporting:

- Internship discovery
- Internship applications
- Resume submission
- Recruiter communication
- Application tracking
- Startup verification
- Real-time notifications

---

## Target Users

### Students

Students can:

- Create an account
- Complete their profile
- Upload resumes
- Browse internship opportunities
- Search internships
- Bookmark opportunities
- Apply for internships
- Track application progress
- Receive notifications
- Chat with recruiters

---

### Startups

Startups can:

- Register their organization
- Complete company profiles
- Submit verification documents
- Create internship postings
- Edit internship listings
- Pause or close internships
- Review applications
- Shortlist candidates
- Accept or reject applicants
- Communicate with students
- View recruitment analytics

---

### Administrator

The administrative module supports:

- Startup verification
- Approval workflow
- Verification status management

---

# Technology Stack

| Layer | Technology |
|---------|------------|
| Frontend | Flutter |
| Programming Language | Dart |
| State Management | Riverpod |
| Architecture | Clean Architecture |
| Backend | Firebase |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| File Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging |
| Local Notifications | Flutter Local Notifications |
| Charts | fl_chart |

---

# System Architecture

UniHub follows a Feature-First Clean Architecture that separates responsibilities into three primary layers.

```
Presentation Layer
│
├── Screens
├── Widgets
├── Providers
└── Controllers

↓

Domain Layer

├── Entities
├── Repository Interfaces
└── Business Logic

↓

Data Layer

├── Firebase Repositories
├── Models
├── Services
└── Remote Data Sources
```

This architecture promotes:

- Maintainability
- Scalability
- Testability
- Loose coupling
- Code reuse

---

# Project Structure

The project consists of approximately **98 Dart source files** organized by feature.

Typical structure:

```
lib/

├── core/
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── profiles/
│   ├── internships/
│   ├── applications/
│   ├── chat/
│   ├── notifications/
│   ├── analytics/
│   └── admin/
│
├── shared/
├── services/
├── repositories/
├── widgets/
├── theme/
└── main.dart
```

Supporting files include:

- Firebase Rules
- Firestore Indexes
- Architecture Documentation
- Navigation Diagrams
- Authentication Flow Diagrams
- README
- Technical Documentation

---

# Firebase Integration

## Firebase Authentication

Implemented features include:

- Email/password registration
- Secure login
- Email verification
- Forgot password
- Session persistence
- Logout
- Role-based authentication

---

## Cloud Firestore

Firestore stores:

- Users
- Student profiles
- Startup profiles
- Internship opportunities
- Applications
- Messages
- Notifications
- Verification requests

Offline persistence is enabled to improve reliability.

---

## Firebase Storage

Storage manages:

- Profile photos
- Company logos
- Student resumes
- Verification documents
- Chat attachments

---

## Firebase Cloud Messaging

Push notifications are generated for:

- Internship applications
- Application status changes
- New chat messages
- Verification updates

Local notifications are used as a fallback mechanism when necessary.

---

# Functional Modules

## Authentication

Features include:

- Registration
- Login
- Email verification
- Password reset
- Remember Me
- Session persistence
- Role-based routing

---

## Onboarding

Three introductory screens are displayed only during the user's first launch using a persistent local flag.

---

## Student Profile

Students can:

- Upload profile picture
- Upload resume (PDF)
- Add skills
- Add portfolio links
- Track profile completion

---

## Startup Profile

Organizations can manage:

- Logo
- Company description
- Mission
- Vision
- Funding stage
- Verification documents

---

## Verification Workflow

Startups submit verification documents.

Verification states include:

- Pending
- Verified
- Rejected

Only verified startups are allowed to publish internship opportunities.

---

## Internship Management

Recruiters can:

- Create internships
- Edit internships
- Duplicate listings
- Pause listings
- Close listings
- Delete listings

Students can:

- Browse internships
- Search opportunities
- Filter by category
- Filter by work mode
- Filter paid internships
- Sort listings
- Load additional results using infinite scrolling

---

## Applications

Students can:

- Apply
- Upload resume
- Write cover letter
- Save drafts
- Withdraw applications

Recruiters can:

- View applications
- Shortlist candidates
- Accept candidates
- Reject candidates
- Archive applications

Each student is limited to one application per internship using deterministic document IDs.

---

## Messaging

Real-time chat supports:

- Text messages
- Image sharing
- File sharing
- Typing indicators
- Read receipts

---

## Notifications

Notifications are generated automatically when:

- Applications are submitted
- Application status changes
- Messages arrive
- Verification status changes

---

## Dashboards

### Student Dashboard

Provides:

- Recommended internships
- Recent opportunities
- Bookmarks
- Notifications

Recommendations are generated using an explainable recommendation engine.

---

### Startup Dashboard

Includes analytics such as:

- Internship views
- Applications received
- Conversion rates
- Seven-day trends
- Application status distribution

Visualization is implemented using **fl_chart**.

---

# Design Principles

The project applies:

- Repository Pattern
- Dependency Injection
- Clean Architecture
- Feature-First Organization
- Offline-First Firestore
- Shared Components
- Reusable Widgets
- Centralized Theme Management

---

# Error Handling

A custom **Result/Failure** model abstracts Firebase exceptions from the presentation layer.

Benefits include:

- Consistent error reporting
- Cleaner UI code
- Better separation of concerns
- Easier debugging

---

# Testing and Validation

The completed application underwent functional testing across all major modules.

Verified functionality includes:

- User registration
- Login
- Email verification
- Logout
- Session persistence
- Student profile management
- Startup profile management
- Verification workflow
- Internship creation
- Internship editing
- Internship search
- Internship browsing
- Filtering
- Pagination
- Bookmarking
- Application submission
- Resume upload
- Application status updates
- Messaging
- Notifications
- Dashboard analytics
- Recommendation engine

Testing confirmed that all core workflows operate correctly and the application performs as expected.

---

# Performance Considerations

Performance optimizations include:

- Infinite scrolling
- Pagination
- Offline Firestore caching
- Lazy loading
- Modular architecture
- Reusable widgets
- Riverpod state management
- Atomic Firestore operations

---

# Security

Security is enforced through:

- Firebase Authentication
- Firestore Security Rules
- Role-based authorization
- Startup verification
- Secure Storage integration
- Protected routing

---

# Project Strengths

- Modular architecture
- Highly scalable design
- Secure authentication
- Offline support
- Real-time synchronization
- Responsive UI
- Role-based access control
- Reusable components
- Maintainable codebase
- Comprehensive Firebase integration

---

# Future Improvements

Potential future enhancements include:

- Unit testing
- Widget testing
- Integration testing
- CI/CD pipelines
- Firebase Crashlytics
- Firebase Performance Monitoring
- AI-enhanced internship recommendations
- Calendar integration
- Video interview scheduling
- Multi-language support
- Dark mode customization
- Administrative analytics dashboard

---

# Conclusion

UniHub successfully delivers a comprehensive internship management platform that connects students and startups through a modern, secure, and scalable mobile application.

By leveraging Flutter's cross-platform capabilities and Firebase's cloud infrastructure, the system provides real-time communication, streamlined recruitment workflows, secure authentication, and efficient application management. The adoption of Clean Architecture, Riverpod, and the Repository Pattern results in a maintainable and extensible codebase suitable for future enhancements.

Comprehensive testing confirmed that the implemented functionality performs reliably across all major workflows, demonstrating that the application is ready for deployment and further evolution.

---

# Documentation

Additional project documentation includes:

- `docs/firebase_setup.md`
- `docs/diagrams.md`
- Firebase Security Rules
- Firestore Indexes
- Architecture Diagrams
- Navigation Diagrams
- Authentication Flow Diagrams

---

# License

This project was developed as **UniHub**, a Flutter + Firebase internship management platform.

All rights reserved by the project owner unless otherwise specified.