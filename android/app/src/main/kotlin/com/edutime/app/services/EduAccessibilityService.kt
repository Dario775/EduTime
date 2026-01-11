package com.edutime.app.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * EduAccessibilityService - Monitors app usage on the device
 * 
 * This service uses Android's Accessibility API to detect when
 * apps are opened or switched, enabling parental control features.
 * 
 * Required permission: BIND_ACCESSIBILITY_SERVICE
 */
class EduAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val TAG = "EduAccessibility"
        
        // Shared preferences keys
        private const val PREFS_NAME = "edutime_monitor_prefs"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        private const val KEY_WHITELISTED_APPS = "whitelisted_apps"
        private const val KEY_BALANCE_SECONDS = "balance_seconds"
        private const val KEY_BLOCKING_ENABLED = "blocking_enabled"
        
        // Singleton instance
        private var instance: EduAccessibilityService? = null
        
        fun getInstance(): EduAccessibilityService? = instance
        
        /**
         * Check if accessibility service is enabled
         */
        fun isAccessibilityServiceEnabled(context: Context): Boolean {
            val expectedComponentName = ComponentName(context, EduAccessibilityService::class.java)
            val enabledServices = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false
            
            val colonSplitter = TextUtils.SimpleStringSplitter(':')
            colonSplitter.setString(enabledServices)
            
            while (colonSplitter.hasNext()) {
                val componentNameString = colonSplitter.next()
                val enabledService = ComponentName.unflattenFromString(componentNameString)
                if (enabledService != null && enabledService == expectedComponentName) {
                    return true
                }
            }
            return false
        }
        
        /**
         * Open accessibility settings
         */
        fun openAccessibilitySettings(context: Context) {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }
    
    private var currentPackage: String = ""
    private var lastEventTime: Long = 0
    private val eventDebounceMs = 500L
    
    // Listener for app change events
    interface OnAppChangeListener {
        fun onAppChanged(packageName: String, appName: String, isBlocked: Boolean)
    }
    
    private var appChangeListener: OnAppChangeListener? = null
    
    fun setOnAppChangeListener(listener: OnAppChangeListener?) {
        appChangeListener = listener
    }
    
    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.i(TAG, "EduAccessibilityService created")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.i(TAG, "EduAccessibilityService destroyed")
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                   AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 100
        }
        
        serviceInfo = info
        Log.i(TAG, "EduAccessibilityService connected")
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // Debounce events
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastEventTime < eventDebounceMs) return
        lastEventTime = currentTime
        
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val packageName = event.packageName?.toString() ?: return
                
                // Ignore system UI and launcher
                if (isSystemPackage(packageName)) return
                
                // Check if package changed
                if (packageName != currentPackage) {
                    currentPackage = packageName
                    onPackageChanged(packageName)
                }
            }
        }
    }
    
    override fun onInterrupt() {
        Log.w(TAG, "EduAccessibilityService interrupted")
    }
    
    /**
     * Called when the foreground app changes
     */
    private fun onPackageChanged(packageName: String) {
        Log.d(TAG, "Package changed to: $packageName")
        
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val blockingEnabled = prefs.getBoolean(KEY_BLOCKING_ENABLED, true)
        
        if (!blockingEnabled) {
            Log.d(TAG, "Blocking disabled, skipping check")
            return
        }
        
        val blockedApps = prefs.getStringSet(KEY_BLOCKED_APPS, emptySet()) ?: emptySet()
        val whitelistedApps = prefs.getStringSet(KEY_WHITELISTED_APPS, emptySet()) ?: emptySet()
        val balanceSeconds = prefs.getInt(KEY_BALANCE_SECONDS, 0)
        
        val appName = getAppName(packageName)
        val isBlocked = shouldBlockApp(packageName, blockedApps, whitelistedApps, balanceSeconds)
        
        // Notify listener
        appChangeListener?.onAppChanged(packageName, appName, isBlocked)
        
        // Show overlay if blocked
        if (isBlocked) {
            showBlockingOverlay(packageName, appName, balanceSeconds)
        } else {
            hideBlockingOverlay()
        }
    }
    
    /**
     * Determine if an app should be blocked
     */
    private fun shouldBlockApp(
        packageName: String,
        blockedApps: Set<String>,
        whitelistedApps: Set<String>,
        balanceSeconds: Int
    ): Boolean {
        // Never block whitelisted apps (including EduTime itself)
        if (whitelistedApps.contains(packageName)) return false
        if (packageName == this.packageName) return false
        
        // Block if explicitly in blocked list
        if (blockedApps.contains(packageName)) {
            return balanceSeconds <= 0
        }
        
        // Default behavior: block entertainment apps when no balance
        if (isEntertainmentApp(packageName) && balanceSeconds <= 0) {
            return true
        }
        
        return false
    }
    
    /**
     * Check if package is a system/launcher package
     */
    private fun isSystemPackage(packageName: String): Boolean {
        val systemPackages = setOf(
            "com.android.systemui",
            "com.android.launcher",
            "com.android.launcher3",
            "com.google.android.apps.nexuslauncher",
            "com.sec.android.app.launcher",
            "com.miui.home",
            "com.huawei.android.launcher",
            "com.android.settings",
            "com.android.vending", // Play Store
            this.packageName // EduTime itself
        )
        return systemPackages.contains(packageName) || 
               packageName.startsWith("com.android.") ||
               packageName.startsWith("com.google.android.gms")
    }
    
    /**
     * Check if package is an entertainment/leisure app
     */
    private fun isEntertainmentApp(packageName: String): Boolean {
        val entertainmentPrefixes = listOf(
            "com.instagram",
            "com.facebook",
            "com.twitter",
            "com.tiktok",
            "com.zhiliaoapp.musically",
            "com.snapchat",
            "com.whatsapp",
            "com.netflix",
            "com.spotify",
            "com.google.android.youtube",
            "com.supercell",
            "com.ea.",
            "com.gameloft",
            "com.king.",
            "tv.twitch",
            "com.discord",
            "com.reddit",
            "com.pinterest"
        )
        
        return entertainmentPrefixes.any { packageName.startsWith(it) }
    }
    
    /**
     * Get readable app name from package name
     */
    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getApplicationInfo(packageName, PackageManager.ApplicationInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.getApplicationInfo(packageName, 0)
            }
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }
    
    /**
     * Show the blocking overlay
     */
    private fun showBlockingOverlay(packageName: String, appName: String, balanceSeconds: Int) {
        Log.i(TAG, "Showing blocking overlay for: $appName")
        
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_SHOW_OVERLAY
            putExtra(OverlayService.EXTRA_APP_NAME, appName)
            putExtra(OverlayService.EXTRA_PACKAGE_NAME, packageName)
            putExtra(OverlayService.EXTRA_REMAINING_SECONDS, balanceSeconds)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
    
    /**
     * Hide the blocking overlay
     */
    private fun hideBlockingOverlay() {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_HIDE_OVERLAY
        }
        startService(intent)
    }
    
    /**
     * Update blocked apps list
     */
    fun updateBlockedApps(blockedApps: List<String>, whitelistedApps: List<String>) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putStringSet(KEY_BLOCKED_APPS, blockedApps.toSet())
            .putStringSet(KEY_WHITELISTED_APPS, whitelistedApps.toSet())
            .apply()
        
        Log.i(TAG, "Updated blocked apps: ${blockedApps.size}, whitelisted: ${whitelistedApps.size}")
    }
    
    /**
     * Update time balance
     */
    fun updateBalance(balanceSeconds: Int) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putInt(KEY_BALANCE_SECONDS, balanceSeconds)
            .apply()
        
        Log.d(TAG, "Updated balance: $balanceSeconds seconds")
        
        // Re-check current app with new balance
        if (currentPackage.isNotEmpty()) {
            onPackageChanged(currentPackage)
        }
    }
    
    /**
     * Enable or disable blocking
     */
    fun setBlockingEnabled(enabled: Boolean) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(KEY_BLOCKING_ENABLED, enabled)
            .apply()
        
        Log.i(TAG, "Blocking enabled: $enabled")
        
        if (!enabled) {
            hideBlockingOverlay()
        }
    }
}
