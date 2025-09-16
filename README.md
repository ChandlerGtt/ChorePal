# ChorePal

ChorePal is a Flutter-based mobile application designed to help parents manage chores for their children. It provides a structured way for children to complete tasks and earn rewards, fostering responsibility and accountability.

## Project Overview

ChorePal connects parents and children through a family-based system where:
- Parents can create and manage chores, set priorities, and define rewards
- Children can view and complete their assigned chores
- A point-based reward system incentivizes chore completion
- Each family has a unique code that allows children to join their family group

The app features a dual-interface approach with separate parent and child dashboards, tailored to their specific needs and responsibilities.

## Features

### Parent Features
- Create a family account with a unique family code
- Add and manage chores with descriptions, deadlines, and priority levels
- Set up rewards with point values
- Review and approve completed chores
- Monitor children's progress and point accumulation

### Child Features
- Join a family using the family code
- View assigned chores in priority order
- Mark chores as completed
- Earn points for completing chores (after parent approval)
- Redeem points for rewards set by parents

## Chore Approval Workflow

ChorePal implements a structured chore approval process:

1. **Assignment**: Parents create chores and assign them to specific children
2. **Completion**: Children mark their assigned chores as completed
3. **Pending Approval**: Completed chores enter a "pending approval" state
4. **Parent Review**: Parents review and approve (or reject) completed chores
5. **Points Awarded**: Upon approval, points are automatically awarded to the child
6. **Reward Redemption**: Children can redeem their earned points for rewards

This workflow ensures accountability and oversight while maintaining a fair reward system.

## Setup & Installation

1. **Prerequisites**
   - Flutter SDK (latest version recommended)
   - Android Studio / VS Code
   - Firebase account

2. **Getting Started**
   ```bash
   # Clone the repository
   git clone https://github.com/yourusername/chore_pal.git
   
   # Navigate to the project directory
   cd chore_pal
   
   # Install dependencies
   flutter pub get
   
   # Run the application
   flutter run
   ```

3. **Firebase Configuration**
   - The app uses Firebase for authentication and data storage
   - Configure Firebase using the Firebase console and update the `firebase_options.dart` file

## Class Structure

The application follows an object-oriented approach with a clear class hierarchy:

- **User (Superclass)**
  - Contains common user properties: id, name, familyId, points
  - Handles basic user functionality

- **Parent (Subclass of User)**
  - Manages family creation and administration
  - Has chore and reward creation capabilities
  - Can approve completed chores and award points

- **Child (Subclass of User)**
  - Joins existing families with family code
  - Views and completes assigned chores
  - Accumulates and redeems points for rewards

The data model is implemented using Firebase Firestore collections, with proper relationships between users, families, chores, and rewards.

## Development Phases

### Phase 1: Project Setup & Authentication
- [x] Initialize Flutter project
- [x] Configure Firebase integration
- [x] Set up authentication for parents
- [x] Design login screen with parent/child toggle

### Phase 2: User Management
- [x] Implement User superclass
- [x] Develop Parent and Child subclasses
- [x] Create family generation system with unique codes
- [x] Build family joining mechanism for children

### Phase 3: Data Models
- [x] Design Chore model with priority system
- [x] Create Reward model with point values
- [x] Implement ChoreState management
- [x] Develop RewardState management

### Phase 4: Parent Dashboard
- [x] Build parent dashboard UI
- [x] Create chore management interface
- [x] Implement reward creation system
- [x] Display family code for sharing

### Phase 5: Child Dashboard
- [x] Design child-friendly dashboard
- [x] Show prioritized chore list
- [x] Create chore completion workflow
- [x] Display available and earned rewards

### Phase 6: Chore Management
- [x] Implement chore assignment to specific children
- [x] Add deadline notifications
- [x] Create chore filters and sorting options
- [x] Build chore history and statistics

### Phase 7: Reward System
- [x] Implement tiered reward levels
- [x] Create reward redemption process
- [x] Add reward history tracking
- [x] Develop point milestone celebrations

### Phase 8: Notification System
- [ ] Set up push notifications
- [ ] Create reminder system for upcoming chores
- [ ] Implement notification preferences
- [ ] Add chore approval notifications

### Phase 9: UI/UX Enhancements
- [ ] Polish both parent and child interfaces
- [ ] Add animations and interactive elements
- [ ] Implement accessibility features
- [ ] Create dark mode option

### Phase 10: Testing & Deployment
- [ ] Conduct thorough testing
- [ ] Fix bugs and optimize performance
- [ ] Prepare app for release
- [ ] Deploy to app stores

## Current Progress

The application has completed the following phases:
- Firebase integration and authentication
- User management system with parent and child roles
- Family creation and joining functionality
- Basic chore and reward models
- Dashboard interfaces for both parent and child users
- Chore assignment system where parents can assign specific chores to children
- Tiered reward system with redemption functionality

The core data structure uses Firestore collections for users, families, chores, and rewards, with proper relationships established between them.

## Future Steps

Immediate priorities include:
1. Implementing notification system for reminders and approvals
2. Adding reward history tracking functionality
3. Developing point milestone celebrations for children
4. Improving the user interface for better usability, especially for younger children

## Contributing

Contributions to ChorePal are welcome! Please follow these steps:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your branch
5. Submit a pull request
