/**
 * EduTime - Firebase Cloud Functions
 * 
 * Core auth triggers and scheduled functions.
 * Using v1 API for compatibility.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { UserRecord } from "firebase-admin/auth";

// Firestore reference
const db = admin.firestore();

/**
 * User creation trigger
 * Initializes user profile when a new user signs up
 */
export const onUserCreate = functions.auth.user().onCreate(async (user: UserRecord) => {
    const { uid, email, displayName, photoURL } = user;

    try {
        await db.collection("users").doc(uid).set({
            uid,
            email: email ?? null,
            displayName: displayName ?? null,
            photoURL: photoURL ?? null,
            role: "CHILD", // Default role
            status: "active",
            timezone: "America/Argentina/Buenos_Aires",
            language: "es",
            deviceTokens: [],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            settings: {
                theme: "system",
                notifications: true,
                language: "es",
            },
            stats: {
                totalStudyTime: 0,
                totalSessions: 0,
                currentStreak: 0,
                longestStreak: 0,
            },
        });

        // Create wallet for new user
        await db.collection("wallets").doc(uid).set({
            id: uid,
            balanceSeconds: 0,
            lifetimeEarned: 0,
            lifetimeSpent: 0,
            lastTransactionAt: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        functions.logger.info(`User profile and wallet created for ${uid}`);
    } catch (error) {
        functions.logger.error(`Error creating user profile: ${error}`);
        throw error;
    }
});

/**
 * User deletion trigger
 * Cleans up user data when account is deleted
 */
export const onUserDelete = functions.auth.user().onDelete(async (user: UserRecord) => {
    const { uid } = user;

    try {
        const batch = db.batch();

        // Delete user document
        batch.delete(db.collection("users").doc(uid));

        // Delete wallet
        batch.delete(db.collection("wallets").doc(uid));

        // Delete streak
        batch.delete(db.collection("streaks").doc(uid));

        // Delete rate limit tracker
        batch.delete(db.collection("rateLimits").doc(uid));

        await batch.commit();

        // Delete user's study sessions subcollection
        const sessionsRef = db.collection("users").doc(uid).collection("sessions");
        const sessionsSnapshot = await sessionsRef.limit(500).get();

        if (!sessionsSnapshot.empty) {
            const sessionBatch = db.batch();
            sessionsSnapshot.docs.forEach((doc) => {
                sessionBatch.delete(doc.ref);
            });
            await sessionBatch.commit();
        }

        // Delete user's subjects subcollection
        const subjectsRef = db.collection("users").doc(uid).collection("subjects");
        const subjectsSnapshot = await subjectsRef.limit(500).get();

        if (!subjectsSnapshot.empty) {
            const subjectBatch = db.batch();
            subjectsSnapshot.docs.forEach((doc) => {
                subjectBatch.delete(doc.ref);
            });
            await subjectBatch.commit();
        }

        functions.logger.info(`User data cleaned up for ${uid}`);
    } catch (error) {
        functions.logger.error(`Error cleaning up user data: ${error}`);
        throw error;
    }
});

/**
 * Scheduled function for daily stats update
 * Runs every day at midnight to update user streaks
 */
export const updateDailyStreaks = functions.pubsub
    .schedule("0 0 * * *")
    .timeZone("America/Argentina/Buenos_Aires")
    .onRun(async () => {
        functions.logger.info("Starting daily streak update");

        try {
            const yesterday = new Date();
            yesterday.setDate(yesterday.getDate() - 1);
            const yesterdayStr = yesterday.toISOString().split("T")[0];

            const streaksSnapshot = await db.collection("streaks").get();

            const batch = db.batch();
            let updateCount = 0;

            for (const streakDoc of streaksSnapshot.docs) {
                const streakData = streakDoc.data();

                // If last study wasn't yesterday, reset streak
                if (streakData.lastStudyDate !== yesterdayStr) {
                    batch.update(streakDoc.ref, {
                        currentStreak: 0,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    updateCount++;
                }
            }

            if (updateCount > 0) {
                await batch.commit();
            }

            functions.logger.info(`Daily streak update completed: ${updateCount} streaks reset`);
        } catch (error) {
            functions.logger.error(`Error updating daily streaks: ${error}`);
            throw error;
        }
    });
