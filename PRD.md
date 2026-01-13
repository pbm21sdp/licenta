# Pet Adoption Mobile Application - Product Requirements Document (PRD)

**Version:** 1.0
**Date:** January 2026
**Status:** Draft

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [User Personas](#2-user-personas)
3. [Feature Requirements](#3-feature-requirements)
4. [User Stories](#4-user-stories)
5. [Technical Requirements](#5-technical-requirements)
6. [Success Metrics](#6-success-metrics)

---

## 1. Executive Summary

### 1.1 Product Vision
A modern, mobile-first pet adoption platform that connects animal shelters with potential adopters through an intuitive, engaging experience. The application revolutionizes the adoption process by implementing a Tinder-like swiping interface for browsing animals, making pet discovery enjoyable while streamlining the administrative workflow for shelter staff.

### 1.2 Problem Statement
Traditional pet adoption processes suffer from:
- Fragmented information across multiple shelter websites
- Overwhelming listings that make it difficult to find suitable matches
- Manual, paper-based adoption workflows
- Poor communication between shelters and potential adopters
- No centralized way to track and manage adoption requests

### 1.3 Solution Overview
The Pet Adoption App addresses these challenges by providing:
- **Unified Platform**: Single app connecting multiple shelters with adopters
- **Engaging Discovery**: Swipe-based interface for intuitive animal browsing
- **Digital Workflow**: End-to-end digital adoption request processing
- **Real-time Communication**: Push notifications for status updates
- **Interview Scheduling**: Built-in calendar integration for adoption interviews

### 1.4 Target Market
- **Primary**: Pet adopters aged 25-45 in urban/suburban areas
- **Secondary**: Animal shelters and rescue organizations seeking to modernize operations

### 1.5 Existing Technical Foundation
The backend infrastructure is already built with:
- Node.js/Express REST API
- PostgreSQL database with 9 tables (users, pets, adoptions, scheduled_meetings, etc.)
- JWT + OAuth authentication (Google, Facebook, Apple Sign-In)
- Multi-factor authentication (TOTP)
- Email service for notifications
- Comprehensive security middleware

---

## 2. User Personas

### 2.1 Adopter Persona: "Sarah the Pet Seeker"

**Demographics:**
- Age: 28-35
- Occupation: Working professional
- Location: Urban/Suburban apartment or house
- Tech Savvy: Comfortable with mobile apps

**Goals:**
- Find a pet that matches her lifestyle and living situation
- Browse available animals quickly without visiting multiple shelter websites
- Keep track of pets she's interested in
- Complete the adoption process with minimal friction
- Stay informed about her adoption request status

**Pain Points:**
- Overwhelmed by endless scrolling through pet listings
- Difficulty remembering which pets she liked across different sites
- Uncertainty about adoption requirements and timelines
- Lack of visibility into application status

**Behaviors:**
- Browses pets during commute or evening leisure time
- Shares interesting pet profiles with family/friends
- Wants to "favorite" pets to review later with partner
- Prefers mobile over desktop for casual browsing

### 2.2 Shelter Representative Persona: "Mark the Shelter Manager"

**Demographics:**
- Age: 35-55
- Role: Shelter staff member or volunteer coordinator
- Organization: Local animal shelter or rescue

**Goals:**
- Increase adoption rates for animals in care
- Efficiently process incoming adoption applications
- Screen potential adopters to ensure good matches
- Reduce administrative burden on staff
- Maintain accurate records of all interactions

**Pain Points:**
- Paper-based systems are error-prone and time-consuming
- Difficult to manage high volume of inquiries
- No centralized system to track application status
- Communication with adopters is fragmented (email, phone, in-person)

**Behaviors:**
- Reviews applications during office hours
- Needs quick access to applicant information
- Schedules multiple interviews per day
- Updates pet availability status frequently

---

## 3. Feature Requirements

### 3.1 Adopter Features

#### 3.1.1 Authentication & Onboarding
| Feature | Priority | Description |
|---------|----------|-------------|
| Email/Password Registration | P0 | Standard signup with email verification |
| Social Login | P0 | Google, Facebook, Apple Sign-In support |
| Multi-Factor Authentication | P1 | Optional TOTP-based 2FA via authenticator apps |
| Profile Management | P0 | Edit name, avatar, contact information |
| Password Recovery | P0 | Email-based password reset flow |

**Existing Backend Support:** Complete - All authentication features are already implemented.

#### 3.1.2 Pet Discovery - Swiping Interface
| Feature | Priority | Description |
|---------|----------|-------------|
| Swipe Cards | P0 | Tinder-like card stack showing pet photos and basic info |
| Swipe Right (Like) | P0 | Add pet to favorites list |
| Swipe Left (Pass) | P0 | Skip pet, remove from current session |
| Undo Last Swipe | P1 | Revert accidental swipe |
| Card Preview | P0 | Display: primary photo, name, age, breed, location |
| Tap for Details | P0 | Open full pet profile on card tap |

**New Backend Requirements:**
- `user_swipes` table to track swipe history
- `favorites` table to store liked pets
- API endpoints for swipe actions

#### 3.1.3 Pet Profile Details
| Feature | Priority | Description |
|---------|----------|-------------|
| Photo Gallery | P0 | Swipeable carousel of all pet photos |
| Basic Information | P0 | Name, type, breed, age, gender, size, color |
| Description | P0 | Detailed pet biography and personality |
| Health Status | P0 | Vaccinations, spay/neuter status, medical notes |
| Location | P1 | Shelter address and map integration |
| Traits/Tags | P1 | Behavioral traits (friendly, energetic, good with kids, etc.) |
| Adoption Fee | P1 | Display fee if applicable |
| Share Pet | P2 | Share pet profile via social/messaging apps |

**Existing Backend Support:** Complete - `pets`, `pet_photos`, `pet_traits` tables exist.

#### 3.1.4 Filtering & Search
| Feature | Priority | Description |
|---------|----------|-------------|
| Species Filter | P0 | Dog, Cat, Bird, Rabbit, Other |
| Age Filter | P0 | Puppy/Kitten, Young, Adult, Senior |
| Size Filter | P0 | Small, Medium, Large |
| Breed Filter | P1 | Search/select from available breeds |
| Gender Filter | P1 | Male, Female |
| Location Filter | P1 | Distance radius or city selection |
| Traits Filter | P2 | Good with kids, good with other pets, etc. |
| Save Filter Preferences | P2 | Remember user's preferred filters |

**Existing Backend Support:** Partial - Pet table has all filterable columns; API endpoints needed.

#### 3.1.5 Favorites Management
| Feature | Priority | Description |
|---------|----------|-------------|
| Favorites List | P0 | View all liked pets in a grid/list |
| Remove from Favorites | P0 | Unlike a pet |
| Sort Favorites | P1 | By date added, name, location |
| Favorites Count | P1 | Badge showing number of favorites |
| Quick Adopt Button | P0 | Start adoption application from favorites |

**New Backend Requirements:** `favorites` table (user_id, pet_id, created_at)

#### 3.1.6 Adoption Application
| Feature | Priority | Description |
|---------|----------|-------------|
| Application Form | P0 | Multi-step form for adoption request |
| Personal Information | P0 | Name, email, phone, address |
| Housing Information | P0 | Type (house/apartment), yard, rental status |
| Household Information | P0 | Children, other pets, family size |
| Pet Experience | P1 | Previous pet ownership history |
| Adoption Reason | P0 | Why adopter wants this pet |
| Save Draft | P2 | Continue application later |
| Submit Application | P0 | Send to shelter for review |

**Existing Backend Support:** Complete - `adoptions` table has all required fields.

#### 3.1.7 Application Tracking
| Feature | Priority | Description |
|---------|----------|-------------|
| My Applications | P0 | List of all submitted applications |
| Application Status | P0 | Pending, In Review, Approved, Rejected, Waitlisted |
| Status Timeline | P1 | Visual timeline of application progress |
| View Application Details | P0 | Review submitted information |
| Cancel Application | P1 | Withdraw pending application |

**Existing Backend Support:** Complete - `adoptions.status` field exists.

#### 3.1.8 Interview Scheduling
| Feature | Priority | Description |
|---------|----------|-------------|
| Available Slots | P1 | View shelter's available time slots |
| Book Interview | P1 | Select date, time, location |
| Interview Confirmation | P1 | Receive confirmation details |
| Reschedule | P2 | Change interview time if allowed |
| Cancel Interview | P2 | Cancel with notification to shelter |
| Calendar Integration | P2 | Add to device calendar |

**Existing Backend Support:** Complete - `scheduled_meetings` table exists.

#### 3.1.9 Notifications
| Feature | Priority | Description |
|---------|----------|-------------|
| Push Notifications | P0 | Real-time status updates |
| Application Status Changes | P0 | Notify on approve/deny/waitlist |
| Interview Reminders | P1 | Reminder before scheduled interview |
| New Pets Alert | P2 | Notify when matching pets are added |
| In-App Notification Center | P1 | History of all notifications |

**New Backend Requirements:** Push notification service (FCM/APNs), notification preferences table.

---

### 3.2 Shelter Representative Features

#### 3.2.1 Authentication
| Feature | Priority | Description |
|---------|----------|-------------|
| Shelter Staff Login | P0 | Admin-verified credentials |
| Role-Based Access | P0 | Distinct from adopter accounts |
| Secure Admin Registration | P0 | Requires admin secret key |

**Existing Backend Support:** Complete - `is_admin` flag and admin registration endpoint exist.

#### 3.2.2 Animal Management
| Feature | Priority | Description |
|---------|----------|-------------|
| Add New Pet | P0 | Full pet profile creation form |
| Edit Pet Profile | P0 | Update any pet information |
| Upload Photos | P0 | Add/remove/reorder photos |
| Set Primary Photo | P1 | Choose main display photo |
| Mark Pet Status | P0 | Available, Pending, Adopted |
| Delete Pet | P1 | Remove pet from system (soft delete) |
| Bulk Actions | P2 | Update multiple pets at once |
| AI-Assisted Detection | P2 | Auto-detect breed, color, size from photos |

**Existing Backend Support:** Complete - All tables and AI detection fields exist.

#### 3.2.3 Adoption Request Management
| Feature | Priority | Description |
|---------|----------|-------------|
| Incoming Requests Dashboard | P0 | View all pending applications |
| Filter by Status | P0 | Pending, In Review, Approved, Rejected |
| Filter by Pet | P1 | View applications for specific animal |
| Request Details | P0 | Full applicant information |
| Admin Notes | P1 | Internal notes on application |

**Existing Backend Support:** Complete - `adoptions` table with all fields.

#### 3.2.4 Request Processing
| Feature | Priority | Description |
|---------|----------|-------------|
| Approve Request | P0 | Approve adoption application |
| Deny Request | P0 | Reject with optional reason |
| Waitlist Request | P0 | Place on waiting list |
| Request Interview | P1 | Require interview before decision |
| Send Notification | P0 | Auto-notify adopter of decision |

**Existing Backend Support:** Partial - Status updates exist; notification system needed.

#### 3.2.5 Interview Management
| Feature | Priority | Description |
|---------|----------|-------------|
| Schedule Interview | P1 | Set date, time, location |
| View Scheduled Interviews | P1 | Calendar view of all interviews |
| Confirm/Cancel Interview | P1 | Manage interview status |
| Interview Notes | P2 | Record interview outcomes |

**Existing Backend Support:** Complete - `scheduled_meetings` table exists.

#### 3.2.6 Analytics Dashboard
| Feature | Priority | Description |
|---------|----------|-------------|
| Adoption Statistics | P2 | Total adoptions, approval rate |
| Popular Pets | P2 | Most viewed/favorited animals |
| Application Funnel | P2 | Conversion from view to adoption |
| Time-to-Adoption | P2 | Average days pet is listed |

**New Backend Requirements:** Analytics aggregation queries or views.

---

## 4. User Stories

### 4.1 Adopter User Stories

#### Epic: Account Management
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-A01 | As an adopter, I want to create an account with my email so I can save my favorites and submit applications | - Registration form with email, password, name<br>- Email verification required<br>- Validation for email format and password strength |
| US-A02 | As an adopter, I want to sign in with my Google account so I can access the app quickly | - Google OAuth button on login screen<br>- Auto-create account if new user<br>- Link to existing account if email matches |
| US-A03 | As an adopter, I want to enable 2FA so my account is more secure | - Setup flow with QR code<br>- 6-digit TOTP verification<br>- Backup codes option |
| US-A04 | As an adopter, I want to reset my password if I forget it | - "Forgot password" link on login<br>- Email with reset link sent<br>- Token expires after 1 hour |

#### Epic: Pet Discovery
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-A05 | As an adopter, I want to swipe through pet cards so I can quickly browse available animals | - Stack of cards with pet photo, name, age, breed<br>- Smooth swipe animation<br>- Endless scroll through database |
| US-A06 | As an adopter, I want to swipe right to add a pet to my favorites | - Swipe right triggers "like" animation<br>- Pet added to favorites list<br>- Confirmation visual feedback |
| US-A07 | As an adopter, I want to swipe left to pass on a pet | - Swipe left removes card<br>- Pet not added to favorites<br>- Next pet card appears |
| US-A08 | As an adopter, I want to undo my last swipe in case I made a mistake | - Undo button visible after swipe<br>- Previous card returns to stack<br>- Favorite status reverted if needed |
| US-A09 | As an adopter, I want to tap a pet card to see full details | - Tap opens full profile modal/screen<br>- All photos, description, health info visible<br>- "Like" and "Pass" buttons available |

#### Epic: Filtering
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-A10 | As an adopter, I want to filter pets by species so I only see dogs/cats/etc | - Filter button on swipe screen<br>- Species checkboxes<br>- Filters apply immediately to card stack |
| US-A11 | As an adopter, I want to filter by age so I find pets matching my preference | - Age range options (puppy, young, adult, senior)<br>- Multiple selections allowed<br>- Results update dynamically |
| US-A12 | As an adopter, I want to filter by size so I find pets suitable for my living space | - Size options (small, medium, large)<br>- Clear current selection button<br>- Persistence of filter across sessions |

#### Epic: Favorites Management
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-A13 | As an adopter, I want to view my favorites list so I can review pets I liked | - Favorites tab in navigation<br>- Grid/list view of liked pets<br>- Shows pet photo, name, basic info |
| US-A14 | As an adopter, I want to remove a pet from favorites if I'm no longer interested | - Remove/unlike button on each favorite<br>- Confirmation prompt<br>- Immediate removal from list |
| US-A15 | As an adopter, I want to start an adoption application from my favorites | - "Apply to Adopt" button on each favorite<br>- Pre-fills pet information in form<br>- Navigates to application screen |

#### Epic: Adoption Application
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-A16 | As an adopter, I want to fill out an adoption application form | - Multi-step form with progress indicator<br>- Fields: personal info, housing, household, experience<br>- Form validation on each step |
| US-A17 | As an adopter, I want to submit my application for shelter review | - Review summary before submission<br>- Submit button sends to shelter<br>- Confirmation screen with application ID |
| US-A18 | As an adopter, I want to track my application status | - "My Applications" screen<br>- Status badge (pending, approved, denied, waitlist)<br>- Tap for full details |
| US-A19 | As an adopter, I want to receive a notification when my application status changes | - Push notification on status update<br>- In-app notification badge<br>- Notification history accessible |

#### Epic: Interview Scheduling
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-A20 | As an adopter, I want to schedule an interview after my application is approved | - Available time slots shown<br>- Date picker and time selection<br>- Location information displayed |
| US-A21 | As an adopter, I want to receive a reminder before my scheduled interview | - Push notification 24 hours before<br>- Push notification 1 hour before<br>- Interview details in notification |

---

### 4.2 Shelter Representative User Stories

#### Epic: Animal Management
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-S01 | As a shelter rep, I want to add a new pet to the system | - Form with all pet fields<br>- Photo upload (multiple)<br>- Save creates new pet record |
| US-S02 | As a shelter rep, I want to edit a pet's profile information | - Edit button on pet details<br>- All fields editable<br>- Save updates database |
| US-S03 | As a shelter rep, I want to mark a pet as adopted so it's no longer shown to adopters | - Status dropdown on pet profile<br>- "Adopted" status hides from swipe feed<br>- Historical record preserved |
| US-S04 | As a shelter rep, I want to delete a pet that's no longer available | - Delete button with confirmation<br>- Soft delete (recoverable)<br>- Removed from adopter view |

#### Epic: Adoption Request Management
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-S05 | As a shelter rep, I want to view all incoming adoption requests | - Dashboard with request list<br>- Shows applicant name, pet, date, status<br>- Sortable and filterable |
| US-S06 | As a shelter rep, I want to approve an adoption request | - "Approve" action button<br>- Optional message to adopter<br>- Status updates, notification sent |
| US-S07 | As a shelter rep, I want to deny an adoption request | - "Deny" action button<br>- Require reason for denial<br>- Notification sent to adopter |
| US-S08 | As a shelter rep, I want to place a request on the waitlist | - "Waitlist" action button<br>- Optional position or note<br>- Notification sent to adopter |
| US-S09 | As a shelter rep, I want to add internal notes to an application | - Notes text field on request<br>- Only visible to shelter staff<br>- Timestamp and author tracked |

#### Epic: Interview Management
| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-S10 | As a shelter rep, I want to schedule an interview with an applicant | - Select date, time, location<br>- Notification sent to adopter<br>- Added to shelter calendar |
| US-S11 | As a shelter rep, I want to view all scheduled interviews | - Calendar or list view<br>- Filter by date range<br>- Shows adopter and pet info |
| US-S12 | As a shelter rep, I want to confirm or cancel an interview | - Status update options<br>- Notification sent on change<br>- Reason field for cancellation |

---

## 5. Technical Requirements

### 5.1 Technology Stack

#### 5.1.1 Existing Backend (Already Implemented)
| Component | Technology | Status |
|-----------|------------|--------|
| Runtime | Node.js | Complete |
| Framework | Express.js 4.18 | Complete |
| Database | PostgreSQL | Complete |
| Authentication | JWT + Passport.js | Complete |
| OAuth Providers | Google, Facebook, Apple | Complete |
| MFA | Speakeasy (TOTP) | Complete |
| Email | Nodemailer (Gmail SMTP) | Complete |
| Security | Helmet, CORS, Rate Limiting | Complete |
| Validation | express-validator | Complete |

#### 5.1.2 Mobile Application (To Be Built)
| Component | Recommended Technology | Rationale |
|-----------|----------------------|-----------|
| Framework | React Native | Cross-platform (iOS + Android), large ecosystem |
| State Management | Redux Toolkit / Zustand | Predictable state, works well with React Native |
| Navigation | React Navigation 6.x | Standard for React Native apps |
| HTTP Client | Axios | Promise-based, interceptors for auth |
| Push Notifications | Firebase Cloud Messaging (FCM) + APNs | Cross-platform push support |
| Swipe Gestures | react-native-deck-swiper | Tinder-like swipe functionality |
| Image Handling | react-native-fast-image | Optimized image loading and caching |
| Forms | React Hook Form + Yup | Performant forms with validation |
| Storage | AsyncStorage / MMKV | Local data persistence |

#### 5.1.3 Backend Additions Required
| Component | Technology | Purpose |
|-----------|------------|---------|
| Push Notifications | Firebase Admin SDK | Send push notifications to mobile |
| WebSockets | Socket.io | Real-time updates (optional) |
| File Storage | Local + Cloud (optional) | Pet photo storage |

### 5.2 Database Schema Additions

#### 5.2.1 New Tables Required

**favorites**
```sql
CREATE TABLE favorites (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pet_id INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, pet_id)
);
CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_pet ON favorites(pet_id);
```

**user_swipes** (for tracking swipe history and preventing re-shows)
```sql
CREATE TABLE user_swipes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pet_id INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    action VARCHAR(10) NOT NULL CHECK (action IN ('like', 'pass')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, pet_id)
);
CREATE INDEX idx_swipes_user ON user_swipes(user_id);
```

**notifications**
```sql
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, is_read);
```

**push_tokens** (for FCM/APNs)
```sql
CREATE TABLE push_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('ios', 'android')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, token)
);
```

### 5.3 API Endpoints Required

#### 5.3.1 Pet Discovery Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/pets/swipe` | Get batch of pets for swiping (excludes already swiped) |
| POST | `/api/v1/pets/:id/swipe` | Record swipe action (like/pass) |
| POST | `/api/v1/pets/:id/undo` | Undo last swipe |
| GET | `/api/v1/pets/:id` | Get full pet details |
| GET | `/api/v1/pets/search` | Search/filter pets |

#### 5.3.2 Favorites Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/favorites` | Get user's favorites list |
| POST | `/api/v1/favorites/:petId` | Add pet to favorites |
| DELETE | `/api/v1/favorites/:petId` | Remove pet from favorites |

#### 5.3.3 Adoption Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/adoptions` | Get user's adoption applications |
| GET | `/api/v1/adoptions/:id` | Get specific application details |
| POST | `/api/v1/adoptions` | Submit new adoption application |
| PUT | `/api/v1/adoptions/:id` | Update application (if pending) |
| DELETE | `/api/v1/adoptions/:id` | Cancel/withdraw application |

#### 5.3.4 Admin Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/pets` | List all pets (admin) |
| POST | `/api/v1/admin/pets` | Create new pet |
| PUT | `/api/v1/admin/pets/:id` | Update pet |
| DELETE | `/api/v1/admin/pets/:id` | Delete pet |
| GET | `/api/v1/admin/adoptions` | List all adoption requests |
| PUT | `/api/v1/admin/adoptions/:id/status` | Update request status |
| POST | `/api/v1/admin/adoptions/:id/schedule` | Schedule interview |

#### 5.3.5 Notification Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/notifications` | Get user's notifications |
| PUT | `/api/v1/notifications/:id/read` | Mark notification as read |
| PUT | `/api/v1/notifications/read-all` | Mark all as read |
| POST | `/api/v1/push-tokens` | Register device push token |
| DELETE | `/api/v1/push-tokens` | Remove push token (logout) |

### 5.4 Security Requirements

| Requirement | Implementation |
|-------------|----------------|
| Authentication | JWT tokens (15 min access, 7 day refresh) - Existing |
| Authorization | Role-based (adopter vs admin) via middleware - Existing |
| Password Security | bcrypt (10 rounds) - Existing |
| Rate Limiting | 100 req/15min general, 20 req/15min auth - Existing |
| Input Validation | express-validator on all endpoints - Existing |
| HTTPS | TLS 1.2+ required in production |
| Data Encryption | Sensitive data encrypted at rest |
| GDPR Compliance | Soft deletes, data export capability - Partial |

### 5.5 Performance Requirements

| Metric | Target |
|--------|--------|
| API Response Time | < 200ms (95th percentile) |
| Image Load Time | < 1s with caching |
| App Launch Time | < 3s cold start |
| Swipe Animation | 60 FPS |
| Offline Support | Cached favorites viewable offline |

### 5.6 Mobile App Architecture

```
src/
├── api/                    # API client and endpoints
│   ├── client.ts          # Axios instance with interceptors
│   ├── auth.ts            # Auth endpoints
│   ├── pets.ts            # Pet endpoints
│   └── adoptions.ts       # Adoption endpoints
├── components/            # Reusable UI components
│   ├── common/           # Buttons, inputs, cards
│   ├── pets/             # Pet card, pet detail
│   └── forms/            # Form components
├── screens/               # Screen components
│   ├── auth/             # Login, register, forgot password
│   ├── discover/         # Swipe screen
│   ├── favorites/        # Favorites list
│   ├── adoptions/        # Applications list
│   ├── profile/          # User profile
│   └── admin/            # Admin screens (conditional)
├── navigation/            # React Navigation setup
├── store/                 # State management
│   ├── slices/           # Redux slices or Zustand stores
│   └── hooks/            # Custom hooks
├── hooks/                 # Shared hooks
├── utils/                 # Utility functions
├── theme/                 # Colors, typography, spacing
└── types/                 # TypeScript types
```

---

## 6. Success Metrics

### 6.1 User Acquisition Metrics

| Metric | Target (6 months) | Measurement |
|--------|-------------------|-------------|
| App Downloads | 10,000+ | App store analytics |
| Registered Users | 5,000+ | Database count |
| Monthly Active Users (MAU) | 2,500+ | Auth logs |
| User Retention (Day 7) | > 40% | Cohort analysis |
| User Retention (Day 30) | > 25% | Cohort analysis |

### 6.2 Engagement Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Avg. Swipes per Session | 20+ | Swipe events |
| Avg. Session Duration | 5+ minutes | App analytics |
| Favorites per User | 5+ | Database query |
| Application Completion Rate | > 60% | Started vs submitted |
| Push Notification Opt-in | > 70% | Token registrations |

### 6.3 Adoption Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Applications Submitted | 500+ / month | Database count |
| Application Approval Rate | > 50% | Status analysis |
| Time to Decision | < 7 days | Date calculations |
| Successful Adoptions | 100+ / month | Completed adoptions |
| Interview Show Rate | > 80% | Scheduled vs completed |

### 6.4 Shelter Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Active Shelter Accounts | 50+ | Admin user count |
| Pets Listed | 1,000+ | Pet database count |
| Request Processing Time | < 48 hours | Average time to first action |
| Shelter Satisfaction | > 4.0 / 5.0 | Survey responses |

### 6.5 Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| API Uptime | > 99.5% | Monitoring |
| Error Rate | < 1% | Error tracking |
| App Crash Rate | < 0.5% | Crashlytics |
| App Store Rating | > 4.5 stars | Store reviews |

---

## Appendix A: Existing Database Schema Reference

The following tables already exist in the PostgreSQL database:

1. **users** - User accounts with auth fields (22 columns)
2. **pets** - Animal profiles with AI detection fields (28 columns)
3. **pet_photos** - Multiple photos per pet (8 columns)
4. **pet_traits** - Behavioral characteristics (4 columns)
5. **adoptions** - Adoption applications (25+ columns)
6. **scheduled_meetings** - Interview scheduling (12 columns)
7. **donations** - Stripe donations (9 columns)
8. **messages** - Contact form messages (7 columns)

## Appendix B: Implementation Phases

### Phase 1: Core Mobile App (MVP)
- User authentication (email + OAuth)
- Pet discovery with swiping
- Basic filtering (species, age, size)
- Favorites management
- Pet detail view

### Phase 2: Adoption Flow
- Adoption application form
- Application submission
- Application tracking
- Basic notifications (email)

### Phase 3: Admin Features
- Pet management (CRUD)
- Request management dashboard
- Status updates with notifications
- Interview scheduling

### Phase 4: Enhanced Features
- Push notifications
- MFA for mobile
- Advanced filtering
- Interview calendar integration
- Analytics dashboard

---

*This PRD aligns with the existing backend infrastructure and provides a roadmap for mobile application development.*
