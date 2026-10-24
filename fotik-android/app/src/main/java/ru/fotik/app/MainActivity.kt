package ru.fotik.app

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.MediaStoreOutputOptions
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : ComponentActivity() {
    private lateinit var previewView: PreviewView
    private lateinit var statusView: TextView
    private lateinit var chooseSongButton: Button
    private lateinit var startButton: Button
    private lateinit var shareButton: Button

    private var videoCapture: VideoCapture<Recorder>? = null
    private var recording: Recording? = null
    private var selectedAudioUri: Uri? = null
    private var lastVideoUri: Uri? = null
    private var mediaPlayer: MediaPlayer? = null
    private var sessionActive = false
    private var startAfterTrackSelection = false

    private val permissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
            if (hasCameraPermission()) {
                bindCamera()
            } else {
                setStatus("Для записи нужно разрешение на камеру.")
            }
        }

    private val audioPicker =
        registerForActivityResult(ActivityResultContracts.GetContent()) { uri ->
            if (uri == null) {
                if (startAfterTrackSelection) {
                    startAfterTrackSelection = false
                    setStatus("Выбор песни отменён. Запись не началась.")
                }
                return@registerForActivityResult
            }

            selectedAudioUri = uri
            chooseSongButton.text = "Сменить песню"
            setStatus("Песня выбрана.")
            if (startAfterTrackSelection) {
                startAfterTrackSelection = false
                startSession()
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildLayout())
        setStatus("Камера показывается на экране. Выберите песню и нажмите «Включить».")

        val missingPermissions = listOf(
            Manifest.permission.CAMERA,
            Manifest.permission.RECORD_AUDIO
        ).filter { permission ->
            ContextCompat.checkSelfPermission(this, permission) !=
                android.content.pm.PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isEmpty()) {
            bindCamera()
        } else {
            permissionLauncher.launch(missingPermissions.toTypedArray())
        }
    }

    private fun buildLayout(): LinearLayout {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(16, 12, 16, 12)
        }

        val title = TextView(this).apply {
            text = AppIdentity.APP_NAME
            textSize = 25f
            gravity = Gravity.CENTER
            setPadding(0, 4, 0, 8)
        }

        statusView = TextView(this).apply {
            textSize = 14f
            setPadding(4, 4, 4, 8)
        }

        previewView = PreviewView(this).apply {
            implementationMode = PreviewView.ImplementationMode.COMPATIBLE
            scaleType = PreviewView.ScaleType.FILL_CENTER
            contentDescription = "Видимое превью камеры"
        }

        chooseSongButton = Button(this).apply {
            text = "Выбрать песню"
            setOnClickListener {
                if (sessionActive || recording != null) {
                    setStatus("Сначала остановите запись.")
                } else {
                    audioPicker.launch("audio/*")
                }
            }
        }

        startButton = Button(this).apply {
            text = "Включить"
            isEnabled = false
            setOnClickListener {
                if (sessionActive || recording != null) {
                    stopSession()
                } else {
                    startSession()
                }
            }
        }

        shareButton = Button(this).apply {
            text = "Поделиться видео"
            isEnabled = false
            setOnClickListener { shareLastVideo() }
        }

        root.addView(title, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ))
        root.addView(statusView, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ))
        root.addView(previewView, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            0,
            1f
        ))
        root.addView(chooseSongButton, buttonLayoutParams())
        root.addView(startButton, buttonLayoutParams())
        root.addView(shareButton, buttonLayoutParams())
        return root
    }

    private fun buttonLayoutParams(): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        )

    private fun bindCamera() {
        startButton.isEnabled = false
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            try {
                val provider = cameraProviderFuture.get()
                val preview = Preview.Builder().build().also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }
                val recorderInstance = Recorder.Builder()
                    .setQualitySelector(QualitySelector.from(Quality.SD))
                    .build()
                val capture = VideoCapture.withOutput(recorderInstance)

                provider.unbindAll()
                provider.bindToLifecycle(
                    this,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    preview,
                    capture
                )

                videoCapture = capture
                startButton.isEnabled = true
                setStatus("Камера готова. Запись начнётся только после нажатия «Включить».")
            } catch (error: Exception) {
                videoCapture = null
                setStatus("Не удалось открыть камеру: ${error.message ?: "неизвестная ошибка"}")
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun startSession() {
        if (sessionActive) return

        if (!hasCameraPermission()) {
            setStatus("Разрешите доступ к камере, чтобы начать запись.")
            permissionLauncher.launch(arrayOf(Manifest.permission.CAMERA))
            return
        }

        if (recording != null) {
            setStatus("Дождитесь завершения предыдущей записи.")
            return
        }

        if (selectedAudioUri == null) {
            startAfterTrackSelection = true
            setStatus("Выберите музыкальный файл. Запись запустится после выбора.")
            audioPicker.launch("audio/*")
            return
        }

        if (videoCapture == null) {
            setStatus("Камера ещё готовится. Попробуйте ещё раз через секунду.")
            bindCamera()
            return
        }

        sessionActive = true
        chooseSongButton.isEnabled = false
        startButton.text = "Остановить"
        shareButton.isEnabled = false
        setMusicVolumeToMaximum()
        startMusicLoop()
        startRecording()
    }

    private fun setMusicVolumeToMaximum() {
        try {
            val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, maxVolume, 0)
        } catch (error: RuntimeException) {
            setStatus("Не удалось изменить громкость: ${error.message ?: "ошибка аудио"}")
        }
    }

    private fun startMusicLoop() {
        val uri = selectedAudioUri ?: return
        mediaPlayer?.release()
        mediaPlayer = null

        try {
            val player = MediaPlayer()
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            player.isLooping = true
            player.setDataSource(this, uri)
            player.setOnPreparedListener { prepared ->
                if (sessionActive && !prepared.isPlaying) {
                    prepared.start()
                }
            }
            player.setOnErrorListener { _, _, _ ->
                setStatus("Не удалось воспроизвести выбранную песню.")
                true
            }
            mediaPlayer = player
            player.prepareAsync()
        } catch (error: Exception) {
            mediaPlayer?.release()
            mediaPlayer = null
            setStatus("Ошибка воспроизведения: ${error.message ?: "неизвестная ошибка"}")
        }
    }

    private fun startRecording() {
        val capture = videoCapture
        if (capture == null) {
            sessionActive = false
            stopMusic()
            startButton.text = "Включить"
            chooseSongButton.isEnabled = true
            setStatus("Камера недоступна. Запись не началась.")
            return
        }

        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "Fotik_$timestamp.mp4")
            put(MediaStore.MediaColumns.MIME_TYPE, "video/mp4")
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                "${Environment.DIRECTORY_MOVIES}/${AppIdentity.MEDIA_FOLDER}"
            )
        }

        val outputOptions = MediaStoreOutputOptions.Builder(
            contentResolver,
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        ).setContentValues(contentValues).build()

        try {
            var pending = capture.output.prepareRecording(this, outputOptions)
            if (hasAudioPermission()) {
                pending = pending.withAudioEnabled()
            }

            recording = pending.start(ContextCompat.getMainExecutor(this)) { event ->
                when (event) {
                    is VideoRecordEvent.Start -> {
                        setStatus(
                            if (hasAudioPermission()) {
                                "Идёт видимая видеозапись. Нажмите «Остановить» для завершения."
                            } else {
                                "Идёт видеозапись без микрофона. Нажмите «Остановить» для завершения."
                            }
                        )
                    }

                    is VideoRecordEvent.Finalize -> {
                        recording = null
                        sessionActive = false
                        stopMusic()
                        startButton.text = "Включить"
                        chooseSongButton.isEnabled = true

                        if (event.error == VideoRecordEvent.Finalize.ERROR_NONE) {
                            lastVideoUri = event.outputResults.outputUri
                            shareButton.isEnabled = true
                            setStatus("Видео сохранено в Movies/Fotik. Отправка выполняется вручную.")
                        } else {
                            setStatus("Ошибка записи видео: ${event.cause?.message ?: event.error}")
                        }
                    }

                    else -> Unit
                }
            }
        } catch (error: Exception) {
            sessionActive = false
            stopMusic()
            startButton.text = "Включить"
            chooseSongButton.isEnabled = true
            setStatus("Не удалось начать запись: ${error.message ?: "неизвестная ошибка"}")
        }
    }

    private fun stopSession() {
        sessionActive = false
        stopMusic()
        recording?.stop()
        startButton.text = "Включить"
        chooseSongButton.isEnabled = true
        setStatus(
            if (recording != null) {
                "Остановка записи… видео будет сохранено после завершения."
            } else {
                "Режим выключен."
            }
        )
    }

    private fun shareLastVideo() {
        val uri = lastVideoUri
        if (uri == null) {
            setStatus("Сначала запишите видео.")
            return
        }

        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "video/mp4"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        try {
            startActivity(Intent.createChooser(sendIntent, "Поделиться видео"))
        } catch (error: Exception) {
            setStatus("Не удалось открыть меню отправки: ${error.message ?: "нет приложения"}")
        }
    }

    private fun stopMusic() {
        mediaPlayer?.release()
        mediaPlayer = null
    }

    private fun hasCameraPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED

    private fun hasAudioPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED

    private fun setStatus(message: String) {
        if (::statusView.isInitialized) {
            statusView.text = message
        }
    }

    override fun onStop() {
        if (sessionActive || recording != null) {
            stopSession()
        }
        super.onStop()
    }

    override fun onDestroy() {
        stopMusic()
        recording?.stop()
        recording = null
        super.onDestroy()
    }
}
