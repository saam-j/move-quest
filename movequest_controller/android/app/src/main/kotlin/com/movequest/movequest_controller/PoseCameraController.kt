package com.movequest.movequest_controller

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Size
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.core.ImageProxy
import androidx.camera.core.resolutionselector.AspectRatioStrategy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.ImageProcessingOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayDeque
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max

class PoseCameraController(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner,
) {
    val previewView = PreviewView(context).apply {
        scaleType = PreviewView.ScaleType.FILL_CENTER
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        setBackgroundColor(android.graphics.Color.BLACK)
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val analysisExecutor = Executors.newSingleThreadExecutor()
    private val processing = AtomicBoolean(false)
    private val pendingImages = ConcurrentHashMap<Long, MPImage>()
    private val pendingStartNanos = ConcurrentHashMap<Long, Long>()
    private val fpsLock = Any()
    private val resultTimes = ArrayDeque<Long>()
    private val pendingImageSizes = ConcurrentHashMap<Long, Pair<Int, Int>>()
    private val pendingImageRotations = ConcurrentHashMap<Long, Int>()
    @Volatile private var landmarker: PoseLandmarker? = null
    @Volatile private var cameraProvider: ProcessCameraProvider? = null
    @Volatile private var eventSink: EventChannel.EventSink? = null
    @Volatile private var isStarting = false
    @Volatile private var isTracking = false
    @Volatile private var disposed = false
    private var lensFacing = CameraSelector.LENS_FACING_FRONT
    private var lastTimestampMs = 0L

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun startTracking(result: MethodChannel.Result) {
        if (isTracking) {
            result.success(null)
            return
        }
        if (isStarting) {
            result.error("START_PENDING", "Camera setup is already in progress.", null)
            return
        }
        isStarting = true
        sendEvent(mapOf("status" to "initializing"))
        analysisExecutor.execute {
            try {
                val options = PoseLandmarker.PoseLandmarkerOptions.builder()
                    .setBaseOptions(
                        BaseOptions.builder()
                            .setModelAssetPath("pose_landmarker_lite.task")
                            .setDelegate(Delegate.CPU)
                            .build(),
                    )
                    .setRunningMode(RunningMode.LIVE_STREAM)
                    .setNumPoses(1)
                    .setMinPoseDetectionConfidence(0.5f)
                    .setMinPosePresenceConfidence(0.5f)
                    .setMinTrackingConfidence(0.5f)
                    .setResultListener(::onPoseResult)
                    .setErrorListener(::onPoseError)
                    .build()
                val created = PoseLandmarker.createFromOptions(context, options)
                mainHandler.post {
                    if (disposed || !isStarting) {
                        created.close()
                        result.error("START_CANCELLED", "Camera setup was cancelled.", null)
                    } else {
                        landmarker = created
                        bindCamera(result)
                    }
                }
            } catch (error: Exception) {
                Log.e(TAG, "Pose landmarker initialization failed.", error)
                mainHandler.post {
                    isStarting = false
                    result.error("POSE_INITIALIZATION_FAILED", error.message ?: "Could not initialize pose detection.", null)
                    sendEvent(mapOf("status" to "error", "message" to (error.message ?: "Could not initialize pose detection.")))
                }
            }
        }
    }

    private fun bindCamera(result: MethodChannel.Result) {
        val providerFuture = ProcessCameraProvider.getInstance(context)
        providerFuture.addListener(
            {
                try {
                    val provider = providerFuture.get()
                    cameraProvider = provider
                    if (!provider.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)) {
                        lensFacing = CameraSelector.LENS_FACING_BACK
                    }
                    bindUseCases(provider)
                    isTracking = true
                    isStarting = false
                    result.success(null)
                    sendEvent(mapOf("status" to "noPerson"))
                } catch (error: Exception) {
                    Log.e(TAG, "Camera startup failed.", error)
                    isStarting = false
                    landmarker?.close()
                    landmarker = null
                    result.error("CAMERA_START_FAILED", error.message ?: "Could not start the camera.", null)
                    sendEvent(mapOf("status" to "error", "message" to (error.message ?: "Could not start the camera.")))
                }
            },
            ContextCompat.getMainExecutor(context),
        )
    }

    private fun bindUseCases(provider: ProcessCameraProvider) {
        val resolutionSelector = ResolutionSelector.Builder()
            .setAspectRatioStrategy(AspectRatioStrategy.RATIO_4_3_FALLBACK_AUTO_STRATEGY)
            .setResolutionStrategy(
                ResolutionStrategy(
                    Size(480, 360),
                    ResolutionStrategy.FALLBACK_RULE_CLOSEST_LOWER_THEN_HIGHER,
                ),
            )
            .build()
        val preview = Preview.Builder()
            .setResolutionSelector(resolutionSelector)
            .build()
            .also { it.setSurfaceProvider(previewView.surfaceProvider) }
        val analysis = ImageAnalysis.Builder()
            .setResolutionSelector(resolutionSelector)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()
        analysis.setAnalyzer(analysisExecutor, ::analyzeFrame)

        provider.unbindAll()
        provider.bindToLifecycle(
            lifecycleOwner,
            CameraSelector.Builder().requireLensFacing(lensFacing).build(),
            preview,
            analysis,
        )
    }

    private fun analyzeFrame(image: ImageProxy) {
        if (!isTracking && !isStarting || !processing.compareAndSet(false, true)) {
            image.close()
            return
        }

        var input: MPImage? = null
        var timestamp = 0L
        try {
            val rotationDegrees = image.imageInfo.rotationDegrees
            val frame = image.toBitmap()
            input = BitmapImageBuilder(frame).build()
            timestamp = max(SystemClock.uptimeMillis(), lastTimestampMs + 1)
            lastTimestampMs = timestamp
            pendingImages[timestamp] = input
            pendingStartNanos[timestamp] = SystemClock.elapsedRealtimeNanos()
            pendingImageRotations[timestamp] = rotationDegrees
            val swapsDimensions = rotationDegrees == 90 || rotationDegrees == 270
            pendingImageSizes[timestamp] = if (swapsDimensions) {
                frame.height to frame.width
            } else {
                frame.width to frame.height
            }
            val options = ImageProcessingOptions.builder().setRotationDegrees(rotationDegrees).build()
            landmarker?.detectAsync(input, options, timestamp)
                ?: throw IllegalStateException("Pose detector is not initialized.")
        } catch (error: Exception) {
            Log.e(TAG, "Could not submit camera frame for pose inference.", error)
            if (timestamp != 0L) {
                pendingImages.remove(timestamp)?.close()
                pendingStartNanos.remove(timestamp)
                pendingImageSizes.remove(timestamp)
                pendingImageRotations.remove(timestamp)
            } else {
                input?.close()
            }
            processing.set(false)
            mainHandler.post {
                if (isTracking) {
                    sendEvent(mapOf("status" to "error", "message" to (error.message ?: "Could not process camera frame.")))
                }
            }
        } finally {
            image.close()
        }
    }

    private fun onPoseResult(result: PoseLandmarkerResult, input: MPImage) {
        val timestamp = result.timestampMs()
        val startedAt = pendingStartNanos.remove(timestamp)
        val imageSize = pendingImageSizes.remove(timestamp) ?: (input.width to input.height)
        val rotationDegrees = pendingImageRotations.remove(timestamp) ?: 0
        pendingImages.remove(timestamp)?.close()
        processing.set(false)
        if (!isTracking) return

        val now = SystemClock.elapsedRealtime()
        val observedFps = synchronized(fpsLock) {
            resultTimes.addLast(now)
            while (resultTimes.isNotEmpty() && now - resultTimes.first() > 1000L) {
                resultTimes.removeFirst()
            }
            resultTimes.size.toDouble()
        }
        val landmarks = result.landmarks().firstOrNull()
        val pose = landmarks?.map { point ->
            mapOf(
                "x" to point.x().toDouble(),
                "y" to point.y().toDouble(),
                "z" to point.z().toDouble(),
                "visibility" to point.visibility().orElse(0.0f).toDouble(),
                "presence" to point.presence().orElse(0.0f).toDouble(),
            )
        }
        val visible = landmarks
            ?.filterIndexed { index, _ -> index in 11..16 || index in 23..28 }
            ?.map { max(it.visibility().orElse(0.0f), it.presence().orElse(0.0f)) }
            ?.average()
            ?: 0.0

        val payload = mapOf(
            "status" to if (pose.isNullOrEmpty()) "noPerson" else "tracking",
            "landmarks" to (pose ?: emptyList<Map<String, Any>>()),
            "quality" to visible,
            "fps" to observedFps,
            "inferenceMs" to startedAt?.let { (SystemClock.elapsedRealtimeNanos() - it) / 1_000_000.0 },
            "imageWidth" to imageSize.first,
            "imageHeight" to imageSize.second,
            "rotationDegrees" to rotationDegrees,
            "frontCamera" to (lensFacing == CameraSelector.LENS_FACING_FRONT),
        )
        mainHandler.post { sendEvent(payload) }
    }

    private fun onPoseError(error: RuntimeException) {
        Log.e(TAG, "Pose inference failed.", error)
        processing.set(false)
        mainHandler.post {
            sendEvent(mapOf("status" to "error", "message" to (error.message ?: "Pose inference failed.")))
        }
    }

    fun switchCamera(result: MethodChannel.Result) {
        val provider = cameraProvider
        if (!isTracking || provider == null) {
            result.error("TRACKING_STOPPED", "Start tracking before switching cameras.", null)
            return
        }
        val nextLens = if (lensFacing == CameraSelector.LENS_FACING_FRONT) {
            CameraSelector.LENS_FACING_BACK
        } else {
            CameraSelector.LENS_FACING_FRONT
        }
        try {
            val selector = CameraSelector.Builder().requireLensFacing(nextLens).build()
            if (!provider.hasCamera(selector)) {
                result.error("CAMERA_UNAVAILABLE", "That camera is not available on this device.", null)
                return
            }
            lensFacing = nextLens
            bindUseCases(provider)
            result.success(lensFacing == CameraSelector.LENS_FACING_FRONT)
        } catch (error: Exception) {
            result.error("CAMERA_SWITCH_FAILED", error.message ?: "Could not switch cameras.", null)
        }
    }

    fun stopTracking() {
        isStarting = false
        isTracking = false
        cameraProvider?.unbindAll()
        cameraProvider = null
        landmarker?.close()
        landmarker = null
        pendingImages.values.forEach(MPImage::close)
        pendingImages.clear()
        pendingStartNanos.clear()
        pendingImageSizes.clear()
        pendingImageRotations.clear()
        processing.set(false)
        synchronized(fpsLock) { resultTimes.clear() }
        sendEvent(mapOf("status" to "initializing"))
    }

    fun dispose() {
        disposed = true
        stopTracking()
        analysisExecutor.shutdown()
    }

    private fun sendEvent(event: Map<String, Any?>) {
        mainHandler.post { eventSink?.success(event) }
    }

    companion object {
        private const val TAG = "MoveQuestPose"
    }
}
