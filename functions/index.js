const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// 🔥 Function تشتغل تلقائياً كل يوم الساعة 9 صباحاً
exports.sendDailyVaccineReminders = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('Asia/Jerusalem')
  .onRun(async (context) => {
    try {
      const db = admin.firestore();
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      console.log(`🔍 جاري البحث عن مواعيد التطعيم لتاريخ: ${today.toISOString()}`);

      // جيب كل المستخدمين (الأطفال)
      const usersSnapshot = await db.collection('users').get();

      if (usersSnapshot.empty) {
        console.log('⚠️ لا يوجد مستخدمين');
        return null;
      }

      let totalReminders = 0;
      let sentSuccessfully = 0;

      // لكل مستخدم (طفل)
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        console.log(`👤 فحص مستخدم: ${userData.name || userId}`);

        // جيب كل التطعيمات لهذا الطفل
        const vaccinesSnapshot = await db
          .collection('users')
          .doc(userId)
          .collection('medical_dates')
          .where('state', '==', 'pending') // فقط التطعيمات المنتظرة
          .get();

        if (vaccinesSnapshot.empty) {
          console.log(`  ℹ️ لا يوجد تطعيمات منتظرة لـ ${userData.name}`);
          continue;
        }

        // افحص كل تطعيم
        for (const vaccineDoc of vaccinesSnapshot.docs) {
          const vaccineData = vaccineDoc.data();

          // تحقق من وجود data (التاريخ)
          if (!vaccineData.data) {
            console.log(`  ⚠️ لا يوجد تاريخ للتطعيم: ${vaccineData.name}`);
            continue;
          }

          // حول التاريخ من String إلى Date
          const vaccineDate = new Date(vaccineData.data);
          vaccineDate.setHours(0, 0, 0, 0);

          // تحقق إذا الموعد غداً
          if (vaccineDate.getTime() === tomorrow.getTime()) {
            const fcmToken = userData.fcmToken;

            if (!fcmToken) continue;

            const message = {
              notification: {
                title: '📅 تذكير مسبق: موعد تطعيم غداً',
                body: `${userData.name}، غداً موعد تطعيم ${vaccineData.name}. استعد للذهاب للمركز الصحي!`,
              },
              data: {
                userId: userId,
                vaccineId: vaccineDoc.id,
                type: 'advance_reminder',
              },
              token: fcmToken,
            };

            try {
              await admin.messaging().send(message);
              console.log(`  ✅ تذكير مسبق لـ ${userData.name}`);
              totalSent++;
            } catch (error) {
              console.error(`  ❌ فشل التذكير المسبق:`, error.code);
            }
          }
        }
      }

      console.log(`📊 تم إرسال ${totalSent} تذكير مسبق`);
      return { success: true, totalSent: totalSent };

    } catch (error) {
      console.error('❌ خطأ:', error);
      return { success: false, error: error.message };
    }
  });