const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendVaccinationReminder = functions.https.onCall(
    async (data, context) => {
        const { fcmToken, title, body } = data;

        if (!fcmToken || !title || !body) {
            return { success: false, error: "Missing required parameters" };
        }

        try {
            const message = {
                notification: { title, body },
                token: fcmToken,
            };

            const response = await admin.messaging().send(message);
            console.log("Successfully sent message:", response);

            return { success: true, messageId: response };
        } catch (e) {
            console.error("Error sending message:", e);
            return { success: false, error: e.message };
        }
    },
);
