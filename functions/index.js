const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const sgMail = require("@sendgrid/mail");

setGlobalOptions({region: "us-central1", secrets: ["SENDGRID_API_KEY"]});

exports.sendEmail = onCall(async (request) => {
  const apiKey = process.env.SENDGRID_API_KEY;
  if (!apiKey) {
    console.error("Missing SENDGRID_API_KEY secret");
    throw new HttpsError("failed-precondition", "API key not available");
  }

  sgMail.setApiKey(apiKey);

  const msg = {
    to: request.data.to,
    from: "support@em615.chorepals.app", // must be verified
    subject: request.data.subject,
    text: request.data.message,
  };

  try {
    const [response] = await sgMail.send(msg);
    console.log("SendGrid response status:", response.statusCode);
    console.log("SendGrid response body:", response.body);
    return {success: true};
  } catch (error) {
    let message = "Unknown error";
    if (error.response && error.response.body) {
      try {
        message = JSON.stringify(error.response.body);
      } catch (e) {
        message = String(error.response.body);
      }
      console.error("SendGrid error:", message);
    } else {
      message = error.message || String(error);
      console.error("SendGrid error:", message);
    }

    throw new HttpsError("internal", message);
  }
});
