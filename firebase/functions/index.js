const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const bucket = admin.storage().bucket();

/**
 * Scheduled Cloud Function running every hour.
 * Inspects pairings, calculates expired files based on their custom schedules (24h, 3d, 7d),
 * and permanently purges them from both Firebase Storage and Firestore.
 */
exports.autoCleanupExpiredFiles = onSchedule("every 1 hours", async (event) => {
  console.log("Starting QuickBridge automated file cleanup sweep...");
  
  try {
    const pairingsSnapshot = await db.collection("pairings").get();
    
    if (pairingsSnapshot.empty) {
      console.log("No active pairing sessions found.");
      return;
    }

    const now = new Date();
    let totalDeletedFiles = 0;

    for (const pairingDoc of pairingsSnapshot.docs) {
      const pairingData = pairingDoc.data();
      const pairId = pairingDoc.id;
      const cleanupHours = pairingData.cleanupHours;

      // Skip if cleanup config is set to null (Never) or is undefined
      if (cleanupHours === null || cleanupHours === undefined) {
        continue;
      }

      // Calculate expiration threshold
      const thresholdTime = new Date(now.getTime() - cleanupHours * 60 * 60 * 1000);
      
      // Get expired file documents
      const expiredFilesSnapshot = await db
        .collection("pairings")
        .doc(pairId)
        .collection("transfers")
        .where("uploadTime", "<", thresholdTime)
        .get();

      if (expiredFilesSnapshot.empty) {
        continue;
      }

      console.log(`Found ${expiredFilesSnapshot.size} expired files in session ${pairId}`);

      for (const fileDoc of expiredFilesSnapshot.docs) {
        const fileData = fileDoc.data();
        const fileId = fileDoc.id;
        const storagePath = fileData.storagePath;

        if (storagePath) {
          try {
            // 1. Delete from Firebase Storage
            await bucket.file(storagePath).delete();
            console.log(`Deleted file storage asset: ${storagePath}`);
          } catch (storageError) {
            // Ignore error if file doesn't exist anymore on Storage
            if (storageError.code !== 404) {
              console.error(`Failed to delete storage file ${storagePath}:`, storageError);
            }
          }
        }

        // 2. Delete Firestore metadata record
        await db
          .collection("pairings")
          .doc(pairId)
          .collection("transfers")
          .doc(fileId)
          .delete();

        console.log(`Deleted Firestore metadata record: pairings/${pairId}/transfers/${fileId}`);
        totalDeletedFiles++;
      }
    }

    console.log(`QuickBridge auto-cleanup completed. Purged ${totalDeletedFiles} files.`);
  } catch (error) {
    console.error("Error running auto-cleanup Cloud Function:", error);
  }
});
