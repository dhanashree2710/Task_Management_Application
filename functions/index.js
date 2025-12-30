const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushNotification = functions.https.onCall(
  async (data, context) => {
    const message = {
      token: data.token,
      notification: {
        title: data.title,
        body: data.body,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "task_channel",
          sound: "notification",
        },
      },
      data: {
        ...data.payload,
      },
    };

    await admin.messaging().send(message);
    return { success: true };
  }
);
