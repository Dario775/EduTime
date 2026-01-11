/**
 * EduTime - Sync Module: Offline Activity Sync
 * 
 * PRIORITY ENDPOINT: Receives offline activity data from client devices
 * and syncs with Firestore while performing anti-cheat validation.
 * Using v1 API for compatibility.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import { CallableContext } from "firebase-functions/v1/https";

const db = admin.firestore();

// ============================================================
// TYPES
// ============================================================

/**
 * Activity event from client
 */
interface ActivityEvent {
    /** Package name of the app (e.g., "com.edutime.app") */
    packageName: string;

    /** Duration of activity in seconds */
    durationSeconds: number;

    /** Client-generated hash for integrity */
    clientHash: string;

    /** Activity type */
    type: "study" | "leisure" | "break";

    /** Subject ID (for study sessions) */
    subjectId?: string;

    /** Timestamp when activity started (client time) */
    startTimestamp: number;

    /** Timestamp when activity ended (client time) */
    endTimestamp: number;

    /** Session ID for tracking */
    sessionId?: string;
}

/**
 * Sync request payload
 */
interface SyncRequest {
    /** Child user ID */
    childId: string;

    /** Array of activity events */
    events: ActivityEvent[];

    /** Client device info for anti-cheat */
    deviceInfo: {
        deviceId: string;
        osVersion: string;
        appVersion: string;
        timezone: string;
    };

    /** Batch sync ID for idempotency */
    batchId: string;

    /** Client timestamp when sync was initiated */
    clientSyncTimestamp: number;
}

/**
 * Sync response
 */
interface SyncResponse {
    success: boolean;
    processedEvents: number;
    rejectedEvents: number;
    walletBalance?: number;
    errors: SyncError[];
    serverTimestamp: number;
}

/**
 * Sync error details
 */
interface SyncError {
    eventIndex: number;
    code: string;
    message: string;
}

/**
 * Anti-cheat validation result
 */
interface ValidationResult {
    isValid: boolean;
    code?: string;
    message?: string;
    adjustedDuration?: number;
}

// ============================================================
// ANTI-CHEAT VALIDATION
// ============================================================

/**
 * Maximum allowed time drift between client and server (5 minutes)
 */
const MAX_TIME_DRIFT_MS = 5 * 60 * 1000;

/**
 * Maximum duration for a single activity event (8 hours)
 */
const MAX_EVENT_DURATION_SECONDS = 8 * 60 * 60;

/**
 * Minimum duration for a valid activity event (10 seconds)
 */
const MIN_EVENT_DURATION_SECONDS = 10;

/**
 * Maximum events per sync batch
 */
const MAX_EVENTS_PER_BATCH = 100;

/**
 * Secret key for hash validation (should be in environment config)
 */
const HASH_SECRET = functions.config().anticheat?.secret || "edutime-dev-secret";

/**
 * Validate client hash for event integrity
 */
function validateClientHash(event: ActivityEvent, childId: string): boolean {
    const dataToHash = `${childId}:${event.packageName}:${event.durationSeconds}:${event.startTimestamp}:${event.endTimestamp}`;
    const expectedHash = crypto
        .createHmac("sha256", HASH_SECRET)
        .update(dataToHash)
        .digest("hex");

    return event.clientHash === expectedHash;
}

/**
 * Validate time consistency
 */
