const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentCreated} = require("firebase-functions/v2/firestore"); // استيراد onDocumentCreated
const admin = require("firebase-admin");
admin.initializeApp();

console.log("Path to firebase-functions:", require.resolve("firebase-functions"));

/**
 * وظيفة مجدولة تعمل بشكل دوري للتحقق من جداول أدوية المرضى وإرسال تذكيرات (الجيل الثاني).
 */
exports.scheduledMedicineReminders = onSchedule("* * * * *", async (event) => {
  const currentTime = new Date();
  const currentHour = currentTime.getHours();
  const currentMinute = currentTime.getMinutes();
  const currentDate = new Date(currentTime.getFullYear(),
      currentTime.getMonth(), currentTime.getDate()); // تاريخ اليوم بدون الوقت

  console.log(`Running scheduled medicine reminders at ${currentTime.toISOString()}`);

  try {
    // استرداد جميع المرضى النشطين من قاعدة البيانات
    const activePatientsSnapshot = await admin.firestore().collection("ActivePatient").get();

    for (const patientDoc of activePatientsSnapshot.docs) {
      const patientData = patientDoc.data();
      const deviceToken = patientData.deviceToken;
      const patientId = patientDoc.id;

      if (deviceToken) {
        // استرداد أدوية المريض من المجموعة الفرعية PatientMedicine
        const patientMedicinesSnapshot = await admin
            .firestore()
            .collection("ActivePatient")
            .doc(patientId)
            .collection("PatientMedicine")
            .get();

        for (const medicineDoc of patientMedicinesSnapshot.docs) {
          const medication = medicineDoc.data();
          const {MedicineName, MedicineTime, StartDate,
            EndDate, NumberOfPillsPerDose} = medication;

          if (MedicineName && Array.isArray(MedicineTime) && StartDate && EndDate) {
            const startDate = StartDate.toDate();
            const endDate = EndDate.toDate();
            const medicineStartDate = new Date(startDate.getFullYear(),
                startDate.getMonth(), startDate.getDate());
            const medicineEndDate = new Date(endDate.getFullYear(),
                endDate.getMonth(), endDate.getDate());

            // التحقق ما إذا كان التاريخ الحالي يقع ضمن فترة تناول الدواء
            if (currentDate >= medicineStartDate && currentDate <= medicineEndDate) {
              for (const time of MedicineTime) {
                const [hourStr, minuteStr] = time.split(":");
                const medicineHour = parseInt(hourStr, 10);
                const medicineMinute = parseInt(minuteStr, 10);

                // التحقق ما إذا كان الوقت الحالي هو وقت تناول الدواء
                if (medicineHour === currentHour && medicineMinute === currentMinute) {
                  const message = {
                    notification: {
                      title: "تذكير بالدواء",
                      body: `حان وقت تناول دواءك: ${MedicineName}. عدد الحبوب:
                       ${NumberOfPillsPerDose || "غير محدد"}`,
                    },
                    token: deviceToken,
                  };

                  try {
                    // إرسال الإشعار للمريض
                    await admin.messaging().send(message);
                    console.log(`Successfully sent reminder for ${MedicineName}
                       at ${time} to ${deviceToken}`);

                    // تخزين الإشعار في Firestore
                    // const notificationData = {
                    //   patientId: patientId,
                    //   medicineName: MedicineName,
                    //   reminderTime: `${medicineHour}:${medicineMinute}`,
                    //   message: `حان وقت تناول دواءك: ${MedicineName}
                    //   . عدد الحبوب: ${NumberOfPillsPerDose || "غير محدد"}`,
                    //   notificationTime: admin.firestore.FieldValue.serverTimestamp(),
                    //   status: "sent",
                    // };

                    // إضافة الإشعار إلى Firestore
                    // await admin.firestore().collection("medicine_notifications")
                    //     .add(notificationData);
                    // console.log(`Successfully saved notification for ${MedicineName}
                    //    at ${time} in Firestore.`);
                  } catch (error) {
                    console.error(`Error sending for ${MedicineName}
                       at ${time} to ${deviceToken}:`, error);
                  }
                }
              }
            } else {
              console.log(`Skipping ${MedicineName} for patient
                 ${patientId} as it's outside the date range.`);
            }
          } else {
            console.warn(`Skipping medication for patient ${patientId}
               due to missing or invalid data.`);
          }
        }
      } else {
        console.warn(`Skipping patient ${patientId} due to missing deviceToken.`);
      }
    }

    console.log("Finished processing medicine reminders.");
    return null;
  } catch (error) {
    console.error("Error during scheduled medicine reminders:", error);
    return null;
  }
});

exports.sendNotificationOnNewSentNotification = onDocumentCreated(
    "SentNotifications/{notificationId}", async (event) => {
      const snapshot = event.data;
      if (!snapshot) {
        console.log("No data associated with the event");
        return;
      }
      const notificationData = snapshot.data();
      const patientId = notificationData.patientId;
      const message = notificationData.message;
      const category = notificationData.category;

      console.log(`New notification created for patient: ${patientId} in category: ${category}`);

      try {
      // 1. استرداد رمز جهاز المريض من مجموعة ActivePatient
        const patientDoc = await admin.firestore()
            .collection("ActivePatient")
            .doc(patientId)
            .get();

        let deviceToken = null;
        const patientData = patientDoc.data();
        if (patientData) {
          deviceToken = patientData.deviceToken;
        }

        if (!deviceToken) {
          console.log(`Device token not found for patient: ${patientId}`);
          return null; // لا يوجد رمز جهاز، لا يمكن إرسال الإشعار
        }

        const title = category === "education" ? "New Educational Content" : "Appointment Reminder";
        const payload = {
          notification: {
            title: title,
            body: message,
          },
          // يمكنك إضافة بيانات مخصصة هنا إذا كنت بحاجة إليها
          // data: { key: 'value' },
          token: deviceToken,
        };

        // 2. إرسال إشعار FCM
        const response = await admin.messaging().send(payload);
        console.log("Successfully sent message:", response);
        return null;
      } catch (error) {
        console.error("Error sending message:", error);
        return null;
      }
    });
