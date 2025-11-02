const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const sgMail = require("@sendgrid/mail");

setGlobalOptions({
  region: "us-central1",
  secrets: ["SENDGRID_API_KEY"],
});

exports.email = onCall(async (request) => {
  console.log("=== sendEmail triggered ===");
  const apiKey = process.env.SENDGRID_API_KEY;
  if (!apiKey) {
    console.error("Missing SENDGRID_API_KEY secret");
    throw new HttpsError("failed-precondition", "SendGrid API key missing");
  }

  sgMail.setApiKey(apiKey);

  const {to, subject, message} = request.data || {};
  if (!to || !subject || !message) {
    throw new HttpsError("invalid-argument", "Missing required fields");
  }

  try {
    const msg = {to,
      from: "support@em615.chorepals.app",
      subject,
      text: message};

    const [response] = await sgMail.send(msg);
    console.log("Email sent:", response.statusCode);
    return {success: true};
  } catch (error) {
    console.error("SendGrid error:", JSON.stringify(error, null, 2));
    throw new HttpsError("internal", error.message || "Email send failed");
  }
});
