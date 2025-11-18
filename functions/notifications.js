const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");
const twilio = require("twilio");

// Note: setGlobalOptions is already called in email.js and sms.js
// We'll set options per-function instead to avoid the warning

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Send FCM notification to a user
 * @param {string} userId - The user ID to send notification to
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Optional data payload for deep linking
 */
exports.sendNotification = onCall(
  {
    region: "us-central1",
    secrets: ["SENDGRID_API_KEY", "TWILIO_SID", "TWILIO_TOKEN", "TWILIO_NUMBER"],
  },
  async (request) => {
    console.log("=== sendNotification triggered ===");
    
    const {userId, title, body, data} = request.data || {};
    
    if (!userId || !title || !body) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required fields: userId, title, body"
      );
    }

    try {
      // Get user document from Firestore
      const userDoc = await admin.firestore().doc(`users/${userId}`).get();
      
      if (!userDoc.exists) {
        throw new HttpsError("not-found", "User not found");
      }

      const userData = userDoc.data();
      
      // Check if push notifications are enabled
      if (!userData.pushNotificationsEnabled) {
        console.log(`Push notifications disabled for user ${userId}`);
        return {success: false, reason: "Push notifications disabled"};
      }

      // Get FCM token
      const fcmToken = userData.fcmToken;
      
      if (!fcmToken) {
        console.log(`No FCM token for user ${userId}`);
        return {success: false, reason: "No FCM token"};
      }

      // Prepare message
      const message = {
        notification: {
          title: title,
          body: body,
        },
        token: fcmToken,
      };

      // Add data payload if provided (for deep linking)
      if (data) {
        message.data = {};
        // Convert all data values to strings (FCM requirement)
        for (const [key, value] of Object.entries(data)) {
          message.data[key] = String(value);
        }
      }

      // Send notification
      const response = await admin.messaging().send(message);
      console.log("FCM notification sent successfully:", response);
      
      return {success: true, messageId: response};
    } catch (error) {
      console.error("Error sending FCM notification:", error);
      
      // Handle invalid token errors
      if (error.code === "messaging/invalid-registration-token" ||
          error.code === "messaging/registration-token-not-registered") {
        // Remove invalid token from Firestore
        try {
          await admin.firestore().doc(`users/${userId}`).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
          console.log(`Removed invalid FCM token for user ${userId}`);
        } catch (updateError) {
          console.error("Error removing invalid token:", updateError);
        }
      }
      
      throw new HttpsError("internal", error.message || "Failed to send notification");
    }
  }
);

/**
 * Helper function to send notification to a user
 * Handles FCM, email, and SMS based on user preferences
 */
async function sendNotificationToUser(userId, title, body, data = null) {
  try {
    const userDoc = await admin.firestore().doc(`users/${userId}`).get();
    if (!userDoc.exists) {
      console.log(`User ${userId} not found`);
      return;
    }

    const userData = userDoc.data();

    // Send FCM notification if enabled
    if (userData.pushNotificationsEnabled && userData.fcmToken) {
      try {
        const message = {
          notification: {title, body},
          token: userData.fcmToken,
        };
        if (data) {
          message.data = {};
          for (const [key, value] of Object.entries(data)) {
            message.data[key] = String(value);
          }
        }
        await admin.messaging().send(message);
        console.log(`FCM notification sent to user ${userId}`);
      } catch (error) {
        console.error(`Error sending FCM to user ${userId}:`, error);
        // Remove invalid token
        if (error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/registration-token-not-registered") {
          await admin.firestore().doc(`users/${userId}`).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
        }
      }
    }

    // Send email if enabled (only for parents)
    if (userData.emailNotificationsEnabled && userData.isParent && userData.email) {
      try {
        const apiKey = process.env.SENDGRID_API_KEY;
        if (apiKey) {
          sgMail.setApiKey(apiKey);
          const msg = {
            to: userData.email,
            from: "support@em615.chorepals.app",
            subject: title,
            text: body,
          };
          await sgMail.send(msg);
          console.log(`Email sent to user ${userId}`);
        }
      } catch (error) {
        console.error(`Error sending email to user ${userId}:`, error);
      }
    }

    // Send SMS if enabled (only for parents with phone)
    if (userData.smsNotificationsEnabled && userData.isParent && userData.phoneNumber) {
      try {
        const sid = process.env.TWILIO_SID;
        const token = process.env.TWILIO_TOKEN;
        const fromNumber = process.env.TWILIO_NUMBER;
        
        if (sid && token && fromNumber) {
          const client = twilio(sid, token);
          await client.messages.create({
            body: `${title}\n${body}`,
            from: fromNumber,
            to: userData.phoneNumber,
          });
          console.log(`SMS sent to user ${userId}`);
        }
      } catch (error) {
        console.error(`Error sending SMS to user ${userId}:`, error);
      }
    }
  } catch (error) {
    console.error(`Error in sendNotificationToUser for ${userId}:`, error);
  }
}

/**
 * Firestore trigger: When a chore is created and assigned to children
 */
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

