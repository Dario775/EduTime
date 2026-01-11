package com.edutime.app

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import androidx.annotation.NonNull
import com.edutime.app.services.EduAccessibilityService
import com.edutime.app.services.OverlayService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * EduTime MainActivity
 *
 * Handles:
 * - Android Keystore encryption for Isar database
 * - Monitor service communication via MethodChannel
 * - Event streaming to Flutter via EventChannel
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        
        // Channel names
        private const val ENCRYPTION_CHANNEL = "com.edutime.app/encryption"
        private const val MONITOR_CHANNEL = "com.edutime.app/monitor"
        private const val MONITOR_EVENTS_CHANNEL = "com.edutime.app/monitor_events"
        
        // Keystore constants
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val GCM_TAG_LENGTH = 128
        private const val ENCRYPTION_PREFS_NAME = "edutime_encryption_prefs"
        private const val IV_PREFIX = "iv_"
        private const val KEY_PREFIX = "encrypted_key_"
        
        // Monitor prefs
        private const val MONITOR_PREFS_NAME = "edutime_monitor_prefs"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        private const val KEY_WHITELISTED_APPS = "whitelisted_apps"
        private const val KEY_BALANCE_SECONDS = "balance_seconds"
        private const val KEY_BLOCKING_ENABLED = "blocking_enabled"
        private const val KEY_MONITORING_ENABLED = "monitoring_enabled"
    }
    
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        setupEncryptionChannel(flutterEngine)
        setupMonitorChannel(flutterEngine)
        setupMonitorEventsChannel(flutterEngine)
        
        // Set up accessibility service listener
        setupAccessibilityServiceListener()
    }
    
    // ============================================================
    // ENCRYPTION CHANNEL
    // ============================================================
    
    private fun setupEncryptionChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENCRYPTION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasKey" -> {
                        val alias = call.argument<String>("alias") ?: ""
                        result.success(hasKey(alias))
                    }
                    "getKey" -> {
                        val alias = call.argument<String>("alias") ?: ""
                        try {
                            val key = getKey(alias)
                            if (key != null) {
                                result.success(key)
                            } else {
                                result.error("KEY_NOT_FOUND", "Key not found for alias: $alias", null)
                            }
                        } catch (e: Exception) {
                            result.error("GET_KEY_ERROR", e.message, e.stackTraceToString())
                        }
                    }
                    "storeKey" -> {
                        val alias = call.argument<String>("alias") ?: ""
                        val key = call.argument<ByteArray>("key")
                        if (key == null) {
                            result.error("INVALID_KEY", "Key cannot be null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            storeKey(alias, key)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("STORE_KEY_ERROR", e.message, e.stackTraceToString())
                        }
                    }
                    "deleteKey" -> {
                        val alias = call.argument<String>("alias") ?: ""
                        try {
                            deleteKey(alias)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("DELETE_KEY_ERROR", e.message, e.stackTraceToString())
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    // ============================================================
    // MONITOR CHANNEL
    // ============================================================
    
    private fun setupMonitorChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MONITOR_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAccessibilityPermission" -> {
                        val isEnabled = EduAccessibilityService.isAccessibilityServiceEnabled(this)
                        result.success(isEnabled)
                    }
                    "requestAccessibilityPermission" -> {
                        EduAccessibilityService.openAccessibilitySettings(this)
                        result.success(null)
                    }
                    "checkOverlayPermission" -> {
                        result.success(OverlayService.canDrawOverlays(this))
                    }
                    "requestOverlayPermission" -> {
                        OverlayService.requestOverlayPermission(this)
                        result.success(null)
                    }
                    "startMonitoring" -> {
                        val userId = call.argument<String>("userId") ?: ""
                        val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                        val whitelistedApps = call.argument<List<String>>("whitelistedApps") ?: emptyList()
                        
                        val success = startMonitoring(userId, blockedApps, whitelistedApps)
                        result.success(success)
                    }
                    "stopMonitoring" -> {
                        stopMonitoring()
                        result.success(null)
                    }
                    "updateBalance" -> {
                        val balance = call.argument<Int>("balanceSeconds") ?: 0
                        updateBalance(balance)
                        result.success(null)
                    }
                    "updateWhitelist" -> {
                        val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                        val whitelistedApps = call.argument<List<String>>("whitelistedApps") ?: emptyList()
                        updateWhitelist(blockedApps, whitelistedApps)
                        result.success(null)
                    }
                    "setBlockingEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        setBlockingEnabled(enabled)
                        result.success(null)
                    }
                    "showOverlay" -> {
                        val message = call.argument<String>("message") ?: ""
                        val remainingSeconds = call.argument<Int>("remainingSeconds") ?: 0
                        showOverlay(message, remainingSeconds)
                        result.success(null)
                    }
                    "hideOverlay" -> {
                        hideOverlay()
                        result.success(null)
                    }
                    "getInstalledApps" -> {
                        val apps = getInstalledApps()
                        result.success(apps)
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    // ============================================================
    // MONITOR EVENTS CHANNEL
    // ============================================================
    
    private fun setupMonitorEventsChannel(flutterEngine: FlutterEngine) {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, MONITOR_EVENTS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.d(TAG, "Monitor events stream started")
                }
                
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d(TAG, "Monitor events stream cancelled")
                }
            })
    }
    
    // ============================================================
    // ACCESSIBILITY SERVICE LISTENER
    // ============================================================
    
    private fun setupAccessibilityServiceListener() {
        EduAccessibilityService.getInstance()?.setOnAppChangeListener(
            object : EduAccessibilityService.OnAppChangeListener {
                override fun onAppChanged(packageName: String, appName: String, isBlocked: Boolean) {
                    sendEventToFlutter(mapOf(
                        "type" to "APP_OPENED",
                        "packageName" to packageName,
                        "appName" to appName,
                        "isBlocked" to isBlocked
                    ))
                }
            }
        )
    }
    
    private fun sendEventToFlutter(event: Map<String, Any>) {
        handler.post {
            eventSink?.success(event)
        }
    }
    
    // ============================================================
    // MONITOR METHODS
    // ============================================================
    
    private fun startMonitoring(
        userId: String,
        blockedApps: List<String>,
        whitelistedApps: List<String>
    ): Boolean {
        // Check permissions
        if (!EduAccessibilityService.isAccessibilityServiceEnabled(this)) {
            Log.w(TAG, "Accessibility service not enabled")
            return false
        }
        
        if (!OverlayService.canDrawOverlays(this)) {
            Log.w(TAG, "Overlay permission not granted")
            return false
        }
        
        // Save configuration
        val prefs = getSharedPreferences(MONITOR_PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_USER_ID, userId)
            .putStringSet(KEY_BLOCKED_APPS, blockedApps.toSet())
            .putStringSet(KEY_WHITELISTED_APPS, whitelistedApps.toSet())
            .putBoolean(KEY_MONITORING_ENABLED, true)
            .putBoolean(KEY_BLOCKING_ENABLED, true)
            .apply()
        
        // Update accessibility service
        EduAccessibilityService.getInstance()?.updateBlockedApps(blockedApps, whitelistedApps)
        
        // Start overlay service
        val intent = Intent(this, OverlayService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        
        setupAccessibilityServiceListener()
        
        Log.i(TAG, "Monitoring started for user: $userId")
        return true
    }
    
    private fun stopMonitoring() {
        val prefs = getSharedPreferences(MONITOR_PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_MONITORING_ENABLED, false)
            .apply()
        
        // Stop overlay service
        stopService(Intent(this, OverlayService::class.java))
        
        Log.i(TAG, "Monitoring stopped")
    }
    
    private fun updateBalance(balanceSeconds: Int) {
        val prefs = getSharedPreferences(MONITOR_PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putInt(KEY_BALANCE_SECONDS, balanceSeconds)
            .apply()
        
        EduAccessibilityService.getInstance()?.updateBalance(balanceSeconds)
    }
    
    private fun updateWhitelist(blockedApps: List<String>, whitelistedApps: List<String>) {
        val prefs = getSharedPreferences(MONITOR_PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putStringSet(KEY_BLOCKED_APPS, blockedApps.toSet())
            .putStringSet(KEY_WHITELISTED_APPS, whitelistedApps.toSet())
            .apply()
        
        EduAccessibilityService.getInstance()?.updateBlockedApps(blockedApps, whitelistedApps)
    }
    
    private fun setBlockingEnabled(enabled: Boolean) {
        val prefs = getSharedPreferences(MONITOR_PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_BLOCKING_ENABLED, enabled)
            .apply()
        
        EduAccessibilityService.getInstance()?.setBlockingEnabled(enabled)
    }
    
    private fun showOverlay(message: String, remainingSeconds: Int) {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_SHOW_OVERLAY
            putExtra(OverlayService.EXTRA_MESSAGE, message)
            putExtra(OverlayService.EXTRA_REMAINING_SECONDS, remainingSeconds)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
    
    private fun hideOverlay() {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_HIDE_OVERLAY
        }
        startService(intent)
    }
    
    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any>>()
        
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(0)
        }
        
        for (appInfo in packages) {
            // Skip system apps without launcher activity
            val launchIntent = pm.getLaunchIntentForPackage(appInfo.packageName)
            if (launchIntent == null && (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) {
                continue
            }
            
            apps.add(mapOf(
                "packageName" to appInfo.packageName,
                "appName" to pm.getApplicationLabel(appInfo).toString(),
                "isSystemApp" to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0)
            ))
        }
        
        return apps.sortedBy { it["appName"] as String }
    }
    
    // ============================================================
    // ENCRYPTION METHODS
    // ============================================================
    
    private fun hasKey(alias: String): Boolean {
        val prefs = getSharedPreferences(ENCRYPTION_PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.contains(KEY_PREFIX + alias)
    }
    
    private fun getKey(alias: String): ByteArray? {
        val prefs = getSharedPreferences(ENCRYPTION_PREFS_NAME, Context.MODE_PRIVATE)
        
        val encryptedKeyB64 = prefs.getString(KEY_PREFIX + alias, null) ?: return null
        val ivB64 = prefs.getString(IV_PREFIX + alias, null) ?: return null
        
        val encryptedKey = Base64.decode(encryptedKeyB64, Base64.DEFAULT)
        val iv = Base64.decode(ivB64, Base64.DEFAULT)
        
        val masterKey = getMasterKey(alias)
        
        val cipher = Cipher.getInstance(TRANSFORMATION)
        val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
        cipher.init(Cipher.DECRYPT_MODE, masterKey, spec)
        
        return cipher.doFinal(encryptedKey)
    }
    
    private fun storeKey(alias: String, key: ByteArray) {
        val masterKey = getOrCreateMasterKey(alias)
        
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, masterKey)
        
        val iv = cipher.iv
        val encryptedKey = cipher.doFinal(key)
        
        val prefs = getSharedPreferences(ENCRYPTION_PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_PREFIX + alias, Base64.encodeToString(encryptedKey, Base64.DEFAULT))
            .putString(IV_PREFIX + alias, Base64.encodeToString(iv, Base64.DEFAULT))
            .apply()
    }
    
    private fun deleteKey(alias: String) {
        val prefs = getSharedPreferences(ENCRYPTION_PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .remove(KEY_PREFIX + alias)
            .remove(IV_PREFIX + alias)
            .apply()
        
        try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
            keyStore.load(null)
            keyStore.deleteEntry(getMasterKeyAlias(alias))
        } catch (e: Exception) {
            Log.w(TAG, "Failed to delete master key", e)
        }
    }
    
    private fun getMasterKeyAlias(alias: String): String = "master_$alias"
    
    private fun getMasterKey(alias: String): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
        keyStore.load(null)
        
        val masterKeyAlias = getMasterKeyAlias(alias)
        val entry = keyStore.getEntry(masterKeyAlias, null) as? KeyStore.SecretKeyEntry
            ?: throw Exception("Master key not found")
        
        return entry.secretKey
    }
    
    private fun getOrCreateMasterKey(alias: String): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
        keyStore.load(null)
        
        val masterKeyAlias = getMasterKeyAlias(alias)
        
        if (keyStore.containsAlias(masterKeyAlias)) {
            val entry = keyStore.getEntry(masterKeyAlias, null) as? KeyStore.SecretKeyEntry
            if (entry != null) {
                return entry.secretKey
            }
        }
        
        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )
        
        val builder = KeyGenParameterSpec.Builder(
            masterKeyAlias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setInvalidatedByBiometricEnrollment(false)
        }
        
        keyGenerator.init(builder.build())
        return keyGenerator.generateKey()
    }
}
