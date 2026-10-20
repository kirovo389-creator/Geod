package com.frilance.game;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import androidx.core.content.FileProvider;
import androidx.webkit.WebViewAssetLoader;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public final class MainActivity extends Activity {
    private static final String RELEASE_API = "https://api.github.com/repos/kirovo389-creator/Geod/releases/latest";
    private static final int INSTALL_PERMISSION_REQUEST = 741;
    private static final long UPDATE_CHECK_INTERVAL = 6L * 60L * 60L * 1000L;

    private final Handler updateHandler = new Handler(Looper.getMainLooper());
    private final ExecutorService updateExecutor = Executors.newSingleThreadExecutor();
    private WebView webView;
    private WebViewAssetLoader assetLoader;
    private volatile boolean updateCheckRunning;
    private File pendingUpdateApk;
    private AlertDialog downloadDialog;

    private final Runnable periodicUpdateCheck = new Runnable() {
        @Override public void run() {
            checkForUpdates(false);
            updateHandler.postDelayed(this, UPDATE_CHECK_INTERVAL);
        }
    };

    @Override
    @SuppressLint("SetJavaScriptEnabled")
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.rgb(11, 14, 18));
        getWindow().setNavigationBarColor(Color.rgb(11, 14, 18));
        getWindow().getDecorView().setSystemUiVisibility(0);

        assetLoader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();
        webView = new WebView(this);
        webView.setBackgroundColor(Color.rgb(11, 14, 18));
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setAllowFileAccess(false);
        settings.setAllowContentAccess(false);
        settings.setSupportZoom(false);
        settings.setBuiltInZoomControls(false);
        settings.setDisplayZoomControls(false);
        settings.setMediaPlaybackRequiresUserGesture(true);
        settings.setJavaScriptCanOpenWindowsAutomatically(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);

        webView.setWebChromeClient(new WebChromeClient());
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                return assetLoader.shouldInterceptRequest(request.getUrl());
            }
        });
        webView.addJavascriptInterface(new UpdateBridge(), "Android");
        setContentView(webView);
        webView.loadUrl("https://appassets.androidplatform.net/assets/index.html");
        updateHandler.postDelayed(() -> checkForUpdates(false), 2500);
        updateHandler.postDelayed(periodicUpdateCheck, UPDATE_CHECK_INTERVAL);
    }

    private final class UpdateBridge {
        @JavascriptInterface public void checkForUpdates() { MainActivity.this.checkForUpdates(true); }
        @JavascriptInterface public String getAppVersion() { return BuildConfig.VERSION_NAME; }
    }

    private void checkForUpdates(boolean userRequested) {
        if (updateCheckRunning) {
            if (userRequested) runOnUiThread(() -> Toast.makeText(this, "Проверка уже выполняется", Toast.LENGTH_SHORT).show());
            return;
        }
        updateCheckRunning = true;
        updateExecutor.execute(() -> {
            try {
                HttpURLConnection connection = (HttpURLConnection) new URL(RELEASE_API).openConnection();
                connection.setRequestMethod("GET");
                connection.setConnectTimeout(12000);
                connection.setReadTimeout(12000);
                connection.setRequestProperty("Accept", "application/vnd.github+json");
                connection.setRequestProperty("User-Agent", "Frilance-Android");
                String body;
                try (InputStream in = connection.getInputStream()) { body = readText(in); }
                finally { connection.disconnect(); }

                JSONObject release = new JSONObject(body);
                String tag = release.optString("tag_name", "");
                int remoteCode = releaseCode(tag);
                String apkUrl = findApkUrl(release.optJSONArray("assets"));
                if (remoteCode <= BuildConfig.VERSION_CODE || apkUrl == null) {
                    if (userRequested) runOnUiThread(() ->
                            Toast.makeText(this, remoteCode <= BuildConfig.VERSION_CODE
                                    ? "Установлена последняя версия" : "APK не найден в последнем релизе",
                                    Toast.LENGTH_LONG).show());
                    return;
                }
                SharedPreferences prefs = getSharedPreferences("frilance_updater", MODE_PRIVATE);
                String lastOffered = prefs.getString("last_offered_release", "");
                if (!userRequested && tag.equals(lastOffered)) return;
                runOnUiThread(() -> offerUpdate(tag, apkUrl, prefs));
            } catch (Exception e) {
                if (userRequested) runOnUiThread(() ->
                        Toast.makeText(this, "Не удалось проверить релизы. Проверь интернет.", Toast.LENGTH_LONG).show());
            } finally { updateCheckRunning = false; }
        });
    }

    private static int releaseCode(String tag) {
        String prefix = "frilance-v1.0.";
        if (!tag.startsWith(prefix)) return 0;
        try { return Integer.parseInt(tag.substring(prefix.length())); }
        catch (NumberFormatException e) { return 0; }
    }

    private static String findApkUrl(JSONArray assets) {
        if (assets == null) return null;
        for (int i = 0; i < assets.length(); i++) {
            JSONObject asset = assets.optJSONObject(i);
            if (asset != null && "Frilance.apk".equals(asset.optString("name"))) {
                String url = asset.optString("browser_download_url", "");
                if (url.startsWith("https://")) return url;
            }
        }
        return null;
    }

    private void offerUpdate(String tag, String apkUrl, SharedPreferences prefs) {
        if (isFinishing()) return;
        prefs.edit().putString("last_offered_release", tag).apply();
        String version = tag.replace("frilance-v", "");
        new AlertDialog.Builder(this).setTitle("Доступно обновление")
                .setMessage("Frilance " + version + " уже доступна. Скачать APK и открыть установщик Android?")
                .setPositiveButton("Скачать и установить", (dialog, which) -> downloadAndInstall(apkUrl))
                .setNegativeButton("Позже", null).show();
    }

    private void downloadAndInstall(String url) {
        ProgressDialog progress = new ProgressDialog(this);
        progress.setMessage("Загрузка обновления…");
        progress.setIndeterminate(true);
        progress.setCancelable(false);
        progress.show();
        downloadDialog = progress;
        updateExecutor.execute(() -> {
            File apk = null;
            Exception failure = null;
            try {
                File dir = new File(getCacheDir(), "updates");
                if (!dir.exists() && !dir.mkdirs()) throw new IllegalStateException("Не удалось создать каталог загрузки");
                apk = new File(dir, "Frilance.apk");
                HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
                connection.setConnectTimeout(15000);
                connection.setReadTimeout(30000);
                connection.setInstanceFollowRedirects(true);
                connection.setRequestProperty("User-Agent", "Frilance-Android");
                try (InputStream in = connection.getInputStream(); FileOutputStream out = new FileOutputStream(apk)) {
                    byte[] buffer = new byte[16384];
                    int count;
                    long total = 0;
                    while ((count = in.read(buffer)) != -1) {
                        total += count;
                        if (total > 100L * 1024L * 1024L) throw new IllegalStateException("Размер APK превышает лимит");
                        out.write(buffer, 0, count);
                    }
                    if (total < 100000L) throw new IllegalStateException("Загруженный APK слишком мал");
                } finally { connection.disconnect(); }
            } catch (Exception e) {
                failure = e;
                if (apk != null && apk.exists()) apk.delete();
            }
            File finalApk = apk;
            Exception finalFailure = failure;
            runOnUiThread(() -> {
                if (downloadDialog != null && downloadDialog.isShowing()) downloadDialog.dismiss();
                downloadDialog = null;
                if (finalFailure != null || finalApk == null || !finalApk.isFile()) {
                    Toast.makeText(this, "Не удалось загрузить APK. Попробуй позже.", Toast.LENGTH_LONG).show();
                    return;
                }
                pendingUpdateApk = finalApk;
                startInstallFlow(finalApk);
            });
        });
    }

    private void startInstallFlow(File apk) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !getPackageManager().canRequestPackageInstalls()) {
            new AlertDialog.Builder(this).setTitle("Разрешение на установку")
                    .setMessage("Android должен разрешить установку обновлений из Frilance. Включи разрешение на следующем экране, затем вернись в приложение.")
                    .setPositiveButton("Открыть настройки", (dialog, which) ->
                            startActivityForResult(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                    Uri.parse("package:" + getPackageName())), INSTALL_PERMISSION_REQUEST))
                    .setNegativeButton("Отмена", null).show();
            return;
        }
        installApk(apk);
    }

    private void installApk(File apk) {
        try {
            Uri uri = FileProvider.getUriForFile(this, getPackageName() + ".fileprovider", apk);
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setDataAndType(uri, "application/vnd.android.package-archive");
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        } catch (Exception e) {
            Toast.makeText(this, "Не удалось открыть установщик Android", Toast.LENGTH_LONG).show();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == INSTALL_PERMISSION_REQUEST) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || getPackageManager().canRequestPackageInstalls()) {
                if (pendingUpdateApk != null && pendingUpdateApk.exists()) installApk(pendingUpdateApk);
            } else Toast.makeText(this, "Разрешение не выдано; обновление можно скачать ещё раз.", Toast.LENGTH_LONG).show();
        }
    }

    private static String readText(InputStream in) throws Exception {
        StringBuilder out = new StringBuilder();
        byte[] buffer = new byte[4096];
        int count;
        while ((count = in.read(buffer)) != -1) out.append(new String(buffer, 0, count, java.nio.charset.StandardCharsets.UTF_8));
        return out.toString();
    }

    @Override @SuppressWarnings("deprecation")
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }

    @Override
    protected void onDestroy() {
        updateHandler.removeCallbacksAndMessages(null);
        if (downloadDialog != null && downloadDialog.isShowing()) downloadDialog.dismiss();
        updateExecutor.shutdownNow();
        if (webView != null) {
            webView.loadUrl("about:blank");
            webView.stopLoading();
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
