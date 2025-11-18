# Cloud Functions Troubleshooting Guide

## Why Cloud Functions Might Not Be Triggering

### 1. **Check Function Deployment**
```bash
# Verify functions are deployed
firebase functions:list

# Check function logs
firebase functions:log

# View specific function logs
firebase functions:log --only onChoreCreated
firebase functions:log --only onChoreUpdated
```

### 2. **Verify Firestore Document Path**
- Functions listen to: `chores/{choreId}`
- Make sure chores are created in the `chores` collection (not `chore` or `task`)
- Check Firebase Console → Firestore → Data to verify document structure

### 3. **Check Function Region**
- Functions are set to `region: "us-central1"`
- Firestore should be in the same region or compatible
- Check Firebase Console → Project Settings → General

### 4. **Verify Billing Plan**
- Cloud Functions require **Blaze (pay-as-you-go) plan**
- Free Spark plan doesn't support Cloud Functions
- Check: Firebase Console → Usage and billing

### 5. **Check Firestore Security Rules**
- Functions need permission to read/write Firestore
- Verify rules allow the operations that trigger functions
- Check: Firebase Console → Firestore → Rules

### 6. **Verify Document Structure**
Functions expect:
- `chore.assignedTo` - array of child IDs (can be empty)
- `chore.title` - string
- `chore.familyId` - string (for parent notifications)
- `chore.isPendingApproval` - boolean
- `chore.isCompleted` - boolean
- `chore.completedBy` - string (child ID)

### 7. **Check Function Logs for Errors**
```bash
# View all function logs
firebase functions:log

# View logs in Firebase Console
# Go to: Firebase Console → Functions → Logs
```

### 8. **Test Function Manually**
```bash
# Test the sendNotification function
firebase functions:shell
# Then in the shell:
sendNotification({userId: "test_user_id", title: "Test", body: "Test message"})
```

### 9. **Common Issues**

#### Issue: Functions trigger but notifications don't send
- Check if users have `fcmToken` in their Firestore document
- Check if `pushNotificationsEnabled: true` in user document
- Check function logs for errors

#### Issue: Functions don't trigger at all
- Verify functions are deployed: `firebase functions:list`
- Check if billing is enabled (Blaze plan)
- Verify document path matches trigger path exactly
- Check Firestore security rules

#### Issue: onChoreCreated doesn't fire
- Chore must be created with `assignedTo` array (can be empty, but must exist)
- Check if chore document is actually created in Firestore
- Verify the collection name is exactly `chores`

#### Issue: onChoreUpdated doesn't fire
- Any update to the chore document should trigger it
- Check if the update is actually happening in Firestore
- Verify the document ID matches the trigger pattern

### 10. **Debug Steps**

1. **Create a test chore** and check Firebase Console → Firestore → Data
2. **Check function logs** immediately after creating/updating
3. **Verify function is deployed**: `firebase functions:list`
4. **Check billing**: Firebase Console → Usage and billing
5. **Test with minimal data**: Create a chore with just `title` and `assignedTo: []`

### 11. **Manual Testing**

Add this test function to verify functions are working:

```javascript
// In functions/notifications.js
exports.testNotification = onCall(async (request) => {
  const {userId} = request.data;
  await sendNotificationToUser(
    userId,
    "Test Notification",
    "If you see this, Cloud Functions are working!"
  );
  return {success: true};
});
```

Then call it from your app to test if functions can send notifications.

