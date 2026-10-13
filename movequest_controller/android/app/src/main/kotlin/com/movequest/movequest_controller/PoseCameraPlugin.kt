package com.movequest.movequest_controller

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.view.View
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class PoseCameraPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var controller: PoseCameraController? = null
    private var eventSink: EventChannel.EventSink? = null
    private var permissionResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            PREVIEW_VIEW,
            object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
                override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
                    val preview = controller?.previewView
                        ?: PreviewView(context).apply {
                            setBackgroundColor(android.graphics.Color.BLACK)
                        }
                    return object : PlatformView {
                        override fun getView(): View = preview
                        override fun dispose() = Unit
                    }
                }
            },
        )
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val host = activity
        when (call.method) {
            "checkCameraPermission" -> result.success(hasCameraPermission(host))
            "requestCameraPermission" -> {
                if (host == null) {
                    result.error("NO_ACTIVITY", "Camera permission needs an active screen.", null)
                } else if (hasCameraPermission(host)) {
                    result.success(mapOf("granted" to true, "permanentlyDenied" to false))
                } else if (permissionResult != null) {
                    result.error("PERMISSION_PENDING", "A camera permission request is already pending.", null)
                } else {
                    permissionResult = result
                    ActivityCompat.requestPermissions(
                        host,
                        arrayOf(Manifest.permission.CAMERA),
                        CAMERA_PERMISSION_REQUEST,
                    )
                }
            }
            "openAppSettings" -> {
                if (host == null) {
                    result.error("NO_ACTIVITY", "App settings need an active screen.", null)
                } else {
                    host.startActivity(
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", host.packageName, null),
                        ),
                    )
                    result.success(null)
                }
            }
            "startTracking" -> {
                if (host == null || controller == null) {
                    result.error("NO_ACTIVITY", "The camera is not available right now.", null)
                } else if (!hasCameraPermission(host)) {
                    result.error("PERMISSION_REQUIRED", "Grant camera permission before tracking.", null)
                } else {
                    controller?.startTracking(result)
                }
            }
            "stopTracking" -> {
                controller?.stopTracking()
                result.success(null)
            }
            "switchCamera" -> controller?.switchCamera(result)
                ?: result.error("NO_ACTIVITY", "The camera is not available right now.", null)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        controller?.setEventSink(events)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        controller?.setEventSink(null)
        controller?.stopTracking()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != CAMERA_PERMISSION_REQUEST) return false

        val host = activity
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        val preferences = host?.getSharedPreferences("movequest_camera", Context.MODE_PRIVATE)
        val hadRequestedBefore = preferences?.getBoolean("requested", false) == true
        preferences?.edit()?.putBoolean("requested", true)?.apply()
        val permanentlyDenied =
            !granted && hadRequestedBefore && host != null &&
                !ActivityCompat.shouldShowRequestPermissionRationale(host, Manifest.permission.CAMERA)
        permissionResult?.success(
            mapOf("granted" to granted, "permanentlyDenied" to permanentlyDenied),
        )
        permissionResult = null
        return true
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        controller = PoseCameraController(binding.activity, binding.activity as LifecycleOwner)
            .also { it.setEventSink(eventSink) }
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = detachActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() = detachActivity()

    private fun detachActivity() {
        controller?.dispose()
        controller = null
        activity = null
        permissionResult = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        controller?.dispose()
        controller = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    private fun hasCameraPermission(host: Activity?): Boolean =
        host != null &&
            ContextCompat.checkSelfPermission(host, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED

    companion object {
        private const val METHOD_CHANNEL = "movequest/pose_camera"
        private const val EVENT_CHANNEL = "movequest/pose_results"
        private const val PREVIEW_VIEW = "movequest/camera_preview"
        private const val CAMERA_PERMISSION_REQUEST = 4172
    }
}