function validateTimeConsistency(
    event: ActivityEvent,
    serverTimestamp: number
): ValidationResult {
    const clientDuration = event.endTimestamp - event.startTimestamp;
    const reportedDuration = event.durationSeconds * 1000;

    // Check if timestamps are in the future
    if (event.endTimestamp > serverTimestamp + MAX_TIME_DRIFT_MS) {
        return {
            isValid: false,
            code: "FUTURE_TIMESTAMP",
            message: "Event timestamp is in the future",
        };
    }

    // Check if duration matches timestamps (within 10% tolerance)
    const durationDiff = Math.abs(clientDuration - reportedDuration);
    const tolerance = reportedDuration * 0.1;

    if (durationDiff > tolerance && durationDiff > 60000) {
        // More than 10% and 1 minute difference
        return {
            isValid: true, // Allow but adjust
            code: "DURATION_ADJUSTED",
            message: "Duration adjusted to match timestamps",
            adjustedDuration: Math.floor(clientDuration / 1000),
        };
    }

    // Check for reasonable duration
    if (event.durationSeconds > MAX_EVENT_DURATION_SECONDS) {
        return {
            isValid: true,
            code: "DURATION_CAPPED",
            message: "Duration capped to maximum allowed",
            adjustedDuration: MAX_EVENT_DURATION_SECONDS,
        };
    }

    if (event.durationSeconds < MIN_EVENT_DURATION_SECONDS) {
        return {
            isValid: false,
            code: "DURATION_TOO_SHORT",
            message: "Event duration too short",
        };
    }

    return { isValid: true };
}

/**
 * Check for overlapping events (potential duplicate/cheat)
 */
async function checkForOverlaps(
    childId: string,
    events: ActivityEvent[]
): Promise<Map<number, ValidationResult>> {
    const results = new Map<number, ValidationResult>();

    // Sort events by start time
    const sortedEvents = events.map((e, i) => ({ event: e, index: i }))
        .sort((a, b) => a.event.startTimestamp - b.event.startTimestamp);

    // Check for overlaps within batch
    for (let i = 1; i < sortedEvents.length; i++) {
        const prev = sortedEvents[i - 1];
        const curr = sortedEvents[i];

        if (curr.event.startTimestamp < prev.event.endTimestamp) {
            results.set(curr.index, {
                isValid: false,
                code: "OVERLAPPING_EVENT",
                message: "Event overlaps with another event",
            });
        }
    }

    // Check for overlaps with existing events in database
    const oneDayAgo = Date.now() - 24 * 60 * 60 * 1000;
    const existingEvents = await db
        .collection("users")
        .doc(childId)
        .collection("sessions")
        .where("startedAt", ">=", admin.firestore.Timestamp.fromMillis(oneDayAgo))
        .get();

    const existingRanges = existingEvents.docs.map((doc) => {
        const data = doc.data();
        return {
            start: data.startedAt.toMillis(),
            end: data.endedAt?.toMillis() || Date.now(),
        };
    });

    for (let i = 0; i < events.length; i++) {
        if (results.has(i)) continue; // Already marked invalid

        const event = events[i];
        for (const range of existingRanges) {
            if (
                event.startTimestamp < range.end &&
                event.endTimestamp > range.start
            ) {
                results.set(i, {
                    isValid: false,
                    code: "DUPLICATE_EVENT",
                    message: "Event overlaps with existing session",
                });
                break;
            }
        }
    }

    return results;
}

/**
 * Rate limiting check
 */
async function checkRateLimit(
    childId: string,
    batchId: string
): Promise<ValidationResult> {
    const rateLimitRef = db.collection("rateLimits").doc(childId);
    const rateLimitDoc = await rateLimitRef.get();

    const now = Date.now();
    const windowMs = 60 * 1000; // 1 minute window
    const maxRequestsPerWindow = 10;

    if (rateLimitDoc.exists) {
        const data = rateLimitDoc.data()!;

        // Check for duplicate batch
        if (data.processedBatches?.includes(batchId)) {
            return {
                isValid: false,
                code: "DUPLICATE_BATCH",
                message: "Batch already processed",
            };
        }

        // Check rate limit
        const windowStart = now - windowMs;
        const recentRequests = (data.requests || []).filter(
            (ts: number) => ts > windowStart
        );

        if (recentRequests.length >= maxRequestsPerWindow) {
            return {
                isValid: false,
                code: "RATE_LIMITED",
                message: "Too many sync requests",
            };
        }
    }

    return { isValid: true };
}

