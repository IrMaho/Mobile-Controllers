package com.example.mobail_contorolers

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.LayoutInflater
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.ImageView
import kotlin.math.max
import kotlin.math.min

class MouseControlService : AccessibilityService() {
    private var windowManager: WindowManager? = null
    private var cursorView: ImageView? = null
    private var cursorX = 0f
    private var cursorY = 0f
    
    companion object {
        var instance: MouseControlService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        setupCursorOverlay()
    }

    private fun setupCursorOverlay() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        cursorView = ImageView(this).apply {
            // TODO: Add custom cursor drawable
            setBackgroundColor(0xFFFF0000.toInt()) // Red circle for now
        }
        
        val params = WindowManager.LayoutParams(
            50, // width
            50, // height
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = 0
        }
        
        windowManager?.addView(cursorView, params)
    }

    fun moveCursor(deltaX: Int, deltaY: Int) {
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels.toFloat()
        val screenHeight = displayMetrics.heightPixels.toFloat()
        
        cursorX = max(0f, min(screenWidth - 50, cursorX + deltaX))
        cursorY = max(0f, min(screenHeight - 50, cursorY + deltaY))
        
        cursorView?.let { view ->
            val params = view.layoutParams as WindowManager.LayoutParams
            params.x = cursorX.toInt()
            params.y = cursorY.toInt()
            windowManager?.updateViewLayout(view, params)
        }
    }

    fun performClick() {
        val path = Path().apply {
            moveTo(cursorX, cursorY)
        }
        
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 10))
            .build()
        
        dispatchGesture(gesture, null, null)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not needed for our use case
    }

    override fun onInterrupt() {
        // Not needed
    }

    override fun onDestroy() {
        super.onDestroy()
        cursorView?.let { windowManager?.removeView(it) }
        instance = null
    }
}
