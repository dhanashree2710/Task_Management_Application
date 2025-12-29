const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushNotification = functions.https.onCall(async (data) => {
  const { token, title, body, payload } = data;

  await admin.messaging().send({
    token,
    notification: {
      title,
      body,
    },
    data: payload ?? {},
    android: {
      priority: "high",
      notification: {
        channelId: "task_channel",
        sound: "default",
      },
    },
  });

  return { success: true };
});


// Optional: Scheduled deadline reminders
exports.deadlineReminder = functions.pubsub.schedule('every 1 hours').onRun(async () => {
  const tasks = await admin.firestore().collection('tasks')
      .where('status', '==', 'assigned')
      .get();
  const now = new Date();
  tasks.forEach(async (doc) => {
    const deadline = doc.data().deadline.toDate();
    if ((deadline - now)/3600000 <= 2) { // 2 hours before
      const user = await admin.firestore().collection('users').doc(doc.data().assigned_to).get();
      await admin.messaging().send({
        token: user.data().fcm_token,
        notification: {title: "Task Deadline Reminder", body: doc.data().title}
      });
    }
  });
});