// ============================================================
// MAIN SYNC FUNCTION
// ============================================================

/**
 * Sync offline activity from client device
 *
 * @param data - Sync request payload
 * @param context - Function context with auth info
 * @returns Sync response with processed/rejected counts
 */
export const syncOfflineActivity = functions.https.onCall(
    async (data: SyncRequest, context: CallableContext): Promise<SyncResponse> => {
        const serverTimestamp = Date.now();
        const errors: SyncError[] = [];
        let processedEvents = 0;
        let rejectedEvents = 0;

        // ============ Authentication ============
        if (!context.auth) {
            throw new functions.https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const callerUid = context.auth.uid;
        const { childId, events, deviceInfo, batchId, clientSyncTimestamp } = data;

        // ============ Authorization ============
        // Check if caller is the child or their parent
        const userDoc = await db.collection("users").doc(callerUid).get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "User profile not found"
            );
        }

        const userData = userDoc.data()!;
        const isChild = callerUid === childId;
        const isParent = userData.role === "PARENT" &&
            userData.familyId &&
            await isParentOfChild(userData.familyId, childId);

        if (!isChild && !isParent) {
            throw new functions.https.HttpsError(
                "permission-denied",
                "Not authorized to sync for this child"
            );
        }

        // ============ Rate Limiting ============
        const rateLimitResult = await checkRateLimit(childId, batchId);
        if (!rateLimitResult.isValid) {
            throw new functions.https.HttpsError(
                "resource-exhausted",
                rateLimitResult.message || "Rate limit exceeded"
            );
        }

        // ============ Validation ============
        if (!events || events.length === 0) {
            return {
                success: true,
                processedEvents: 0,
                rejectedEvents: 0,
                errors: [],
                serverTimestamp,
            };
        }

        if (events.length > MAX_EVENTS_PER_BATCH) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                `Maximum ${MAX_EVENTS_PER_BATCH} events per batch`
            );
        }

        // Check time drift
        const timeDrift = Math.abs(serverTimestamp - clientSyncTimestamp);
        if (timeDrift > MAX_TIME_DRIFT_MS) {
            functions.logger.warn("Large time drift detected", {
                childId,
                timeDrift,
                clientTime: clientSyncTimestamp,
                serverTime: serverTimestamp,
            });
        }

        // ============ Anti-Cheat Validation ============
        const overlapResults = await checkForOverlaps(childId, events);

        const validatedEvents: Array<{
            event: ActivityEvent;
            index: number;
            adjustedDuration?: number;
        }> = [];

        for (let i = 0; i < events.length; i++) {
            const event = events[i];

            // Check overlaps
            if (overlapResults.has(i)) {
                const result = overlapResults.get(i)!;
                errors.push({
                    eventIndex: i,
                    code: result.code || "VALIDATION_ERROR",
                    message: result.message || "Validation failed",
                });
                rejectedEvents++;
                continue;
            }

            // Validate hash
            if (!validateClientHash(event, childId)) {
                errors.push({
                    eventIndex: i,
                    code: "INVALID_HASH",
                    message: "Event integrity check failed",
                });
                rejectedEvents++;
                continue;
            }

            // Validate time consistency
            const timeResult = validateTimeConsistency(event, serverTimestamp);
            if (!timeResult.isValid) {
                errors.push({
                    eventIndex: i,
                    code: timeResult.code || "TIME_ERROR",
                    message: timeResult.message || "Time validation failed",
                });
                rejectedEvents++;
                continue;
            }

            validatedEvents.push({
                event,
                index: i,
                adjustedDuration: timeResult.adjustedDuration,
            });
        }

        // ============ Process Valid Events ============
        const batch = db.batch();
        let totalEarnedSeconds = 0;

        // Get family config for time ratio
        const familyConfig = await getFamilyConfig(childId);
        const globalRatio = familyConfig?.settings?.timeRatio?.globalRatio || 1.0;

        for (const { event, adjustedDuration } of validatedEvents) {
            const duration = adjustedDuration || event.durationSeconds;

            // Create session document
            const sessionRef = db
                .collection("users")
                .doc(childId)
                .collection("sessions")
                .doc();

            const sessionData = {
                id: sessionRef.id,
                odexUserId: childId,
                type: event.type === "study" ? "FREE" : event.type.toUpperCase(),
                status: "COMPLETED",
                subjectId: event.subjectId || null,
                packageName: event.packageName,
                plannedDuration: duration,
                actualDuration: duration,
                earnedTime: event.type === "study"
                    ? Math.floor(duration * globalRatio)
                    : 0,
                startedAt: admin.firestore.Timestamp.fromMillis(event.startTimestamp),
                endedAt: admin.firestore.Timestamp.fromMillis(event.endTimestamp),
                syncedAt: admin.firestore.FieldValue.serverTimestamp(),
                deviceInfo: {
                    deviceId: deviceInfo.deviceId,
                    appVersion: deviceInfo.appVersion,
                },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };

            batch.set(sessionRef, sessionData);

            if (event.type === "study") {
                totalEarnedSeconds += sessionData.earnedTime;
            }

            processedEvents++;
        }

        // Update wallet if time was earned
        if (totalEarnedSeconds > 0) {
            const walletRef = db.collection("wallets").doc(childId);
            batch.update(walletRef, {
                balanceSeconds: admin.firestore.FieldValue.increment(totalEarnedSeconds),
                lifetimeEarned: admin.firestore.FieldValue.increment(totalEarnedSeconds),
                lastTransactionAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Create transaction record
            const txRef = db.collection("transactions").doc();
            batch.set(txRef, {
                id: txRef.id,
                walletId: childId,
                type: "EARN",
                amountSeconds: totalEarnedSeconds,
                description: `Sync: ${processedEvents} study sessions`,
                batchId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }

        // Update rate limit tracker
        const rateLimitRef = db.collection("rateLimits").doc(childId);
        batch.set(rateLimitRef, {
            requests: admin.firestore.FieldValue.arrayUnion(serverTimestamp),
            processedBatches: admin.firestore.FieldValue.arrayUnion(batchId),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        // Commit all changes
        await batch.commit();

        // Get updated wallet balance
        const walletDoc = await db.collection("wallets").doc(childId).get();
        const walletBalance = walletDoc.exists
            ? walletDoc.data()?.balanceSeconds
            : 0;

        functions.logger.info("Sync completed", {
            childId,
            batchId,
            processedEvents,
            rejectedEvents,
            totalEarnedSeconds,
        });

        return {
            success: true,
            processedEvents,
            rejectedEvents,
            walletBalance,
            errors,
            serverTimestamp,
        };
    }
);

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/**
 * Check if a user is a parent of a child
 */
async function isParentOfChild(
    familyId: string,
    childId: string
): Promise<boolean> {
    const familyDoc = await db.collection("families").doc(familyId).get();
    if (!familyDoc.exists) return false;

    const familyData = familyDoc.data()!;
    return familyData.childUids?.includes(childId) || false;
}

/**
 * Get family configuration for a user
 */
async function getFamilyConfig(userId: string) {
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return null;

    const userData = userDoc.data()!;
    if (!userData.familyId) return null;

    const familyDoc = await db.collection("families").doc(userData.familyId).get();
    return familyDoc.exists ? familyDoc.data() : null;
}

/**
 * Generate client hash (for testing/documentation)
 */
export function generateClientHash(
    childId: string,
    packageName: string,
    durationSeconds: number,
    startTimestamp: number,
    endTimestamp: number
): string {
    const dataToHash = `${childId}:${packageName}:${durationSeconds}:${startTimestamp}:${endTimestamp}`;
    return crypto
        .createHmac("sha256", HASH_SECRET)
        .update(dataToHash)
        .digest("hex");
}
