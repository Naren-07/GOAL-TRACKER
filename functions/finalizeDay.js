const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Scheduler cron triggered every 15 minutes.
 * Processes unfinalized day logs whose 10:00 AM grace cutoff has passed.
 * Implements Asymmetric Resolution:
 *  - Pending photo proof -> auto_approved, task completed, ₹0 penalty
 *  - Pending or declined excuse -> missed, ₹10 penalty recorded
 *  - Neither photo nor excuse -> missed, ₹10 penalty recorded
 */
exports.finalizeDay = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async (context) => {
    const now = new Date();
    console.log(`[finalizeDay] Running cron check at ${now.toISOString()}`);

    // Query unfinalized dayLogs where grace period (10:00 AM) has passed
    const usersSnapshot = await db.collection('users').get();

    for (const userDoc of usersSnapshot.docs) {
      const uid = userDoc.id;
      const dayLogsSnapshot = await db
        .collection('users')
        .doc(uid)
        .collection('dayLogs')
        .where('finalized', '==', false)
        .get();

      for (const dayLogDoc of dayLogsSnapshot.docs) {
        const dayLog = dayLogDoc.data();
        const logDateStr = dayLogDoc.id; // YYYY-MM-DD
        const [year, month, day] = logDateStr.split('-').map(Number);

        // 10:00 AM grace cutoff is on the morning following logDate
        const graceDeadline = new Date(year, month - 1, day + 1, 10, 0, 0);

        if (now < graceDeadline) {
          // Grace period still active for this day log
          continue;
        }

        console.log(`[finalizeDay] Processing unfinalized day log ${logDateStr} for user ${uid}`);

        // Fetch proofs and excuses for this date
        const [proofsSnap, excusesSnap, tasksSnap] = await Promise.all([
          db.collection('proofs').where('uid', '==', uid).where('date', '==', logDateStr).get(),
          db.collection('excuses').where('uid', '==', uid).where('date', '==', logDateStr).get(),
          db.collection('users').doc(uid).collection('tasks').where('active', '==', true).get(),
        ]);

        const proofs = proofsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
        const excuses = excusesSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
        const tasks = tasksSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

        const updatedOutcomes = { ...(dayLog.taskOutcomes || {}) };
        let additionalPenaltiesCount = 0;

        for (const task of tasks) {
          const outcome = updatedOutcomes[task.id] || { status: 'pending' };

          if (outcome.status === 'completed' || outcome.status === 'excused') {
            continue;
          }

          const matchingProof = proofs.find((p) => p.taskId === task.id);
          const matchingExcuse = excuses.find((e) => e.taskId === task.id);

          // Asymmetric Resolution
          if (matchingProof && matchingProof.status === 'pending') {
            // Unreviewed photo proof auto-approves past 10 AM without penalty
            await db.collection('proofs').doc(matchingProof.id).update({
              status: 'auto_approved',
              autoApprovedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            updatedOutcomes[task.id] = {
              status: 'completed',
              proofId: matchingProof.id,
            };
          } else if (matchingExcuse && matchingExcuse.status === 'pending') {
            // Unreviewed excuse past 10 AM finalizes as missed with ₹10 penalty
            await db.collection('excuses').doc(matchingExcuse.id).update({
              status: 'missed',
              finalizedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            updatedOutcomes[task.id] = {
              status: 'missed',
              excuseId: matchingExcuse.id,
              penaltyAmount: 10,
            };
            additionalPenaltiesCount += 1;
          } else if (matchingExcuse && matchingExcuse.status === 'declined') {
            updatedOutcomes[task.id] = {
              status: 'missed',
              excuseId: matchingExcuse.id,
              penaltyAmount: 10,
            };
            additionalPenaltiesCount += 1;
          } else {
            // Neither photo nor excuse was submitted
            updatedOutcomes[task.id] = {
              status: 'missed',
              penaltyAmount: 10,
            };
            additionalPenaltiesCount += 1;
          }
        }

        // Recalculate weights
        let totalWeight = 0;
        let completedWeight = 0;
        for (const task of tasks) {
          const outcome = updatedOutcomes[task.id];
          if (outcome && outcome.status !== 'excused') {
            totalWeight += (task.weight || 1);
          }
          if (outcome && outcome.status === 'completed') {
            completedWeight += (task.weight || 1);
          }
        }

        const completionPercent = totalWeight === 0
          ? 0
          : Math.min(100, Math.round((completedWeight / totalWeight) * 100));

        // Mark dayLog finalized
        await dayLogDoc.ref.update({
          taskOutcomes: updatedOutcomes,
          totalWeight,
          completedWeight,
          completionPercent,
          finalized: true,
          finalizedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update user unresolved penalties count
        if (additionalPenaltiesCount > 0) {
          await userDoc.ref.update({
            unresolvedPenaltiesCount: admin.firestore.FieldValue.increment(additionalPenaltiesCount),
          });
        }
      }
    }

    console.log('[finalizeDay] Completed daily grace cutoff processing.');
    return null;
  });
