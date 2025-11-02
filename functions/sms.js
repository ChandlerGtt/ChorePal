const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const twilio = require("twilio");

// configure global region and secrets
setGlobalOptions({
  region: "us-central1",
  secrets: ["TWILIO_SID", "TWILIO_TOKEN", "TWILIO_NUMBER"],
});

exports.sms = onCall(async (request) => {
  const sid = process.env.TWILIO_SID;
  const token = process.env.TWILIO_TOKEN;
  const fromNumber = process.env.TWILIO_NUMBER;

  if (!sid || !token || !fromNumber) {
    console.error("Missing Twilio credentials");
    throw new HttpsError("failed-precondition", "Twilio credentials missing");
  }

  const {to, message} = request.data || {};
  if (!to || !message) {
    throw new HttpsError("invalid-argument", "Missing 'to' or 'message' field");
  }

  const client = twilio(sid, token);

  try {
    const result = await client.messages.create({
      body: message,
      from: fromNumber,
      to: to, // must be in +15551234567 format
    });

    console.log("SMS sent successfully:", result.sid);
    return {success: true, sid: result.sid};
  } catch (error) {
    console.error("Twilio error:", error);
    throw new HttpsError("internal", error.message || "Failed to send SMS");
  }
});
