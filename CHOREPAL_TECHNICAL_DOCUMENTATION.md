# ChorePal Technical Documentation

## Table of Contents

1. [Overview](#1-overview)
2. [User Roles & Permissions](#2-user-roles--permissions)
3. [Full App Flow](#3-full-app-flow)
   - [3.1 Onboarding Flow](#31-onboarding-flow)
   - [3.2 Parent App Flow](#32-parent-app-flow)
   - [3.3 Child App Flow](#33-child-app-flow)
4. [Database Structure (Firebase Firestore)](#4-database-structure-firebase-firestore)
5. [Notification System Architecture](#5-notification-system-architecture)
   - [5.1 Notification Types](#51-notification-types)
   - [5.2 How Notifications Are Triggered](#52-how-notifications-are-triggered)
   - [5.3 Cloud Function Examples](#53-cloud-function-examples)
   - [5.4 FCM Token Management](#54-fcm-token-management)
   - [5.5 Flutter Client Logic](#55-flutter-client-logic)
6. [Sequence Diagrams](#6-sequence-diagrams)
7. [Error Handling / Edge Cases](#7-error-handling--edge-cases)
8. [Future Expansion Ideas](#8-future-expansion-ideas)

---

## 1. Overview

### 1.1 Brief Description

**ChorePal** is a family task management mobile application designed to help parents organize household chores and motivate children through a gamified point-and-reward system. The app facilitates communication between parents and children regarding task assignments, completions, and rewards, creating an engaging environment for family collaboration.

### 1.2 Purpose of This Document

This technical documentation serves as a comprehensive guide for:
- **Developer Onboarding**: Understanding the codebase architecture and implementation details
- **Project Planning**: Reference for feature development and system design decisions
- **Architecture Review**: Technical overview for stakeholders and team members
- **Academic/Professional Presentation**: Detailed system documentation for educational or business purposes

### 1.3 Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Frontend Framework** | Flutter (Dart) | Cross-platform mobile app (iOS/Android/Web/Windows) |
| **Authentication** | Firebase Authentication | User signup, login, and session management |
| **Database** | Firebase Firestore | Real-time NoSQL database for users, families, chores, and rewards |
| **Cloud Functions** | Firebase Cloud Functions (Node.js) | Serverless backend for email and SMS notifications |
| **Email Service** | SendGrid (via Cloud Functions) | Transactional email delivery |
| **SMS Service** | Twilio (via Cloud Functions) | SMS message delivery |
| **Local Notifications** | flutter_local_notifications | In-app push notifications |
| **State Management** | Provider | Reactive state management for UI updates |
| **Offline Support** | Firestore Offline Persistence | Local caching for offline functionality |

---

## 2. User Roles & Permissions

### 2.1 Parent Capabilities

Parents have full administrative control over their family account:

- **Family Management**
  - Create and manage family account
  - Generate and share unique 6-digit family codes
  - Add/remove children from family
  - View all family members

- **Chore Management**
  - Create, edit, and delete chores
  - Assign chores to specific children
  - Set chore priorities (high, medium, low)
  - Set point values and deadlines
  - Approve or deny completed chores
  - View chore history and statistics

- **Reward Management**
  - Create, edit, and delete rewards
  - Set point requirements and tiers (bronze, silver, gold)
  - View reward redemption history

- **Point Management**
  - Award points upon chore approval
  - View point totals for all children
  - Manage point balances

- **Notifications**
  - Receive notifications when children complete chores
  - Configure notification preferences (push, email, SMS)
  - View notification history

### 2.2 Child Capabilities

Children have limited, task-focused capabilities:

- **Chore Interaction**
  - View assigned chores
  - Mark chores as complete
  - View chore details (title, description, deadline, points)
  - See pending approval status

- **Point System**
  - View current point balance
  - See points earned per chore
  - Track point history

- **Reward System**
  - Browse available rewards
  - View point requirements
  - Redeem rewards (if sufficient points)
  - View redemption history

- **Progress Tracking**
  - View leaderboard rankings
  - See completion statistics
  - Track streaks and achievements

- **Notifications**
  - Receive notifications for new chores, approvals, and milestones
  - Configure notification preferences

### 2.3 Access Control

#### UI-Level Access Control

The app uses role-based UI rendering:

```dart
// Example: Role-based navigation
if (userState.isParent) {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => EnhancedParentDashboard()
  ));
} else {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => EnhancedChildDashboard(childId: user.id)
  ));
}
```

#### Database-Level Access Control

Firestore Security Rules enforce data access:

```javascript
// Example security rules (conceptual)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Parents can read all family data
    match /families/{familyId} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isParent == true &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.familyId == familyId;
    }
    
    // Chores: Parents can write, children can read assigned chores
    match /chores/{choreId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isParent == true;
    }
  }
}
```

---

## 3. Full App Flow

### 3.1 Onboarding Flow

#### 3.1.1 Signup/Login (Firebase Auth)

**Parent Registration Flow:**

```
1. User selects "Parent" role on login screen
2. Enters: Name, Email, Password, Family Name
3. App calls: Firebase Auth createUserWithEmailAndPassword()
4. On success:
   - Creates family document in Firestore
   - Generates unique 6-digit family code
   - Creates parent user document
   - Links parent to family
5. Auto-login and navigate to Parent Dashboard
```

**Parent Login Flow:**

```
1. User selects "Parent" role
2. Enters: Email, Password
3. App calls: Firebase Auth signInWithEmailAndPassword()
4. Verifies user document exists and isParent == true
5. Loads family data and navigates to Parent Dashboard
```

**Child Registration/Login Flow:**

```
1. User selects "Child" role
2. Enters: Name, Family Code (6 digits)
3. App validates family code format
4. Searches Firestore for family with matching code
5. If family found:
   - Checks if child with same name exists
   - If exists: Uses existing Firebase Auth account
   - If new: Creates Firebase Auth account with generated email
   - Creates/updates child user document
   - Adds child to family's childrenIds array
6. Navigates to Child Dashboard
```

#### 3.1.2 Role Selection

The app uses a toggle on the login screen to switch between Parent and Child modes. The selected role determines:
- Which registration/login form is displayed
- Which authentication flow is executed
- Which dashboard is shown after authentication

#### 3.1.3 Linking Child to Parent Account

**Family Code System:**

1. **Code Generation**: When a parent creates an account, a unique 6-digit numeric code is generated (e.g., `180939`)
2. **Code Storage**: Stored in the `families/{familyId}` document as `familyCode`
3. **Code Sharing**: Parent can view and copy the code from the dashboard
4. **Code Validation**: Child enters code, app searches `families` collection where `familyCode == enteredCode`
5. **Linking**: On successful match, child's `familyId` is set to the matched family's ID

**Visual Flow:**

```
Parent Account Creation
    ↓
Family Document Created
    ↓
Family Code Generated: "180939"
    ↓
Parent Shares Code with Child
    ↓
Child Enters Code in App
    ↓
App Searches: families.where('familyCode', '==', '180939')
    ↓
Family Found → Child Linked
```

---

### 3.2 Parent App Flow

#### 3.2.1 Home Dashboard

The parent dashboard (`EnhancedParentDashboard`) displays:

- **Family Code Header**: Shows the 6-digit code for sharing
- **Statistics Tab**: Completion rates, total points awarded, family activity
- **Tab Navigation**: Chores, Rewards, Children, Leaderboard, Stats

#### 3.2.2 Add/Edit/Delete Chores

**Add Chore Flow:**

```
1. Parent taps "Add Chore" button (FloatingActionButton)
2. Dialog opens with form fields:
   - Title (required)
   - Description (optional)
   - Deadline (date picker)
   - Point Value (numeric input)
   - Priority (dropdown: high, medium, low)
3. Parent submits form
4. App creates Chore object
5. Firestore write: chores.add(chore.toFirestore())
6. Chore appears in chores list
7. Optional: Assign to child immediately
```

**Edit Chore Flow:**

```
1. Parent taps on existing chore card
2. Edit dialog opens with pre-filled values
3. Parent modifies fields
4. Firestore update: chores.doc(choreId).update(updatedData)
5. UI updates via ChoreState provider
```

**Delete Chore Flow:**

```
1. Parent long-presses chore or taps delete icon
2. Confirmation dialog appears
3. On confirm: Firestore delete: chores.doc(choreId).delete()
4. Chore removed from UI
```

#### 3.2.3 Add/Edit/Delete Rewards

**Add Reward Flow:**

```
1. Parent navigates to Rewards tab
2. Taps "Add Reward" button
3. Navigates to AddRewardScreen
4. Form fields:
   - Title (required)
   - Description (optional)
   - Points Required (numeric)
   - Tier (dropdown: bronze, silver, gold)
   - Optional image URL
5. Submit → Firestore: rewards.add(reward.toFirestore())
```

**Edit/Delete Rewards:**

Similar flow to chores, with Firestore update/delete operations.

#### 3.2.4 Assign Chores to a Child

**Assignment Flow:**

```
1. Parent taps "Assign" on a chore card
2. Navigates to AssignChoreScreen
3. Screen shows list of children in family
4. Parent selects one or more children
5. Firestore update:
   chores.doc(choreId).update({
     'assignedTo': FieldValue.arrayUnion([childId])
   })
6. Child receives notification (if enabled)
7. Chore appears in child's chore list
```

#### 3.2.5 Approve or Deny Completed Chores

**Approval Flow:**

```
1. Parent views chores list
2. Sees chores with isPendingApproval == true
3. Taps "Approve" button on chore card
4. App updates chore:
   - isCompleted = true
   - isPendingApproval = false
   - completedAt = serverTimestamp()
5. App awards points to child:
   - users.doc(childId).update({
       'points': FieldValue.increment(chore.pointValue)
     })
6. Child receives approval notification
7. Chore moves to completed state
```

**Denial Flow:**

```
1. Parent taps "Deny" button
2. Chore status reset:
   - isCompleted = false
   - isPendingApproval = false
   - completedBy = null
3. Child receives notification (optional)
4. Chore returns to assigned state
```

#### 3.2.6 Manage Point Totals

Points are automatically managed through:
- **Awarding**: When parent approves a chore, points are incremented
- **Deducting**: When child redeems reward, points are decremented
- **Viewing**: Parent dashboard shows point totals per child
- **History**: Points changes are tracked through chore/reward completion timestamps

---

### 3.3 Child App Flow

#### 3.3.1 Daily Chore List

**Chore List Display:**

```
1. Child opens app → Child Dashboard
2. App queries Firestore:
   chores.where('familyId', '==', familyId)
         .where('assignedTo', 'array-contains', childId)
3. Filters chores:
   - Not completed (isCompleted == false)
   - Sorted by deadline (ascending)
4. Displays in list view with:
   - Chore title
   - Deadline countdown
   - Point value
   - Priority indicator
   - Completion button
```

#### 3.3.2 Marking Chore as Complete

**Completion Flow:**

```
1. Child taps "Complete" button on chore card
2. App updates chore in Firestore:
   chores.doc(choreId).update({
     'isCompleted': false,  // Not fully completed yet
     'isPendingApproval': true,
     'completedBy': childId,
     'completedAt': FieldValue.serverTimestamp()
   })
3. Chore moves to "Pending Approval" state
4. Parent receives notification
5. Child sees "Waiting for Approval" status
```

#### 3.3.3 Earning Points

Points are earned when:
1. Child marks chore complete
2. Parent approves the chore
3. System increments child's points: `points += chore.pointValue`

**Point Update Flow:**

```
Parent Approves Chore
    ↓
Firestore Transaction:
  - Update chore: isCompleted = true
  - Update child: points += pointValue
    ↓
Child's point balance updates
    ↓
Child receives notification with points earned
```

#### 3.3.4 Redeeming Rewards

**Redemption Flow:**

```
1. Child navigates to Rewards tab
2. Views available rewards (pointsRequired <= child.points)
3. Taps "Redeem" on desired reward
4. Confirmation dialog appears
5. On confirm:
   - Firestore update: rewards.doc(rewardId).update({
       'isRedeemed': true,
       'redeemedBy': childId,
       'redeemedAt': FieldValue.serverTimestamp()
     })
   - Deduct points: users.doc(childId).update({
       'points': FieldValue.increment(-reward.pointsRequired)
     })
   - Add to child's redeemedRewards array
6. Reward marked as redeemed
7. Parent receives notification (optional)
```

#### 3.3.5 Viewing Progress

**Progress Tracking Features:**

- **Leaderboard**: Shows ranking within family based on points
- **Statistics**: Completion rates, points earned, chores completed
- **Streaks**: Consecutive days of completing chores
- **Achievements**: Milestones reached (e.g., 100 points, 10 chores completed)

---

## 4. Database Structure (Firebase Firestore)

### 4.1 Collection: `/users/{userId}`

Represents both parent and child users.

**Schema:**

```json
{
  "name": "string",
  "email": "string (parent only)",
  "familyId": "string",
  "isParent": "boolean",
  "points": "number",
  "createdAt": "timestamp",
  "pushNotificationsEnabled": "boolean",
  "emailNotificationsEnabled": "boolean",
  "smsNotificationsEnabled": "boolean",
  "phoneNumber": "string (optional)",
  "profileIcon": "string (optional: 'boy', 'girl')",
  
  // Child-specific fields:
  "completedChores": ["string (chore IDs)"],
  "redeemedRewards": ["string (reward IDs)"]
}
```

**Example Parent Document:**

```json
{
  "name": "John Smith",
  "email": "john@example.com",
  "familyId": "abc123xyz",
  "isParent": true,
  "points": 0,
  "createdAt": "2024-01-15T10:30:00Z",
  "pushNotificationsEnabled": true,
  "emailNotificationsEnabled": true,
  "smsNotificationsEnabled": false,
  "phoneNumber": "+15551234567"
}
```

**Example Child Document:**

```json
{
  "name": "Emma Smith",
  "familyId": "abc123xyz",
  "isParent": false,
  "points": 150,
  "createdAt": "2024-01-20T14:00:00Z",
  "pushNotificationsEnabled": true,
  "emailNotificationsEnabled": true,
  "smsNotificationsEnabled": false,
  "profileIcon": "girl",
  "completedChores": ["chore1", "chore2"],
  "redeemedRewards": ["reward1"]
}
```

### 4.2 Collection: `/families/{familyId}`

Represents a family group.

**Schema:**

```json
{
  "familyName": "string",
  "familyCode": "string (6 digits)",
  "parentId": "string (parent user ID)",
  "childrenIds": ["string (child user IDs)"],
  "createdAt": "timestamp"
}
```

**Example:**

```json
{
  "familyName": "The Smith Family",
  "familyCode": "180939",
  "parentId": "parent_user_id_123",
  "childrenIds": ["child_user_id_456", "child_user_id_789"],
  "createdAt": "2024-01-15T10:30:00Z"
}
```

### 4.3 Collection: `/chores/{choreId}`

Represents a chore/task.

**Schema:**

```json
{
  "title": "string",
  "description": "string",
  "deadline": "timestamp",
  "isCompleted": "boolean",
  "isPendingApproval": "boolean",
  "pointValue": "number",
  "priority": "string ('high', 'medium', 'low')",
  "assignedTo": ["string (child user IDs)"],
  "completedBy": "string (child user ID, optional)",
  "completedAt": "timestamp (optional)",
  "familyId": "string"
}
```

**Example:**

```json
{
  "title": "Take out the trash",
  "description": "Empty all trash bins and take to curb",
  "deadline": "2024-01-25T18:00:00Z",
  "isCompleted": false,
  "isPendingApproval": true,
  "pointValue": 10,
  "priority": "medium",
  "assignedTo": ["child_user_id_456"],
  "completedBy": "child_user_id_456",
  "completedAt": "2024-01-24T16:30:00Z",
  "familyId": "abc123xyz"
}
```

### 4.4 Collection: `/rewards/{rewardId}`

Represents a reward that can be redeemed.

**Schema:**

```json
{
  "title": "string",
  "description": "string",
  "pointsRequired": "number",
  "tier": "string ('bronze', 'silver', 'gold')",
  "isRedeemed": "boolean",
  "redeemedBy": "string (child user ID, optional)",
  "redeemedAt": "timestamp (optional)",
  "imageUrl": "string (optional)",
  "familyId": "string"
}
```

**Example:**

```json
{
  "title": "Extra 30 minutes of screen time",
  "description": "Enjoy an additional 30 minutes of device time",
  "pointsRequired": 50,
  "tier": "bronze",
  "isRedeemed": false,
  "imageUrl": null,
  "familyId": "abc123xyz"
}
```

### 4.5 Data Relationships

```
Family (1) ──< (Many) Users (Parent + Children)
    │
    └──< (Many) Chores
    │
    └──< (Many) Rewards

User (Child) ──< (Many) Chores (assignedTo)
User (Child) ──< (Many) Rewards (redeemedBy)
```

---

## 5. Notification System Architecture

### 5.1 Notification Types

#### 5.1.1 Chore Assigned

**Trigger**: When parent assigns a chore to a child

**Recipient**: Child

**Content**:
- Title: "New Chore Assigned 📝"
- Body: "You have a new chore: '[Chore Title]'"

**Implementation**: `NotificationHelper.showNewChoreAssigned()`

#### 5.1.2 Chore Due Soon

**Trigger**: Scheduled check for chores with deadline approaching (e.g., within 24 hours)

**Recipient**: Child

**Content**:
- Title: "Chore Due Soon ⏰"
- Body: "'[Chore Title]' is due soon!"

**Implementation**: Can be implemented via scheduled Cloud Function or local notification scheduling

#### 5.1.3 Chore Marked Complete

**Trigger**: When child marks a chore as complete

**Recipient**: Parent

**Content**:
- Title: "Chore Completed! 📋"
- Body: "[Child Name] completed '[Chore Title]' and is waiting for your approval."

**Implementation**: `NotificationHelper.showChoreCompletedByChildNotification()`

#### 5.1.4 Parent Approval/Denial

**Trigger**: When parent approves or denies a completed chore

**Recipient**: Child

**Approval Content**:
- Title: "Chore Approved! ✅"
- Body: "Great job! '[Chore Title]' was approved. You earned [X] points!"

**Denial Content**:
- Title: "Chore Needs Revision 🔄"
- Body: "'[Chore Title]' was not approved. Please check with your parent."

**Implementation**: `NotificationHelper.showChoreApprovedNotification()`

#### 5.1.5 Reward Redeemed

**Trigger**: When child redeems a reward

**Recipient**: Parent (optional)

**Content**:
- Title: "Reward Redeemed 🎁"
- Body: "[Child Name] redeemed '[Reward Title]' for [X] points."

#### 5.1.6 Additional Notification Types

- **Daily Reminders**: `showDailyReminder()` - Daily check-in for pending chores
- **Overdue Alerts**: `showOverdueChoreAlert()` - Notify about overdue chores
- **Streak Achievements**: `showStreakAchievement()` - Celebrate consecutive completion days
- **Weekly Summary**: `showWeeklySummary()` - Progress report
- **Reward Available**: `showRewardAvailable()` - Alert when child can afford a reward
- **Streak at Risk**: `showStreakAtRisk()` - Warn about breaking a streak

### 5.2 How Notifications Are Triggered

#### 5.2.1 Firestore Writes

Notifications are primarily triggered by Firestore document changes:

**Example: Chore Assignment**

```dart
// When parent assigns chore
await chores.doc(choreId).update({
  'assignedTo': FieldValue.arrayUnion([childId])
});

// Trigger notification (client-side)
final child = await firestoreService.getUserById(childId);
NotificationHelper.showNewChoreAssigned(
  child.name,
  chore.title
);
```

#### 5.2.2 Cloud Functions (Future Implementation)

For server-side notifications, Cloud Functions can listen to Firestore changes:

**Example: onCreate Trigger**

```javascript
exports.onChoreCreated = functions.firestore
  .document('chores/{choreId}')
  .onCreate(async (snap, context) => {
    const chore = snap.data();
    
    // Send notification to assigned children
    for (const childId of chore.assignedTo) {
      await sendNotificationToChild(childId, {
        title: 'New Chore Assigned',
        body: `You have a new chore: ${chore.title}`
      });
    }
  });
```

**Example: onUpdate Trigger**

```javascript
exports.onChoreUpdated = functions.firestore
  .document('chores/{choreId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Check if chore was just approved
    if (!before.isPendingApproval && after.isPendingApproval === false && after.isCompleted) {
      const childId = after.completedBy;
      await sendNotificationToChild(childId, {
        title: 'Chore Approved!',
        body: `Great job! "${after.title}" was approved. You earned ${after.pointValue} points!`
      });
    }
  });
```

#### 5.2.3 Scheduled Notifications

For time-based notifications (e.g., daily reminders, due soon alerts):

**Cloud Function with Pub/Sub:**

```javascript
exports.dailyChoreReminder = functions.pubsub
  .schedule('0 9 * * *') // 9 AM daily
  .timeZone('America/New_York')
  .onRun(async (context) => {
    // Query all families
    const families = await admin.firestore().collection('families').get();
    
    for (const familyDoc of families.docs) {
      const children = await getChildrenInFamily(familyDoc.id);
      
      for (const child of children) {
        const pendingChores = await getPendingChoresForChild(child.id);
        
        if (pendingChores.length > 0) {
          await sendNotificationToChild(child.id, {
            title: 'Daily Chore Check-in',
            body: `You have ${pendingChores.length} chore(s) to complete today!`
          });
        }
      }
    }
  });
```

### 5.3 Cloud Function Examples

#### 5.3.1 Send Push Notification When Child Completes Chore

**Current Implementation (Client-Side):**

```dart
// In Flutter app when child marks chore complete
await chores.doc(choreId).update({
  'isPendingApproval': true,
  'completedBy': childId,
  'completedAt': FieldValue.serverTimestamp()
});

// Get parent user
final parent = await firestoreService.getParentByFamilyId(familyId);

// Send notification
NotificationHelper.showChoreCompletedByChildNotification(
  child.name,
  chore.title
);
```

**Future Cloud Function Implementation:**

```javascript
exports.onChoreCompleted = functions.firestore
  .document('chores/{choreId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Detect when chore moves to pending approval
    if (!before.isPendingApproval && after.isPendingApproval === true) {
      const choreId = context.params.choreId;
      const childId = after.completedBy;
      const familyId = after.familyId;
      
      // Get child and parent info
      const childDoc = await admin.firestore().doc(`users/${childId}`).get();
      const child = childDoc.data();
      
      const familyDoc = await admin.firestore().doc(`families/${familyId}`).get();
      const family = familyDoc.data();
      const parentId = family.parentId;
      
      const parentDoc = await admin.firestore().doc(`users/${parentId}`).get();
      const parent = parentDoc.data();
      
      // Get parent's FCM token
      const parentToken = parent.fcmToken;
      
      if (parentToken && parent.pushNotificationsEnabled) {
        const message = {
          notification: {
            title: 'Chore Completed! 📋',
            body: `${child.name} completed "${after.title}" and is waiting for your approval.`
          },
          data: {
            type: 'chore_completed',
            choreId: choreId,
            childId: childId
          },
          token: parentToken
        };
        
        await admin.messaging().send(message);
      }
    }
  });
```

#### 5.3.2 Send Notification When Parent Assigns New Chore

**Cloud Function:**

```javascript
exports.onChoreAssigned = functions.firestore
  .document('chores/{choreId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Check if new children were added to assignedTo
    const beforeAssigned = before.assignedTo || [];
    const afterAssigned = after.assignedTo || [];
    const newlyAssigned = afterAssigned.filter(id => !beforeAssigned.includes(id));
    
    if (newlyAssigned.length > 0) {
      // Send notifications to newly assigned children
      for (const childId of newlyAssigned) {
        const childDoc = await admin.firestore().doc(`users/${childId}`).get();
        const child = childDoc.data();
        
        if (child.fcmToken && child.pushNotificationsEnabled) {
          const message = {
            notification: {
              title: 'New Chore Assigned 📝',
              body: `You have a new chore: "${after.title}"`
            },
            data: {
              type: 'chore_assigned',
              choreId: context.params.choreId
            },
            token: child.fcmToken
          };
          
          await admin.messaging().send(message);
        }
      }
    }
  });
```

#### 5.3.3 Scheduled Reminders (Pseudocode)

```javascript
exports.choreDueSoonReminder = functions.pubsub
  .schedule('0 */6 * * *') // Every 6 hours
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const tomorrow = new Date(now.toDate());
    tomorrow.setHours(tomorrow.getHours() + 24);
    const tomorrowTimestamp = admin.firestore.Timestamp.fromDate(tomorrow);
    
    // Find chores due within 24 hours
    const dueSoonChores = await admin.firestore()
      .collection('chores')
      .where('deadline', '<=', tomorrowTimestamp)
      .where('deadline', '>', now)
      .where('isCompleted', '==', false)
      .get();
    
    for (const choreDoc of dueSoonChores.docs) {
      const chore = choreDoc.data();
      
      for (const childId of chore.assignedTo) {
        const childDoc = await admin.firestore().doc(`users/${childId}`).get();
        const child = childDoc.data();
        
        if (child.fcmToken && child.pushNotificationsEnabled) {
          await admin.messaging().send({
            notification: {
              title: 'Chore Due Soon ⏰',
              body: `"${chore.title}" is due soon!`
            },
            token: child.fcmToken
          });
        }
      }
    }
  });
```

### 5.4 FCM Token Management

#### 5.4.1 Retrieving FCM Token in Flutter

**Current Implementation Note**: The app currently uses `flutter_local_notifications` for local notifications. FCM integration would require the following:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Request permission
  Future<bool> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
  
  // Get FCM token
  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
  
  // Initialize FCM
  Future<void> initialize() async {
    // Request permission
    await requestPermission();
    
    // Get token
    String? token = await getToken();
    if (token != null) {
      // Store token in Firestore
      await storeTokenInFirestore(token);
    }
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      storeTokenInFirestore(newToken);
    });
  }
}
```

#### 5.4.2 Storing Tokens per User in Firestore

```dart
Future<void> storeTokenInFirestore(String token) async {
  final user = AuthService().currentUser;
  if (user == null) return;
  
  await FirestoreService().users.doc(user.uid).update({
    'fcmToken': token,
    'fcmTokenUpdatedAt': FieldValue.serverTimestamp()
  });
}
```

**Updated User Schema:**

```json
{
  "fcmToken": "string (FCM registration token)",
  "fcmTokenUpdatedAt": "timestamp",
  // ... other user fields
}
```

#### 5.4.3 Handling Token Refresh

FCM tokens can expire or be refreshed. The app should:

1. **Listen for token refresh events**:
```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  storeTokenInFirestore(newToken);
});
```

2. **Periodically verify token validity**:
```dart
// Check token on app startup
Future<void> verifyAndUpdateToken() async {
  String? currentToken = await FirebaseMessaging.instance.getToken();
  final userDoc = await FirestoreService().users.doc(userId).get();
  final storedToken = userDoc.data()?['fcmToken'];
  
  if (currentToken != storedToken) {
    await storeTokenInFirestore(currentToken);
  }
}
```

#### 5.4.4 Not Sending Notifications to Logged-Out Users

**Strategy 1: Token Cleanup on Logout**

```dart
Future<void> signOut() async {
  // Clear FCM token from Firestore
  final user = AuthService().currentUser;
  if (user != null) {
    await FirestoreService().users.doc(user.uid).update({
      'fcmToken': FieldValue.delete()
    });
  }
  
  // Sign out from Firebase Auth
  await FirebaseAuth.instance.signOut();
}
```

**Strategy 2: Check User Status Before Sending**

In Cloud Functions:

```javascript
async function sendNotificationToUser(userId, message) {
  const userDoc = await admin.firestore().doc(`users/${userId}`).get();
  const user = userDoc.data();
  
  // Check if user has valid token and is logged in
  if (!user.fcmToken) {
    console.log(`User ${userId} has no FCM token, skipping notification`);
    return;
  }
  
  // Optional: Check last active timestamp
  const lastActive = user.lastActiveAt;
  const daysSinceActive = (Date.now() - lastActive.toMillis()) / (1000 * 60 * 60 * 24);
  if (daysSinceActive > 30) {
    console.log(`User ${userId} inactive for ${daysSinceActive} days, skipping`);
    return;
  }
  
  await admin.messaging().send({
    ...message,
    token: user.fcmToken
  });
}
```

### 5.5 Flutter Client Logic

#### 5.5.1 How Flutter Displays Notifications

**Current Implementation (Local Notifications):**

```dart
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = 
    FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }
  
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chorepal_channel',
      'ChorePal Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(id, title, body, details);
  }
}
```

**Future FCM Implementation:**

```dart
class FCMNotificationHandler {
  // Handle foreground messages
  static Future<void> handleForegroundMessage(RemoteMessage message) async {
    await NotificationService().showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'ChorePal',
      body: message.notification?.body ?? '',
    );
  }
  
  // Handle background messages
  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    // Show notification even when app is in background
    await NotificationService().showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'ChorePal',
      body: message.notification?.body ?? '',
    );
  }
  
  // Initialize FCM
  static Future<void> initialize() async {
    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check if app was opened from notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }
}
```

#### 5.5.2 Foreground vs Background Behavior

**Foreground (App Open):**

- Notifications are displayed as in-app banners/toasts
- User can interact immediately
- No system notification tray entry (optional)

**Background (App Minimized):**

- System notification appears in notification tray
- User can tap to open app
- Deep linking navigates to relevant screen

**Terminated (App Closed):**

- System notification appears
- Tapping opens app and triggers deep link
- App state is restored

#### 5.5.3 Notification Tap Navigation Flow (Deep Linking)

```dart
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final type = data['type'];
  
  switch (type) {
    case 'chore_assigned':
      final choreId = data['choreId'];
      Navigator.pushNamed(context, '/chores', arguments: {'choreId': choreId});
      break;
      
    case 'chore_completed':
      final choreId = data['choreId'];
      Navigator.pushNamed(context, '/chores', arguments: {'choreId': choreId});
      break;
      
    case 'chore_approved':
      final choreId = data['choreId'];
      Navigator.pushNamed(context, '/chores', arguments: {'choreId': choreId});
      break;
      
    case 'reward_available':
      Navigator.pushNamed(context, '/rewards');
      break;
      
    default:
      Navigator.pushNamed(context, '/home');
  }
}
```

**Deep Link Data Structure:**

```json
{
  "notification": {
    "title": "Chore Approved! ✅",
    "body": "Great job! You earned 10 points!"
  },
  "data": {
    "type": "chore_approved",
    "choreId": "chore_123",
    "points": "10"
  }
}
```

---

## 6. Sequence Diagrams

### 6.1 Parent Assigns Chore → Child Receives Notification

```
Parent                    Flutter App              Firestore              Child Device
  |                           |                        |                        |
  |--[Tap "Assign"]---------->|                        |                        |
  |                           |--[Update chore]------->|                        |
  |                           |  assignedTo: [childId] |                        |
  |                           |                        |                        |
  |                           |<--[Update success]-----|                        |
  |                           |                        |                        |
  |                           |--[Query child user]--->|                        |
  |                           |                        |                        |
  |                           |<--[Child data]---------|                        |
  |                           |                        |                        |
  |                           |--[Check preferences]-->|                        |
  |                           |                        |                        |
  |                           |<--[Preferences]--------|                        |
  |                           |                        |                        |
  |                           |--[Show notification]--------------------------->|
  |                           |                        |                        |
  |                           |                        |    [Notification appears]
```

### 6.2 Child Completes Chore → Parent Receives Notification

```
Child Device          Flutter App              Firestore              Parent Device
  |                      |                        |                        |
  |--[Tap "Complete"]-->|                        |                        |
  |                      |                        |                        |
  |                      |--[Update chore]------>|                        |
  |                      |  isPendingApproval:true|                        |
  |                      |  completedBy: childId  |                        |
  |                      |                        |                        |
  |                      |<--[Update success]-----|                        |
  |                      |                        |                        |
  |                      |--[Query parent]------->|                        |
  |                      |                        |                        |
  |                      |<--[Parent data]--------|                        |
  |                      |                        |                        |
  |                      |--[Check preferences]-->|                        |
  |                      |                        |                        |
  |                      |<--[Preferences]--------|                        |
  |                      |                        |                        |
  |                      |--[Show notification]--------------------------->|
  |                      |                        |                        |
  |                      |                        |    [Notification appears]
  |                      |                        |                        |
  |                      |                        |--[Tap notification]------>|
  |                      |                        |                        |
  |                      |                        |    [Navigate to chore]
```

### 6.3 Child Redeems Reward → Parent Gets Notification

```
Child Device          Flutter App              Firestore              Parent Device
  |                      |                        |                        |
  |--[Tap "Redeem"]---->|                        |                        |
  |                      |                        |                        |
  |                      |--[Check points]------->|                        |
  |                      |                        |                        |
  |                      |<--[Points data]--------|                        |
  |                      |                        |                        |
  |                      |--[Update reward]------>|                        |
  |                      |  isRedeemed: true     |                        |
  |                      |  redeemedBy: childId  |                        |
  |                      |                        |                        |
  |                      |--[Deduct points]------>|                        |
  |                      |  points: -pointsRequired|                        |
  |                      |                        |                        |
  |                      |<--[Update success]-----|                        |
  |                      |                        |                        |
  |                      |--[Query parent]------->|                        |
  |                      |                        |                        |
  |                      |<--[Parent data]--------|                        |
  |                      |                        |                        |
  |                      |--[Show notification]--------------------------->|
  |                      |                        |                        |
  |                      |                        |    [Notification appears]
```

### 6.4 Complete Chore Approval Flow (ASCII)

```
┌─────────┐      ┌──────────────┐      ┌──────────┐      ┌─────────┐
│  Child  │      │ Flutter App  │      │ Firestore│      │ Parent  │
└────┬────┘      └──────┬───────┘      └────┬─────┘      └────┬────┘
     │                  │                   │                 │
     │ Mark Complete   │                   │                 │
     │─────────────────>│                   │                 │
     │                  │                   │                 │
     │                  │ Update Chore     │                 │
     │                  │ isPendingApproval│                 │
     │                  │──────────────────>│                 │
     │                  │                   │                 │
     │                  │<──────────────────│                 │
     │                  │                   │                 │
     │                  │ Notify Parent    │                 │
     │                  │─────────────────────────────────────>│
     │                  │                   │                 │
     │                  │                   │   [Parent sees notification]
     │                  │                   │                 │
     │                  │                   │   [Parent taps "Approve"]
     │                  │                   │<────────────────│
     │                  │                   │                 │
     │                  │ Update Chore     │                 │
     │                  │ isCompleted: true │                 │
     │                  │──────────────────>│                 │
     │                  │                   │                 │
     │                  │ Award Points     │                 │
     │                  │ points += value   │                 │
     │                  │──────────────────>│                 │
     │                  │                   │                 │
     │                  │<──────────────────│                 │
     │                  │                   │                 │
     │                  │ Notify Child      │                 │
     │<─────────────────│                   │                 │
     │                  │                   │                 │
     │ [Child sees approval notification]    │                 │
```

---

## 7. Error Handling / Edge Cases

### 7.1 Missing FCM Tokens

**Problem**: User doesn't have an FCM token (new device, token not generated yet)

**Solution**:
- Check for token existence before sending notifications
- Gracefully degrade to email/SMS if token missing
- Retry token generation on app startup

```dart
Future<void> sendNotification(User user, String title, String body) async {
  // Try push notification first
  if (user.fcmToken != null && user.pushNotificationsEnabled) {
    try {
      await sendFCMNotification(user.fcmToken!, title, body);
      return;
    } catch (e) {
      print('FCM failed, falling back to email/SMS');
    }
  }
  
  // Fallback to email
  if (user.emailNotificationsEnabled && user is Parent) {
    await EmailService.sendEmail(user.email, title, body);
  }
  
  // Fallback to SMS
  if (user.smsNotificationsEnabled && user.phoneNumber != null) {
    await SMSService.sendSMS(user.phoneNumber!, '$title\n$body');
  }
}
```

### 7.2 Duplicate Notifications

**Problem**: Multiple notifications sent for the same event

**Causes**:
- Multiple Cloud Function triggers
- Client-side and server-side both sending
- Retry logic causing duplicates

**Solution**:
- Use idempotency keys in notification sending
- Track sent notifications in Firestore
- Debounce rapid Firestore updates

```dart
// Track sent notifications
final sentNotifications = <String>{};

Future<void> sendNotificationOnce(String eventId, User user, String title, String body) async {
  if (sentNotifications.contains(eventId)) {
    return; // Already sent
  }
  
  await sendNotification(user, title, body);
  sentNotifications.add(eventId);
  
  // Clear after 1 hour
  Future.delayed(Duration(hours: 1), () {
    sentNotifications.remove(eventId);
  });
}
```

### 7.3 Multiple Children in Same Family

**Problem**: Notifications sent to wrong child or all children

**Solution**:
- Always verify `assignedTo` array contains target child
- Filter notifications by child ID
- Use child-specific FCM tokens

```dart
// When assigning chore, only notify assigned children
for (final childId in chore.assignedTo) {
  final child = await getUserById(childId);
  if (child != null) {
    await sendNotificationToChild(child, 'New Chore', chore.title);
  }
}
```

### 7.4 Parent/Child Unlinking

**Problem**: Child removed from family but still receives notifications

**Solution**:
- Check `familyId` match before sending
- Remove FCM token on account deletion
- Clean up orphaned references

```dart
Future<void> removeChildFromFamily(String childId, String familyId) async {
  // Remove from family
  await families.doc(familyId).update({
    'childrenIds': FieldValue.arrayRemove([childId])
  });
  
  // Clear FCM token
  await users.doc(childId).update({
    'fcmToken': FieldValue.delete(),
    'familyId': '' // Or delete user document entirely
  });
}
```

### 7.5 Old Devices or Token Expiration

**Problem**: FCM token expired or device no longer in use

**Solution**:
- Listen for token refresh events
- Handle FCM send errors (invalid token)
- Clean up expired tokens

```javascript
// In Cloud Function
try {
  await admin.messaging().send(message);
} catch (error) {
  if (error.code === 'messaging/invalid-registration-token' ||
      error.code === 'messaging/registration-token-not-registered') {
    // Token is invalid, remove it
    await admin.firestore().doc(`users/${userId}`).update({
      fcmToken: FieldValue.delete()
    });
  }
}
```

### 7.6 Network Failures

**Problem**: Notification send fails due to network issues

**Solution**:
- Implement retry logic with exponential backoff
- Queue notifications for offline devices
- Use Firestore as notification queue

```dart
class NotificationQueue {
  final CollectionReference queue = 
    FirebaseFirestore.instance.collection('notification_queue');
  
  Future<void> queueNotification(String userId, Map<String, dynamic> data) async {
    await queue.add({
      'userId': userId,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending'
    });
  }
  
  // Process queue (can be done by Cloud Function)
}
```

---

## 8. Future Expansion Ideas

### 8.1 In-App Messaging Between Parent/Child

**Concept**: Direct messaging feature within the app

**Implementation**:
- New Firestore collection: `/messages/{messageId}`
- Real-time listeners for new messages
- Push notifications for new messages
- Message threads per family

**Schema**:
```json
{
  "fromUserId": "string",
  "toUserId": "string",
  "familyId": "string",
  "message": "string",
  "read": "boolean",
  "createdAt": "timestamp"
}
```

### 8.2 Weekly Summary Notifications

**Concept**: Automated weekly progress reports

**Implementation**:
- Scheduled Cloud Function (runs every Sunday)
- Aggregates chore completion data
- Generates summary statistics
- Sends to both parent and child

**Content**:
- Total chores completed
- Points earned
- Streak maintained
- Rewards redeemed
- Comparison to previous week

### 8.3 Automated Reminders

**Concept**: Smart reminders for overdue or upcoming chores

**Implementation**:
- Scheduled Cloud Function checking chore deadlines
- Configurable reminder intervals (e.g., 24h, 6h, 1h before deadline)
- Personalized reminder messages

**Example**:
```javascript
exports.choreReminder = functions.pubsub
  .schedule('0 */6 * * *') // Every 6 hours
  .onRun(async (context) => {
    // Find chores due in next 6 hours
    // Send reminder notifications
  });
```

### 8.4 Gamification Extensions

**Additional Features**:

1. **Achievement Badges**
   - "First Chore" badge
   - "Week Warrior" (7 days streak)
   - "Point Master" (1000 points)
   - Badge collection display

2. **Leaderboard Enhancements**
   - Weekly/monthly/all-time rankings
   - Category-based leaderboards (chores, points, streaks)
   - Family vs. family competitions

3. **Challenges**
   - Parent-created challenges (e.g., "Complete 10 chores this week")
   - Bonus points for challenge completion
   - Challenge progress tracking

4. **Level System**
   - Level up based on total points
   - Unlock new features at higher levels
   - Visual level indicators

5. **Social Features**
   - Share achievements on social media
   - Family photo gallery
   - Celebration animations

### 8.5 Advanced Notification Features

1. **Notification Scheduling**
   - Parent can schedule reminder notifications
   - Custom notification times per child
   - Quiet hours support

2. **Notification Preferences per Event Type**
   - Separate toggles for each notification type
   - Custom notification sounds
   - Priority levels

3. **Notification History**
   - View past notifications
   - Mark as read/unread
   - Search and filter

4. **Batch Notifications**
   - Group multiple events into single notification
   - "You have 3 chores due today"
   - Reduce notification fatigue

### 8.6 Analytics and Insights

**Parent Dashboard Enhancements**:

- **Completion Trends**: Charts showing completion rates over time
- **Child Performance**: Individual child statistics and comparisons
- **Reward Effectiveness**: Track which rewards motivate most
- **Time Analysis**: Average time to complete chores
- **Predictive Insights**: Suggest optimal chore assignments

### 8.7 Multi-Family Support

**Concept**: Support for extended families or shared custody

**Features**:
- Child can belong to multiple families
- Separate point balances per family
- Family switching interface
- Unified dashboard view

### 8.8 Integration with Smart Home Devices

**Concept**: Connect with IoT devices for automated chore verification

**Examples**:
- Dishwasher completion detected → Auto-approve "Load dishwasher" chore
- Trash bin sensor → Auto-approve "Take out trash" when detected
- Room cleaning robot → Verify "Clean room" completion

---

## Appendix: Key Code References

### Authentication Service
- **File**: `lib/services/auth_service.dart`
- **Key Methods**: `signInWithEmailAndPassword()`, `registerWithEmailAndPassword()`, `signOut()`

### Firestore Service
- **File**: `lib/services/firestore_service.dart`
- **Key Methods**: `createParentProfile()`, `createChildProfile()`, `addChore()`, `updateChore()`

### Notification Helper
- **File**: `lib/widgets/notification_helper.dart`
- **Key Methods**: `showChoreCompletedByChildNotification()`, `showChoreApprovedNotification()`

### Cloud Functions
- **Email**: `functions/email.js` (SendGrid integration)
- **SMS**: `functions/sms.js` (Twilio integration)

### Models
- **User**: `lib/models/user.dart` (Parent/Child classes)
- **Chore**: `lib/models/chore.dart`
- **Reward**: `lib/models/reward.dart`

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Maintained By**: ChorePal Development Team