exports.onChoreCreated = onDocumentCreated(
  {
    document: "chores/{choreId}",
    region: "us-central1",
    secrets: ["SENDGRID_API_KEY", "TWILIO_SID", "TWILIO_TOKEN", "TWILIO_NUMBER"],
  },
  async (event) => {
    // Log immediately to verify function is triggered
    console.log(`[onChoreCreated] FUNCTION TRIGGERED - Event received`);
    console.log(`[onChoreCreated] Event params:`, JSON.stringify(event.params));
    console.log(`[onChoreCreated] Event data exists:`, !!event.data);
    
    try {
      const chore = event.data.data();
      const choreId = event.params.choreId;

      console.log(`[onChoreCreated] Chore created: ${choreId}`);
      console.log(`[onChoreCreated] Chore data:`, JSON.stringify(chore));

      // Notify all assigned children
      if (chore.assignedTo && Array.isArray(chore.assignedTo) && chore.assignedTo.length > 0) {
        console.log(`[onChoreCreated] Notifying ${chore.assignedTo.length} children`);
        for (const childId of chore.assignedTo) {
          try {
            await sendNotificationToUser(
              childId,
              "New Chore Assigned 📝",
              `You have a new chore: "${chore.title}"`,
              {
                type: "chore_assigned",
                choreId: choreId,
              }
            );
            console.log(`[onChoreCreated] Notification sent to child: ${childId}`);
          } catch (error) {
            console.error(`[onChoreCreated] Error sending notification to child ${childId}:`, error);
          }
        }
      } else {
        console.log(`[onChoreCreated] No children assigned to chore ${choreId}`);
      }
    } catch (error) {
      console.error(`[onChoreCreated] Error processing chore creation:`, error);
      throw error;
    }
  }
);

/**
 * Firestore trigger: When a chore is updated
 */
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");

exports.onChoreUpdated = onDocumentUpdated(
  {
    document: "chores/{choreId}",
    region: "us-central1",
    secrets: ["SENDGRID_API_KEY", "TWILIO_SID", "TWILIO_TOKEN", "TWILIO_NUMBER"],
  },
  async (event) => {
    // Log immediately to verify function is triggered
    console.log(`[onChoreUpdated] FUNCTION TRIGGERED - Event received`);
    console.log(`[onChoreUpdated] Event params:`, JSON.stringify(event.params));
    console.log(`[onChoreUpdated] Event data exists:`, !!event.data);
    
    try {
      const before = event.data.before.data();
      const after = event.data.after.data();
      const choreId = event.params.choreId;

      console.log(`[onChoreUpdated] Chore updated: ${choreId}`);
      console.log(`[onChoreUpdated] Before:`, JSON.stringify(before));
      console.log(`[onChoreUpdated] After:`, JSON.stringify(after));

    // Check if chore was just assigned to new children
    const beforeAssigned = new Set(before.assignedTo || []);
    const afterAssigned = new Set(after.assignedTo || []);
    const newlyAssigned = [...afterAssigned].filter((id) => !beforeAssigned.has(id));

    if (newlyAssigned.length > 0) {
      console.log(`[onChoreUpdated] ${newlyAssigned.length} newly assigned children detected`);
      for (const childId of newlyAssigned) {
        try {
          await sendNotificationToUser(
            childId,
            "New Chore Assigned 📝",
            `You have a new chore: "${after.title}"`,
            {
              type: "chore_assigned",
              choreId: choreId,
            }
          );
          console.log(`[onChoreUpdated] Assignment notification sent to child: ${childId}`);
        } catch (error) {
          console.error(`[onChoreUpdated] Error sending assignment notification to ${childId}:`, error);
        }
      }
    }

    // Check if chore was just completed (moved to pending approval)
    if (!before.isPendingApproval && after.isPendingApproval === true && after.completedBy) {
      console.log(`[onChoreUpdated] Chore marked as pending approval by child: ${after.completedBy}`);
      const childId = after.completedBy;
      const familyId = after.familyId;

      if (!familyId) {
        console.error(`[onChoreUpdated] No familyId found for chore ${choreId}`);
        // Don't return - continue to check for other state changes
      } else {
        // Get child info
        const childDoc = await admin.firestore().doc(`users/${childId}`).get();
        const child = childDoc.exists ? childDoc.data() : null;

        // Get parent from family
        const familyDoc = await admin.firestore().doc(`families/${familyId}`).get();
        if (familyDoc.exists) {
          const family = familyDoc.data();
          // Families have parentIds array, notify all parents
          const parentIds = family.parentIds || [];
          
          if (parentIds.length === 0) {
            console.error(`[onChoreUpdated] No parentIds found in family ${familyId}`);
            // Don't return - continue to check for other state changes
          } else {
            console.log(`[onChoreUpdated] Notifying ${parentIds.length} parents`);
            for (const parentId of parentIds) {
              try {
                await sendNotificationToUser(
                  parentId,
                  "Chore Completed! 📋",
                  `${child?.name || "Your child"} completed "${after.title}" and is waiting for your approval.`,
                  {
                    type: "chore_completed",
                    choreId: choreId,
                    childId: childId,
                  }
                );
                console.log(`[onChoreUpdated] Completion notification sent to parent: ${parentId}`);
              } catch (error) {
                console.error(`[onChoreUpdated] Error sending completion notification to parent ${parentId}:`, error);
              }
            }
          }
        } else {
          console.error(`[onChoreUpdated] Family document ${familyId} not found`);
        }
      }
    }

    // Check if chore was just approved (moved from pending to completed)
    if (before.isPendingApproval === true && 
        after.isPendingApproval === false && 
        after.isCompleted === true &&
        after.completedBy) {
      console.log(`[onChoreUpdated] Chore approved for child: ${after.completedBy}`);
      const childId = after.completedBy;

      try {
        await sendNotificationToUser(
          childId,
          "Chore Approved! ✅",
          `Great job! "${after.title}" was approved. You earned ${after.pointValue || 0} points!`,
          {
            type: "chore_approved",
            choreId: choreId,
            points: String(after.pointValue || 0),
          }
        );
        console.log(`[onChoreUpdated] Approval notification sent to child: ${childId}`);
      } catch (error) {
        console.error(`[onChoreUpdated] Error sending approval notification to child ${childId}:`, error);
      }
    }
    } catch (error) {
      console.error(`[onChoreUpdated] Error processing chore update:`, error);
      throw error;
    }
  }
);

