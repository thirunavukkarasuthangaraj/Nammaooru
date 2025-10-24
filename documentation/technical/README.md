# Technical Architecture Documentation

System design and technical architecture for NammaOoru platform.

## 📄 Documents in this folder

### [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md)
Complete system architecture documentation
- High-level architecture
- Database schema
- Component design
- Technology stack
- Security architecture
- Scalability considerations
- Infrastructure design

### [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
Index of all project documentation
- Documentation overview
- Quick links
- Document categories
- Update history

## 🏗️ Architecture Overview

### Three-Tier Architecture

```
┌─────────────────────────────────────┐
│     Presentation Layer               │
│  ┌──────────┐  ┌──────────────────┐ │
│  │ Angular  │  │ Flutter Mobile   │ │
│  │ Web App  │  │ Apps (3 types)   │ │
│  └──────────┘  └──────────────────┘ │
└─────────────────────────────────────┘
                  ↓ REST APIs
┌─────────────────────────────────────┐
│     Application Layer                │
│  ┌─────────────────────────────────┐│
│  │   Spring Boot Backend           ││
│  │   - Business Logic              ││
│  │   - Firebase Integration        ││
│  │   - JWT Authentication          ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│     Data Layer                       │
│  ┌──────────────┐  ┌──────────────┐ │
│  │ PostgreSQL   │  │   Firebase   │ │
│  │   Database   │  │     FCM      │ │
│  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────┘
```

## 🛠️ Technology Stack

- **Backend**: Spring Boot (Java 17)
- **Frontend**: Angular 15+
- **Mobile**: Flutter 3.x
- **Database**: PostgreSQL 15
- **Notifications**: Firebase Cloud Messaging
- **Authentication**: JWT
- **Server**: Ubuntu 20.04 LTS

## 📊 Database Design

See [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md) for complete database schema.

## 📞 Support

For architecture questions, review the complete documentation in this folder.
