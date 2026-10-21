package com.frilance.game;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.ProgressDialog;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.text.InputType;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.core.content.FileProvider;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public final class MainActivity extends Activity {
    private static final String RELEASE_API = "https://api.github.com/repos/kirovo389-creator/Geod/releases/latest";
    private static final int INSTALL_PERMISSION_REQUEST = 741;
    private static final int NOTIFICATION_PERMISSION_REQUEST = 742;
    private static final long UPDATE_CHECK_INTERVAL = 6L * 60L * 60L * 1000L;
    private static final long MARKET_REFRESH_MS = 3_000L;
    private static final long ALL_MARKETS_REFRESH_MS = 15_000L;
    private static final long DROP_ALERT_COOLDOWN_MS = 6L * 60L * 60L * 1000L;

    private static final int BG = Color.rgb(8, 13, 19);
    private static final int PANEL = Color.rgb(15, 23, 32);
    private static final int PANEL_HI = Color.rgb(21, 32, 43);
    private static final int LINE = Color.rgb(37, 49, 60);
    private static final int MUTED = Color.rgb(133, 151, 165);
    private static final int WHITE = Color.rgb(236, 244, 248);
    private static final int MINT = Color.rgb(76, 190, 145);
    private static final int RED = Color.rgb(222, 85, 100);
    private static final String ALERT_CHANNEL = "market_alerts";

    private final List<Asset> assets = new ArrayList<>(Arrays.asList(
            new Asset("BTC", "Bitcoin", "BTC", "BTCUSDT", "binance", "", "₿"),
            new Asset("ETH", "Ethereum", "ETH", "ETHUSDT", "binance", "", "E"),
            new Asset("SOL", "Solana", "SOL", "SOLUSDT", "binance", "", "S"),
            new Asset("BNB", "BNB", "BNB", "BNBUSDT", "binance", "", "B"),
            new Asset("XRP", "XRP", "XRP", "XRPUSDT", "binance", "", "X"),
            new Asset("DOGE", "Dogecoin", "DOGE", "DOGEUSDT", "binance", "", "D"),
            new Asset("ADA", "Cardano", "ADA", "ADAUSDT", "binance", "", "A"),
            new Asset("LINK", "Chainlink", "LINK", "LINKUSDT", "binance", "", "L"),
            new Asset("TRX", "TRON", "TRX", "TRXUSDT", "binance", "", "T"),
            new Asset("AVAX", "Avalanche", "AVAX", "AVAXUSDT", "binance", "", "A"),
            new Asset("DOT", "Polkadot", "DOT", "DOTUSDT", "binance", "", "P"),
            new Asset("LTC", "Litecoin", "LTC", "LTCUSDT", "binance", "", "Ł"),
            new Asset("BCH", "Bitcoin Cash", "BCH", "BCHUSDT", "binance", "", "B"),
            new Asset("NEAR", "NEAR Protocol", "NEAR", "NEARUSDT", "binance", "", "N"),
            new Asset("UNI", "Uniswap", "UNI", "UNIUSDT", "binance", "", "U"),
            new Asset("AAVE", "Aave", "AAVE", "AAVEUSDT", "binance", "", "A"),
            new Asset("ETC", "Ethereum Classic", "ETC", "ETCUSDT", "binance", "", "E"),
            new Asset("XLM", "Stellar", "XLM", "XLMUSDT", "binance", "", "X"),
            new Asset("ATOM", "Cosmos", "ATOM", "ATOMUSDT", "binance", "", "C"),
            new Asset("ICP", "Internet Computer", "ICP", "ICPUSDT", "binance", "", "I"),
            new Asset("FIL", "Filecoin", "FIL", "FILUSDT", "binance", "", "F"),
            new Asset("OP", "Optimism", "OP", "OPUSDT", "binance", "", "O"),
            new Asset("ARB", "Arbitrum", "ARB", "ARBUSDT", "binance", "", "A"),
            new Asset("SUI", "Sui", "SUI", "SUIUSDT", "binance", "", "S"),
            new Asset("APT", "Aptos", "APT", "APTUSDT", "binance", "", "A"),
            new Asset("TIA", "Celestia", "TIA", "TIAUSDT", "binance", "", "T"),
            new Asset("INJ", "Injective", "INJ", "INJUSDT", "binance", "", "I"),
            new Asset("SEI", "Sei", "SEI", "SEIUSDT", "binance", "", "S"),
            new Asset("TON", "Toncoin", "TON", "TONUSDT", "binance", "", "T"),
            new Asset("SHIB", "Shiba Inu", "SHIB", "SHIBUSDT", "binance", "", "S"),
            new Asset("PEPE", "Pepe", "PEPE", "PEPEUSDT", "binance", "", "P"),
            new Asset("FLOKI", "FLOKI", "FLOKI", "FLOKIUSDT", "binance", "", "F"),
            new Asset("BONK", "Bonk", "BONK", "BONKUSDT", "binance", "", "B"),
            new Asset("WIF", "dogwifhat", "WIF", "WIFUSDT", "binance", "", "W"),
            new Asset("RENDER", "Render", "RENDER", "RENDERUSDT", "binance", "", "R"),
            new Asset("FET", "Artificial Superintelligence", "FET", "FETUSDT", "binance", "", "F"),
            new Asset("STX", "Stacks", "STX", "STXUSDT", "binance", "", "S"),
            new Asset("IMX", "Immutable", "IMX", "IMXUSDT", "binance", "", "I"),
            new Asset("GRT", "The Graph", "GRT", "GRTUSDT", "binance", "", "G"),
            new Asset("LDO", "Lido DAO", "LDO", "LDOUSDT", "binance", "", "L"),
            new Asset("ENS", "Ethereum Name Service", "ENS", "ENSUSDT", "binance", "", "E"),
            new Asset("SAND", "The Sandbox", "SAND", "SANDUSDT", "binance", "", "S"),
            new Asset("MANA", "Decentraland", "MANA", "MANAUSDT", "binance", "", "M"),
            new Asset("AXS", "Axie Infinity", "AXS", "AXSUSDT", "binance", "", "A"),
            new Asset("CHZ", "Chiliz", "CHZ", "CHZUSDT", "binance", "", "C"),
            new Asset("CRV", "Curve DAO", "CRV", "CRVUSDT", "binance", "", "C"),
            new Asset("COMP", "Compound", "COMP", "COMPUSDT", "binance", "", "C"),
            new Asset("DYDX", "dYdX", "DYDX", "DYDXUSDT", "binance", "", "D"),
            new Asset("SNX", "Synthetix", "SNX", "SNXUSDT", "binance", "", "S"),
            new Asset("ALGO", "Algorand", "ALGO", "ALGOUSDT", "binance", "", "A"),
            new Asset("VET", "VeChain", "VET", "VETUSDT", "binance", "", "V"),
            new Asset("HBAR", "Hedera", "HBAR", "HBARUSDT", "binance", "", "H"),
            new Asset("THETA", "Theta Network", "THETA", "THETAUSDT", "binance", "", "T"),
            new Asset("KAVA", "Kava", "KAVA", "KAVAUSDT", "binance", "", "K"),
            new Asset("EGLD", "MultiversX", "EGLD", "EGLDUSDT", "binance", "", "E"),
            new Asset("ZEC", "Zcash", "ZEC", "ZECUSDT", "binance", "", "Z"),
            new Asset("DASH", "Dash", "DASH", "DASHUSDT", "binance", "", "D"),
            new Asset("XTZ", "Tezos", "XTZ", "XTZUSDT", "binance", "", "T"),
            new Asset("IOTA", "IOTA", "IOTA", "IOTAUSDT", "binance", "", "I"),
            new Asset("RUNE", "THORChain", "RUNE", "RUNEUSDT", "binance", "", "R"),
            new Asset("MINA", "Mina", "MINA", "MINAUSDT", "binance", "", "M"),
            new Asset("ROSE", "Oasis Network", "ROSE", "ROSEUSDT", "binance", "", "R"),
            new Asset("CELO", "Celo", "CELO", "CELOUSDT", "binance", "", "C"),
            new Asset("LPT", "Livepeer", "LPT", "LPTUSDT", "binance", "", "L"),
            new Asset("ENA", "Ethena", "ENA", "ENAUSDT", "binance", "", "E"),
            new Asset("WLD", "Worldcoin", "WLD", "WLDUSDT", "binance", "", "W"),
            new Asset("NOT", "Notcoin", "NOT", "NOTUSDT", "binance", "", "N"),
            new Asset("STRK", "Starknet", "STRK", "STRKUSDT", "binance", "", "S"),
            new Asset("ZK", "zkSync", "ZK", "ZKUSDT", "binance", "", "Z"),
            new Asset("BLUR", "Blur", "BLUR", "BLURUSDT", "binance", "", "B"),
            new Asset("ORDI", "ORDI", "ORDI", "ORDIUSDT", "binance", "", "O"),
            new Asset("GALA", "Gala", "GALA", "GALAUSDT", "binance", "", "G"),
            new Asset("PENDLE", "Pendle", "PENDLE", "PENDLEUSDT", "binance", "", "P"),
            new Asset("JUP", "Jupiter", "JUP", "JUPUSDT", "binance", "", "J"),
            new Asset("PYTH", "Pyth Network", "PYTH", "PYTHUSDT", "binance", "", "P"),
            new Asset("POL", "POL", "POL", "POLUSDT", "binance", "", "P"),
            new Asset("TWT", "Trust Wallet Token", "TWT", "TWTUSDT", "binance", "", "T"),
            new Asset("CAKE", "PancakeSwap", "CAKE", "CAKEUSDT", "binance", "", "C"),
            new Asset("1INCH", "1inch", "1INCH", "1INCHUSDT", "binance", "", "1"),
            new Asset("ARKM", "Arkham", "ARKM", "ARKMUSDT", "binance", "", "A"),
            new Asset("QTUM", "Qtum", "QTUM", "QTUMUSDT", "binance", "", "Q"),
            new Asset("BAT", "Basic Attention Token", "BAT", "BATUSDT", "binance", "", "B"),
            new Asset("RVN", "Ravencoin", "RVN", "RVNUSDT", "binance", "", "R"),
            new Asset("ANKR", "Ankr", "ANKR", "ANKRUSDT", "binance", "", "A")
    ));

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final ExecutorService marketExecutor = Executors.newFixedThreadPool(4);
    private final ExecutorService updateExecutor = Executors.newSingleThreadExecutor();
    private final Set<String> pendingQuotes = ConcurrentHashMap.newKeySet();
    private final Set<String> pendingCandles = ConcurrentHashMap.newKeySet();
    private boolean allQuotesPending;
    private final Map<String, Quote> quotes = new LinkedHashMap<>();
    private final Map<String, BigDecimal> holdings = new HashMap<>();
    private final Map<String, BigDecimal> costBasis = new HashMap<>();
    private final Map<String, List<BigDecimal>> recentPrices = new HashMap<>();
    private final List<Trade> trades = new ArrayList<>();

    private SharedPreferences preferences;
    private BigDecimal cash = new BigDecimal("5.00");
    private String selectedAssetId = "BTC";
    private String currentTab = "chart";
    private String currentInterval = "15m";
    private long lastAllMarketRefresh;
    private long lastCandleRefresh;
    private boolean updateCheckRunning;
    private boolean notificationPermissionAsked;
    private File pendingUpdateApk;
    private ProgressDialog downloadDialog;

    private LinearLayout root;
    private LinearLayout header;
    private FrameLayout screenHost;
    private LinearLayout tradeDock;
    private LinearLayout bottomNav;
    private TextView headerEquity;
    private TextView headerCash;
    private TextView headerLive;
    private TextView selectedPriceText;
    private TextView selectedChangeText;
    private TextView selectedPositionText;
    private EditText amountInput;
    private NativeChartView chartView;
    private ScrollView marketScroll;
    private final Map<String, TextView> marketPriceViews = new HashMap<>();
    private final Map<String, TextView> marketChangeViews = new HashMap<>();
    private final Map<String, TextView> marketStatusViews = new HashMap<>();

    private final Runnable periodicUpdateCheck = new Runnable() {
        @Override public void run() {
            checkForUpdates(false);
            handler.postDelayed(this, UPDATE_CHECK_INTERVAL);
        }
    };

    private final Runnable marketTicker = new Runnable() {
        @Override public void run() {
            requestQuote(assetById(selectedAssetId));
            long now = System.currentTimeMillis();
            if (now - lastAllMarketRefresh >= ALL_MARKETS_REFRESH_MS) {
                lastAllMarketRefresh = now;
                requestAllQuotes();
            }
            if (currentTab.equals("chart") && now - lastCandleRefresh >= 60_000L) {
                requestCandles();
            }
            handler.postDelayed(this, MARKET_REFRESH_MS);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Window window = getWindow();
        window.setStatusBarColor(BG);
        window.setNavigationBarColor(BG);
        window.getDecorView().setSystemUiVisibility(0);
        preferences = getSharedPreferences("frilance_native_state", MODE_PRIVATE);
        loadState();
        createNotificationChannel();
        requestNotificationPermission();
        renderRoot();
        requestAllQuotes();
        lastAllMarketRefresh = System.currentTimeMillis();
        handler.postDelayed(() -> requestCandles(), 700);
        handler.postDelayed(marketTicker, MARKET_REFRESH_MS);
        handler.postDelayed(() -> checkForUpdates(false), 2500);
        handler.postDelayed(periodicUpdateCheck, UPDATE_CHECK_INTERVAL);
    }

    private void loadState() {
        String savedCash = preferences.getString("cash", null);
        cash = savedCash == null ? new BigDecimal("5.00") : decimal(savedCash, BigDecimal.ZERO);
        readDecimalMap(preferences.getString("holdings", "{}"), holdings);
        readDecimalMap(preferences.getString("cost_basis", "{}"), costBasis);
        try {
            JSONObject savedPrices = new JSONObject(preferences.getString("prices", "{}"));
            Iterator<String> keys = savedPrices.keys();
            while (keys.hasNext()) {
                String key = keys.next();
                JSONObject object = savedPrices.optJSONObject(key);
                if (object == null) continue;
                BigDecimal price = decimal(object.optString("price", "0"), BigDecimal.ZERO);
                BigDecimal change = decimal(object.optString("change", "0"), BigDecimal.ZERO);
                if (price.signum() > 0) quotes.put(key, new Quote(price, change, "Кэш", System.currentTimeMillis()));
            }
        } catch (Exception ignored) { }
        try {
            JSONArray savedTrades = new JSONArray(preferences.getString("trades", "[]"));
            for (int i = 0; i < savedTrades.length() && i < 80; i++) {
                JSONObject object = savedTrades.optJSONObject(i);
                if (object == null) continue;
                trades.add(new Trade(
                        object.optLong("time"),
                        object.optString("side", "BUY"),
                        object.optString("asset", "BTC"),
                        decimal(object.optString("quantity", "0"), BigDecimal.ZERO),
                        decimal(object.optString("price", "0"), BigDecimal.ZERO),
                        decimal(object.optString("amount", "0"), BigDecimal.ZERO),
                        decimal(object.optString("pnl", "0"), BigDecimal.ZERO)
                ));
            }
        } catch (Exception ignored) { }
        for (Asset asset : assets) recentPrices.put(asset.id, new ArrayList<>());
    }

    private void readDecimalMap(String json, Map<String, BigDecimal> target) {
        try {
            JSONObject object = new JSONObject(json);
            Iterator<String> keys = object.keys();
            while (keys.hasNext()) {
                String key = keys.next();
                BigDecimal value = decimal(object.optString(key, "0"), BigDecimal.ZERO);
                if (value.signum() > 0) target.put(key, value);
            }
        } catch (Exception ignored) { }
    }

    private void saveState() {
        JSONObject savedHoldings = decimalMapJson(holdings);
        JSONObject savedBasis = decimalMapJson(costBasis);
        JSONArray savedTrades = new JSONArray();
        for (int i = 0; i < trades.size() && i < 80; i++) {
            Trade trade = trades.get(i);
            JSONObject item = new JSONObject();
            try {
                item.put("time", trade.time);
                item.put("side", trade.side);
                item.put("asset", trade.assetId);
                item.put("quantity", trade.quantity.toPlainString());
                item.put("price", trade.price.toPlainString());
                item.put("amount", trade.amount.toPlainString());
                item.put("pnl", trade.pnl.toPlainString());
                savedTrades.put(item);
            } catch (Exception ignored) { }
        }
        preferences.edit()
                .putString("cash", cash.toPlainString())
                .putString("holdings", savedHoldings.toString())
                .putString("cost_basis", savedBasis.toString())
                .putString("trades", savedTrades.toString())
                .apply();
    }

    private JSONObject decimalMapJson(Map<String, BigDecimal> map) {
        JSONObject object = new JSONObject();
        for (Map.Entry<String, BigDecimal> entry : map.entrySet()) {
            try { object.put(entry.getKey(), entry.getValue().toPlainString()); }
            catch (Exception ignored) { }
        }
        return object;
    }

    private void savePriceCache() {
        JSONObject saved = new JSONObject();
        for (Map.Entry<String, Quote> entry : quotes.entrySet()) {
            try {
                JSONObject value = new JSONObject();
                value.put("price", entry.getValue().price.toPlainString());
                value.put("change", entry.getValue().change.toPlainString());
                saved.put(entry.getKey(), value);
            } catch (Exception ignored) { }
        }
        preferences.edit().putString("prices", saved.toString()).apply();
    }

    private void renderRoot() {
        root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(BG);
        root.setFocusableInTouchMode(true);

        header = createHeader();
        root.addView(header, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(64)));

        screenHost = new FrameLayout(this);
        root.addView(screenHost, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));

        tradeDock = createTradeDock();
        root.addView(tradeDock, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        bottomNav = createBottomNav();
        root.addView(bottomNav, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(60)));
        setContentView(root);
        renderCurrentScreen();
        updateHeader();
    }

    private LinearLayout createHeader() {
        LinearLayout bar = new LinearLayout(this);
        bar.setGravity(Gravity.CENTER_VERTICAL);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setPadding(dp(18), dp(6), dp(16), dp(6));
        bar.setBackgroundColor(BG);

        LinearLayout brand = new LinearLayout(this);
        brand.setOrientation(LinearLayout.VERTICAL);
        brand.setGravity(Gravity.CENTER_VERTICAL);
        TextView title = text("FRILANCE", 18, WHITE, true);
        title.setLetterSpacing(0.10f);
        TextView subtitle = text("VIRTUAL MARKET", 9, MUTED, true);
        subtitle.setLetterSpacing(0.17f);
        brand.addView(title);
        brand.addView(subtitle);
        bar.addView(brand, new LinearLayout.LayoutParams(0, -2, 1f));

        LinearLayout wallet = new LinearLayout(this);
        wallet.setOrientation(LinearLayout.VERTICAL);
        wallet.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL);
        headerEquity = text("ДОСТУПНО $5.00", 14, MINT, true);
        headerEquity.setGravity(Gravity.RIGHT);
        headerCash = text("КАПИТАЛ $5.00", 9, MUTED, true);
        headerCash.setGravity(Gravity.RIGHT);
        wallet.addView(headerEquity);
        wallet.addView(headerCash);
        bar.addView(wallet, new LinearLayout.LayoutParams(-2, -2));
        return bar;
    }

    private LinearLayout createTradeDock() {
        LinearLayout dock = new LinearLayout(this);
        dock.setOrientation(LinearLayout.VERTICAL);
        dock.setPadding(dp(12), dp(9), dp(12), dp(10));
        dock.setBackground(background(PANEL, 0, LINE));

        amountInput = new EditText(this);
        amountInput.setTextColor(WHITE);
        amountInput.setHintTextColor(MUTED);
        amountInput.setTextSize(15);
        amountInput.setSingleLine(true);
        amountInput.setSelectAllOnFocus(true);
        amountInput.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);
        amountInput.setPadding(dp(12), 0, dp(8), 0);
        amountInput.setHint("Сумма в USD");
        amountInput.setText("1.00");
        amountInput.setBackground(background(Color.rgb(9, 16, 23), 10, LINE));
        dock.addView(amountInput, new LinearLayout.LayoutParams(-1, dp(43)));

        LinearLayout actionRow = new LinearLayout(this);
        actionRow.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams actionParams = new LinearLayout.LayoutParams(-1, dp(45));
        actionParams.topMargin = dp(8);

        Button buy = button("КУПИТЬ", MINT, Color.rgb(7, 24, 19));
        buy.setTextSize(13);
        buy.setOnClickListener(v -> executeTrade(true));
        actionRow.addView(buy, new LinearLayout.LayoutParams(0, -1, 1f));

        Button sell = button("ПРОДАТЬ", Color.rgb(74, 31, 41), RED);
        sell.setTextSize(13);
        sell.setOnClickListener(v -> executeTrade(false));
        LinearLayout.LayoutParams sellParams = new LinearLayout.LayoutParams(0, -1, 1f);
        sellParams.leftMargin = dp(8);
        actionRow.addView(sell, sellParams);
        dock.addView(actionRow, actionParams);
        return dock;
    }

    private LinearLayout createBottomNav() {
        LinearLayout nav = new LinearLayout(this);
        nav.setOrientation(LinearLayout.HORIZONTAL);
        nav.setGravity(Gravity.CENTER);
        nav.setPadding(dp(8), dp(4), dp(8), dp(5));
        nav.setBackground(background(BG, 0, LINE));
        addNavButton(nav, "chart", "⌁", "ГРАФИК");
        addNavButton(nav, "market", "≋", "РЫНОК");
        addNavButton(nav, "portfolio", "▤", "ПОРТФЕЛЬ");
        return nav;
    }

    private void addNavButton(LinearLayout nav, String tab, String icon, String label) {
        LinearLayout button = new LinearLayout(this);
        button.setOrientation(LinearLayout.VERTICAL);
        button.setGravity(Gravity.CENTER);
        button.setPadding(dp(4), dp(2), dp(4), dp(2));
        TextView iconText = text(icon, 20, currentTab.equals(tab) ? MINT : MUTED, true);
        iconText.setGravity(Gravity.CENTER);
        TextView labelText = text(label, 9, currentTab.equals(tab) ? MINT : MUTED, true);
        labelText.setGravity(Gravity.CENTER);
        labelText.setLetterSpacing(0.05f);
        button.addView(iconText);
        button.addView(labelText);
        button.setOnClickListener(v -> {
            if (!currentTab.equals(tab)) {
                currentTab = tab;
                renderCurrentScreen();
                updateBottomNav();
            }
        });
        nav.addView(button, new LinearLayout.LayoutParams(0, -1, 1f));
    }

    private void updateBottomNav() {
        if (bottomNav == null) return;
        bottomNav.removeAllViews();
        addNavButton(bottomNav, "chart", "⌁", "ГРАФИК");
        addNavButton(bottomNav, "market", "≋", "РЫНОК");
        addNavButton(bottomNav, "portfolio", "▤", "ПОРТФЕЛЬ");
    }

    private void renderCurrentScreen() {
        if (screenHost == null) return;
        screenHost.removeAllViews();
        marketPriceViews.clear();
        marketChangeViews.clear();
        marketStatusViews.clear();
        tradeDock.setVisibility(currentTab.equals("chart") ? View.VISIBLE : View.GONE);

        if (currentTab.equals("chart")) renderChartScreen();
        else if (currentTab.equals("market")) renderMarketScreen();
        else renderPortfolioScreen();

        updateHeader();
        updateBottomNav();
    }

    private void renderChartScreen() {
        Asset asset = assetById(selectedAssetId);
        LinearLayout screen = new LinearLayout(this);
        screen.setOrientation(LinearLayout.VERTICAL);
        screen.setPadding(dp(14), dp(6), dp(14), dp(2));
        screen.setBackgroundColor(BG);

        LinearLayout coinLine = new LinearLayout(this);
        coinLine.setGravity(Gravity.CENTER_VERTICAL);
        coinLine.setOrientation(LinearLayout.HORIZONTAL);

        TextView icon = coinIcon(asset, 42);
        coinLine.addView(icon, new LinearLayout.LayoutParams(dp(42), dp(42)));
        LinearLayout.LayoutParams nameParams = new LinearLayout.LayoutParams(0, -2, 1f);
        nameParams.leftMargin = dp(10);
        LinearLayout nameBox = new LinearLayout(this);
        nameBox.setOrientation(LinearLayout.VERTICAL);
        nameBox.addView(text(asset.name, 16, WHITE, true));
        TextView ticker = text(asset.symbol + "  ·  " + quoteSource(asset), 10, MUTED, false);
        nameBox.addView(ticker);
        coinLine.addView(nameBox, nameParams);

        LinearLayout priceBox = new LinearLayout(this);
        priceBox.setGravity(Gravity.RIGHT);
        priceBox.setOrientation(LinearLayout.VERTICAL);
        selectedPriceText = text(priceFor(asset), 18, WHITE, true);
        selectedPriceText.setGravity(Gravity.RIGHT);
        selectedChangeText = text(changeFor(asset), 11, MUTED, true);
        selectedChangeText.setGravity(Gravity.RIGHT);
        priceBox.addView(selectedPriceText);
        priceBox.addView(selectedChangeText);
        coinLine.addView(priceBox, new LinearLayout.LayoutParams(-2, -2));
        screen.addView(coinLine, new LinearLayout.LayoutParams(-1, dp(55)));

        selectedPositionText = text(positionSummary(asset), 10, MUTED, false);
        selectedPositionText.setMaxLines(1);
        selectedPositionText.setEllipsize(TextUtils.TruncateAt.END);
        selectedPositionText.setPadding(dp(2), dp(5), dp(2), dp(2));
        screen.addView(selectedPositionText, new LinearLayout.LayoutParams(-1, dp(26)));

        chartView = new NativeChartView(this);
        chartView.setData(candlesForCurrentAsset(), recentPrices.get(asset.id),
                quoteFor(asset) == null ? BigDecimal.ZERO : quoteFor(asset).price);
        LinearLayout.LayoutParams chartParams = new LinearLayout.LayoutParams(-1, 0, 1f);
        chartParams.topMargin = dp(2);
        chartParams.bottomMargin = dp(2);
        screen.addView(chartView, chartParams);

        LinearLayout timeframeRow = new LinearLayout(this);
        timeframeRow.setGravity(Gravity.CENTER_VERTICAL);
        timeframeRow.setOrientation(LinearLayout.HORIZONTAL);
        timeframeRow.setPadding(0, dp(2), 0, dp(4));
        for (String interval : new String[]{"15m", "1h", "4h", "1d"}) {
            String label = interval.equals("15m") ? "15м" :
                    interval.equals("1h") ? "1ч" : interval.equals("4h") ? "4ч" : "1д";
            Button b = button(label, currentInterval.equals(interval) ? Color.rgb(20, 57, 47) : PANEL,
                    currentInterval.equals(interval) ? MINT : MUTED);
            b.setTextSize(11);
            b.setPadding(dp(10), 0, dp(10), 0);
            b.setOnClickListener(v -> {
                currentInterval = interval;
                lastCandleRefresh = 0;
                renderCurrentScreen();
                requestCandles();
            });
            LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, dp(32), 1f);
            p.rightMargin = dp(5);
            timeframeRow.addView(b, p);
        }
        Button refresh = button("↻", PANEL, WHITE);
        refresh.setOnClickListener(v -> {
            lastCandleRefresh = 0;
            requestQuote(assetById(selectedAssetId));
            requestCandles();
        });
        timeframeRow.addView(refresh, new LinearLayout.LayoutParams(dp(39), dp(32)));
        screen.addView(timeframeRow);

        screenHost.addView(screen, new FrameLayout.LayoutParams(-1, -1));
    }

    private void renderMarketScreen() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setClipToPadding(false);
        scroll.setBackgroundColor(BG);
        marketScroll = scroll;

        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(16), dp(14), dp(16), dp(18));

        content.addView(text("Выбор рынка", 23, WHITE, true));
        TextView desc = text("Реальные котировки · выбери актив для графика", 12, MUTED, false);
        LinearLayout.LayoutParams descParams = new LinearLayout.LayoutParams(-1, -2);
        descParams.topMargin = dp(4);
        descParams.bottomMargin = dp(15);
        content.addView(desc, descParams);

        for (Asset asset : assets) {
            LinearLayout card = new LinearLayout(this);
            card.setGravity(Gravity.CENTER_VERTICAL);
            card.setOrientation(LinearLayout.HORIZONTAL);
            card.setPadding(dp(12), dp(12), dp(12), dp(12));
            card.setBackground(background(asset.id.equals(selectedAssetId) ? Color.rgb(17, 39, 35) : PANEL,
                    14, asset.id.equals(selectedAssetId) ? Color.rgb(39, 114, 88) : LINE));

            TextView icon = coinIcon(asset, 42);
            card.addView(icon, new LinearLayout.LayoutParams(dp(42), dp(42)));

            LinearLayout titleBox = new LinearLayout(this);
            titleBox.setOrientation(LinearLayout.VERTICAL);
            titleBox.addView(text(asset.name, 14, WHITE, true));
            TextView symbolView = text(asset.symbol + " · " + quoteSource(asset), 10, MUTED, false);
            titleBox.addView(symbolView);
            LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(0, -2, 1f);
            titleParams.leftMargin = dp(11);
            card.addView(titleBox, titleParams);

            LinearLayout quoteBox = new LinearLayout(this);
            quoteBox.setGravity(Gravity.RIGHT);
            quoteBox.setOrientation(LinearLayout.VERTICAL);
            TextView price = text(priceFor(asset), 14, WHITE, true);
            price.setGravity(Gravity.RIGHT);
            TextView change = text(changeFor(asset), 11, MUTED, true);
            change.setGravity(Gravity.RIGHT);
            quoteBox.addView(price);
            quoteBox.addView(change);
            card.addView(quoteBox, new LinearLayout.LayoutParams(-2, -2));
            marketPriceViews.put(asset.id, price);
            marketChangeViews.put(asset.id, change);

            TextView status = text(asset.id.equals(selectedAssetId) ? "●" : "›", 17,
                    asset.id.equals(selectedAssetId) ? MINT : MUTED, true);
            status.setGravity(Gravity.CENTER);
            LinearLayout.LayoutParams statusParams = new LinearLayout.LayoutParams(dp(18), -1);
            statusParams.leftMargin = dp(7);
            card.addView(status, statusParams);
            marketStatusViews.put(asset.id, status);
            card.setOnClickListener(v -> {
                selectedAssetId = asset.id;
                currentTab = "chart";
                lastCandleRefresh = 0;
                renderCurrentScreen();
                requestQuote(asset);
                requestCandles();
            });
            LinearLayout.LayoutParams rowParams = new LinearLayout.LayoutParams(-1, dp(76));
            rowParams.bottomMargin = dp(9);
            content.addView(card, rowParams);
        }

        TextView disclaimer = text("Режим симулятора. Покупки и продажи виртуальные, настоящие деньги не используются.",
                11, MUTED, false);
        disclaimer.setLineSpacing(dp(2), 1f);
        LinearLayout.LayoutParams disclaimerParams = new LinearLayout.LayoutParams(-1, -2);
        disclaimerParams.topMargin = dp(8);
        content.addView(disclaimer, disclaimerParams);

        scroll.addView(content);
        screenHost.addView(scroll, new FrameLayout.LayoutParams(-1, -1));
    }

    private void renderPortfolioScreen() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setClipToPadding(false);
        scroll.setBackgroundColor(BG);

        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(16), dp(14), dp(16), dp(20));
        content.addView(text("Портфель", 23, WHITE, true));
        TextView subtitle = text("Виртуальный капитал · торговля без реальных денег", 12, MUTED, false);
        LinearLayout.LayoutParams subParams = new LinearLayout.LayoutParams(-1, -2);
        subParams.topMargin = dp(4);
        content.addView(subtitle, subParams);

        BigDecimal total = totalEquity();
        LinearLayout balanceCard = new LinearLayout(this);
        balanceCard.setOrientation(LinearLayout.VERTICAL);
        balanceCard.setPadding(dp(17), dp(15), dp(17), dp(15));
        balanceCard.setBackground(background(Color.rgb(15, 37, 34), 15, Color.rgb(37, 94, 76)));
        LinearLayout.LayoutParams balanceParams = new LinearLayout.LayoutParams(-1, -2);
        balanceParams.topMargin = dp(15);
        content.addView(balanceCard, balanceParams);
        balanceCard.addView(text("ОБЩИЙ КАПИТАЛ", 10, MUTED, true));
        balanceCard.addView(text(money(total), 28, MINT, true));
        LinearLayout cashRow = new LinearLayout(this);
        cashRow.setOrientation(LinearLayout.HORIZONTAL);
        cashRow.setGravity(Gravity.CENTER_VERTICAL);
        TextView cashLabel = text("Доступно для покупки", 12, MUTED, false);
        cashRow.addView(cashLabel, new LinearLayout.LayoutParams(0, -2, 1f));
        cashRow.addView(text(money(cash), 13, WHITE, true));
        LinearLayout.LayoutParams cashRowParams = new LinearLayout.LayoutParams(-1, -2);
        cashRowParams.topMargin = dp(8);
        balanceCard.addView(cashRow, cashRowParams);

        content.addView(sectionTitle("ОТКРЫТЫЕ ПОЗИЦИИ"), topMargin(18));
        boolean anyPosition = false;
        for (Asset asset : assets) {
            BigDecimal qty = holding(asset.id);
            if (qty.signum() <= 0) continue;
            anyPosition = true;
            BigDecimal basis = basis(asset.id);
            Quote quote = quoteFor(asset);
            BigDecimal price = quote == null ? BigDecimal.ZERO : quote.price;
            BigDecimal value = quote == null ? basis : TradeMath.marketValue(qty, price);
            BigDecimal pnl = value.subtract(basis);
            LinearLayout row = new LinearLayout(this);
            row.setOrientation(LinearLayout.HORIZONTAL);
            row.setGravity(Gravity.CENTER_VERTICAL);
            row.setPadding(dp(12), dp(12), dp(12), dp(12));
            row.setBackground(background(PANEL, 12, LINE));

            LinearLayout left = new LinearLayout(this);
            left.setOrientation(LinearLayout.VERTICAL);
            left.addView(text(asset.symbol, 14, WHITE, true));
            left.addView(text(quantity(qty) + " монет", 10, MUTED, false));
            row.addView(left, new LinearLayout.LayoutParams(0, -2, 1f));

            LinearLayout right = new LinearLayout(this);
            right.setOrientation(LinearLayout.VERTICAL);
            right.setGravity(Gravity.RIGHT);
            right.addView(text(money(value), 14, WHITE, true));
            TextView pnlText = text((pnl.signum() > 0 ? "+" : "") + money(pnl), 11,
                    pnl.signum() >= 0 ? MINT : RED, true);
            pnlText.setGravity(Gravity.RIGHT);
            right.addView(pnlText);
            row.addView(right);
            row.setOnClickListener(v -> {
                selectedAssetId = asset.id;
                currentTab = "chart";
                renderCurrentScreen();
                requestQuote(asset);
                requestCandles();
            });
            LinearLayout.LayoutParams rowParams = new LinearLayout.LayoutParams(-1, -2);
            rowParams.bottomMargin = dp(8);
            content.addView(row, rowParams);
        }
        if (!anyPosition) {
            TextView empty = text("Пока нет открытых позиций. Выбери актив во вкладке «Рынок» и купи на виртуальный баланс.",
                    12, MUTED, false);
            empty.setLineSpacing(dp(3), 1f);
            empty.setPadding(dp(13), dp(14), dp(13), dp(14));
            empty.setBackground(background(PANEL, 12, LINE));
            content.addView(empty);
        }

        content.addView(sectionTitle("ИСТОРИЯ СДЕЛОК"), topMargin(18));
        if (trades.isEmpty()) {
            content.addView(text("Сделок пока нет.", 12, MUTED, false), topMargin(5));
        } else {
            int limit = Math.min(25, trades.size());
            for (int i = 0; i < limit; i++) {
                Trade trade = trades.get(i);
                Asset asset = assetById(trade.assetId);
                LinearLayout row = new LinearLayout(this);
                row.setGravity(Gravity.CENTER_VERTICAL);
                row.setOrientation(LinearLayout.HORIZONTAL);
                row.setPadding(dp(10), dp(11), dp(10), dp(11));

                LinearLayout info = new LinearLayout(this);
                info.setOrientation(LinearLayout.VERTICAL);
                info.addView(text((trade.side.equals("BUY") ? "Покупка " : "Продажа ") + asset.symbol,
                        12, WHITE, true));
                String time = new SimpleDateFormat("dd.MM HH:mm:ss", Locale.getDefault()).format(new Date(trade.time));
                info.addView(text(time + " · " + quantity(trade.quantity), 10, MUTED, false));
                row.addView(info, new LinearLayout.LayoutParams(0, -2, 1f));

                LinearLayout amountBox = new LinearLayout(this);
                amountBox.setGravity(Gravity.RIGHT);
                amountBox.setOrientation(LinearLayout.VERTICAL);
                amountBox.addView(text(money(trade.amount), 12,
                        trade.side.equals("BUY") ? WHITE : MINT, true));
                if (trade.side.equals("SELL")) {
                    amountBox.addView(text("P/L " + signedMoney(trade.pnl), 10,
                            trade.pnl.signum() >= 0 ? MINT : RED, true));
                } else {
                    amountBox.addView(text("Цена " + price(trade.price), 10, MUTED, false));
                }
                row.addView(amountBox, new LinearLayout.LayoutParams(-2, -2));
                content.addView(row);
                View divider = new View(this);
                divider.setBackgroundColor(LINE);
                content.addView(divider, new LinearLayout.LayoutParams(-1, dp(1)));
            }
        }

        scroll.addView(content);
        screenHost.addView(scroll, new FrameLayout.LayoutParams(-1, -1));
    }

    private void executeTrade(boolean buy) {
        Asset asset = assetById(selectedAssetId);
        Quote quote = quoteFor(asset);
        if (quote == null || quote.price.signum() <= 0) {
            toast("Ждём реальную цену рынка. Проверь подключение к интернету.");
            requestQuote(asset);
            return;
        }

        BigDecimal entered;
        try {
            String input = amountInput.getText().toString().trim().replace(',', '.');
            entered = new BigDecimal(input).setScale(2, RoundingMode.HALF_UP);
        } catch (Exception e) {
            toast("Введи корректную сумму в долларах.");
            return;
        }
        if (entered.signum() <= 0) {
            toast("Сумма должна быть не меньше $0.01.");
            return;
        }

        if (buy) {
            BigDecimal amount = entered;
            if (amount.compareTo(cash) > 0) {
                toast("Недостаточно виртуальных средств. Доступно " + money(cash));
                return;
            }
            BigDecimal qty = TradeMath.quantityForCash(amount, quote.price);
            if (qty.signum() <= 0 || amount.signum() <= 0) {
                toast("Сумма слишком мала для расчёта.");
                return;
            }

            cash = cash.subtract(amount);
            holdings.put(asset.id, holding(asset.id).add(qty));
            costBasis.put(asset.id, basis(asset.id).add(amount));
            trades.add(0, new Trade(System.currentTimeMillis(), "BUY", asset.id, qty, quote.price, amount, BigDecimal.ZERO));
            trimTrades();
            saveState();
            updateHeader();
            updateSelectedStats();
            updateChart();
            return;
        }

        BigDecimal held = holding(asset.id);
        if (held.signum() <= 0) {
            toast("У тебя нет " + asset.symbol + " для продажи.");
            return;
        }
        BigDecimal qty = TradeMath.quantityForSale(entered, quote.price, held, basis(asset.id));
        if (qty.signum() <= 0) {
            toast("Сумма слишком мала для расчёта.");
            return;
        }

        BigDecimal amount = TradeMath.marketValue(qty, quote.price);
        BigDecimal oldBasis = basis(asset.id);
        BigDecimal soldBasis = TradeMath.soldCostBasis(oldBasis, qty, held);
        BigDecimal pnl = amount.subtract(soldBasis);
        cash = TradeMath.cashAfterSale(cash, qty, quote.price);
        BigDecimal remainingQty = held.subtract(qty);
        BigDecimal remainingBasis = oldBasis.subtract(soldBasis);
        if (remainingQty.signum() == 0) {
            holdings.remove(asset.id);
            costBasis.remove(asset.id);
        } else {
            holdings.put(asset.id, remainingQty);
            costBasis.put(asset.id, remainingBasis.max(BigDecimal.ZERO));
        }
        trades.add(0, new Trade(System.currentTimeMillis(), "SELL", asset.id, qty, quote.price, amount, pnl));
        trimTrades();
        saveState();
        updateHeader();
        updateSelectedStats();
        updateChart();
    }

    private void updateHeader() {
        if (headerEquity != null) headerEquity.setText("ДОСТУПНО " + money(cash));
        if (headerCash != null) headerCash.setText("КАПИТАЛ " + money(totalEquity()));
        if (headerLive != null) headerLive.setText("LIVE");
    }

    private void updateSelectedStats() {
        Asset asset = assetById(selectedAssetId);
        Quote quote = quoteFor(asset);
        if (selectedPriceText != null) selectedPriceText.setText(priceFor(asset));
        if (selectedChangeText != null) {
            selectedChangeText.setText(changeFor(asset));
            selectedChangeText.setTextColor(quote != null && quote.change.signum() >= 0 ? MINT : RED);
        }
        if (selectedPositionText != null) selectedPositionText.setText(positionSummary(asset));
        updateHeader();
    }

    private void updateChart() {
        if (chartView == null) return;
        Asset asset = assetById(selectedAssetId);
        Quote quote = quoteFor(asset);
        chartView.setData(candlesForCurrentAsset(), recentPrices.get(asset.id),
                quote == null ? BigDecimal.ZERO : quote.price);
    }

    private void updateMarketRows() {
        for (Asset asset : assets) {
            TextView priceView = marketPriceViews.get(asset.id);
            TextView changeView = marketChangeViews.get(asset.id);
            TextView statusView = marketStatusViews.get(asset.id);
            if (priceView != null) priceView.setText(priceFor(asset));
            if (changeView != null) {
                Quote quote = quoteFor(asset);
                changeView.setText(changeFor(asset));
                changeView.setTextColor(quote != null && quote.change.signum() >= 0 ? MINT : RED);
            }
            if (statusView != null) {
                boolean selected = asset.id.equals(selectedAssetId);
                statusView.setText(selected ? "●" : "›");
                statusView.setTextColor(selected ? MINT : MUTED);
            }
        }
    }

    private void requestQuote(Asset asset) {
        if (asset == null || !pendingQuotes.add(asset.id)) return;
        marketExecutor.execute(() -> {
            Quote fetched = null;
            try {
                fetched = fetchQuote(asset);
            } catch (Exception ignored) { }
            Quote result = fetched;
            handler.post(() -> {
                pendingQuotes.remove(asset.id);
                if (result == null) {
                    if (currentTab.equals("chart") && selectedAssetId.equals(asset.id)
                            && quoteFor(asset) == null && headerCash != null) {
                        selectedChangeTextIfPresent("Нет связи с рынком");
                    }
                    return;
                }
                quotes.put(asset.id, result);
                List<BigDecimal> series = recentPrices.get(asset.id);
                if (series != null) {
                    series.add(result.price);
                    while (series.size() > 120) series.remove(0);
                }
                savePriceCache();
                maybeAlertForDrop(asset, result);
                if (selectedAssetId.equals(asset.id)) {
                    updateSelectedStats();
                    updateChart();
                } else {
                    updateHeader();
                }
                updateMarketRows();
            });
        });
    }

    private void selectedChangeTextIfPresent(String message) {
        if (selectedChangeText != null) selectedChangeText.setText(message);
    }

    private void requestAllQuotes() {
        if (allQuotesPending) return;
        allQuotesPending = true;
        marketExecutor.execute(() -> {
            Map<String, Quote> fetchedByPair = new LinkedHashMap<>();
            try {
                // This public spot endpoint returns the active symbol ticker set in one request.
                JSONArray rows = new JSONArray(httpGet(
                        "https://api.binance.com/api/v3/ticker/24hr", 12000));
                long now = System.currentTimeMillis();
                for (int i = 0; i < rows.length(); i++) {
                    JSONObject row = rows.optJSONObject(i);
                    if (row == null) continue;
                    String pair = row.optString("symbol", "");
                    if (!pair.endsWith("USDT") || pair.length() <= 4) continue;
                    String base = pair.substring(0, pair.length() - 4);
                    if (!base.matches("[A-Z0-9]{2,15}") || isLeveragedToken(base)) continue;
                    BigDecimal price = decimal(row.optString("lastPrice", "0"), BigDecimal.ZERO);
                    BigDecimal change = decimal(row.optString("priceChangePercent", "0"), BigDecimal.ZERO);
                    if (price.signum() > 0) {
                        fetchedByPair.put(pair, new Quote(price, change, "Binance", now));
                    }
                }
            } catch (Exception ignored) { }
            Map<String, Quote> results = fetchedByPair;
            handler.post(() -> {
                allQuotesPending = false;
                if (results.isEmpty()) return;
                Map<String, Asset> byPair = new HashMap<>();
                for (Asset asset : assets) byPair.put(asset.pair, asset);
                for (Map.Entry<String, Quote> entry : results.entrySet()) {
                    Asset asset = byPair.get(entry.getKey());
                    if (asset == null) {
                        String base = entry.getKey().substring(0, entry.getKey().length() - 4);
                        asset = new Asset(base, base, base, entry.getKey(), "binance", "", base.substring(0, 1));
                        assets.add(asset);
                        byPair.put(asset.pair, asset);
                        recentPrices.put(base, new ArrayList<>());
                    }
                    quotes.put(asset.id, entry.getValue());
                    List<BigDecimal> series = recentPrices.get(asset.id);
                    if (series != null) {
                        series.add(entry.getValue().price);
                        while (series.size() > 120) series.remove(0);
                    }
                    maybeAlertForDrop(asset, entry.getValue());
                }
                savePriceCache();
                updateHeader();
                updateMarketRows();
                if (currentTab.equals("chart") && quotes.containsKey(selectedAssetId)) {
                    updateSelectedStats();
                    updateChart();
                }
            });
        });
    }

    private boolean isLeveragedToken(String base) {
        return base.endsWith("UP") || base.endsWith("DOWN") ||
                base.endsWith("BULL") || base.endsWith("BEAR") ||
                base.endsWith("2L") || base.endsWith("2S") ||
                base.endsWith("3L") || base.endsWith("3S") ||
                base.endsWith("4L") || base.endsWith("4S") ||
                base.endsWith("5L") || base.endsWith("5S");
    }

    private Quote fetchQuote(Asset asset) throws Exception {
        if (asset.source.equals("binance")) {
            String url = "https://api.binance.com/api/v3/ticker/24hr?symbol=" +
                    URLEncoder.encode(asset.pair, "UTF-8");
            JSONObject response = new JSONObject(httpGet(url, 9000));
            BigDecimal price = decimal(response.optString("lastPrice", "0"), BigDecimal.ZERO);
            BigDecimal change = decimal(response.optString("priceChangePercent", "0"), BigDecimal.ZERO);
            if (price.signum() <= 0) throw new IllegalStateException("Нет цены");
            return new Quote(price, change, "Binance", System.currentTimeMillis());
        }

        String url = "https://api.dexscreener.com/latest/dex/search?q=" +
                URLEncoder.encode(asset.query, "UTF-8");
        JSONObject response = new JSONObject(httpGet(url, 10000));
        JSONArray pairs = response.optJSONArray("pairs");
        JSONObject best = null;
        BigDecimal bestLiquidity = BigDecimal.valueOf(-1);
        if (pairs != null) {
            for (int i = 0; i < pairs.length(); i++) {
                JSONObject pair = pairs.optJSONObject(i);
                if (pair == null) continue;
                JSONObject base = pair.optJSONObject("baseToken");
                String symbol = base == null ? "" : base.optString("symbol", "");
                if (!symbol.equalsIgnoreCase(asset.symbol)) continue;
                BigDecimal price = decimal(pair.optString("priceUsd", "0"), BigDecimal.ZERO);
                if (price.signum() <= 0) continue;
                JSONObject liquidity = pair.optJSONObject("liquidity");
                BigDecimal liquidityUsd = liquidity == null ? BigDecimal.ZERO :
                        decimal(liquidity.optString("usd", "0"), BigDecimal.ZERO);
                if (best == null || liquidityUsd.compareTo(bestLiquidity) > 0) {
                    best = pair;
                    bestLiquidity = liquidityUsd;
                }
            }
        }
        if (best == null) throw new IllegalStateException("Актив не найден");
        BigDecimal price = decimal(best.optString("priceUsd", "0"), BigDecimal.ZERO);
        JSONObject changeObject = best.optJSONObject("priceChange");
        BigDecimal change = changeObject == null ? BigDecimal.ZERO :
                decimal(changeObject.optString("h24", "0"), BigDecimal.ZERO);
        String dex = best.optString("dexId", "DEX");
        return new Quote(price, change, "DEX · " + dex, System.currentTimeMillis());
    }

    private void requestCandles() {
        Asset asset = assetById(selectedAssetId);
        if (asset == null) return;
        if (!asset.source.equals("binance")) {
            lastCandleRefresh = System.currentTimeMillis();
            updateChart();
            return;
        }
        if (!pendingCandles.add(asset.id)) {
            updateChart();
            return;
        }
        lastCandleRefresh = System.currentTimeMillis();
        String interval = currentInterval;
        marketExecutor.execute(() -> {
            List<Candle> result = new ArrayList<>();
            try {
                String url = "https://api.binance.com/api/v3/klines?symbol=" +
                        URLEncoder.encode(asset.pair, "UTF-8") + "&interval=" + interval + "&limit=72";
                JSONArray items = new JSONArray(httpGet(url, 10000));
                for (int i = 0; i < items.length(); i++) {
                    JSONArray item = items.optJSONArray(i);
                    if (item == null || item.length() < 5) continue;
                    BigDecimal open = decimal(item.optString(1), BigDecimal.ZERO);
                    BigDecimal high = decimal(item.optString(2), BigDecimal.ZERO);
                    BigDecimal low = decimal(item.optString(3), BigDecimal.ZERO);
                    BigDecimal close = decimal(item.optString(4), BigDecimal.ZERO);
                    if (open.signum() > 0 && high.signum() > 0 && low.signum() > 0 && close.signum() > 0) {
                        result.add(new Candle(item.optLong(0), open, high, low, close));
                    }
                }
            } catch (Exception ignored) { }
            List<Candle> candles = result;
            handler.post(() -> {
                pendingCandles.remove(asset.id);
                if (selectedAssetId.equals(asset.id) && currentTab.equals("chart")) {
                    if (!candles.isEmpty()) cachedCandles.put(asset.id + ":" + interval, candles);
                    updateChart();
                }
            });
        });
    }

    private final Map<String, List<Candle>> cachedCandles = new HashMap<>();

    private List<Candle> candlesForCurrentAsset() {
        return cachedCandles.getOrDefault(selectedAssetId + ":" + currentInterval, new ArrayList<>());
    }

    private String httpGet(String address, int timeoutMs) throws Exception {
        HttpURLConnection connection = (HttpURLConnection) new URL(address).openConnection();
        connection.setRequestMethod("GET");
        connection.setConnectTimeout(timeoutMs);
        connection.setReadTimeout(timeoutMs);
        connection.setInstanceFollowRedirects(true);
        connection.setRequestProperty("Accept", "application/json");
        connection.setRequestProperty("User-Agent", "Frilance-Android-Native");
        try {
            int status = connection.getResponseCode();
            InputStream stream = status >= 400 ? connection.getErrorStream() : connection.getInputStream();
            if (stream == null) throw new IllegalStateException("HTTP " + status);
            String body = readText(stream);
            if (status >= 400) throw new IllegalStateException("HTTP " + status);
            return body;
        } finally {
            connection.disconnect();
        }
    }

    private void maybeAlertForDrop(Asset asset, Quote quote) {
        if (quote.change.compareTo(new BigDecimal("-15")) > 0) return;
        String key = "drop_alert_" + asset.id;
        long previous = preferences.getLong(key, 0L);
        long now = System.currentTimeMillis();
        if (now - previous < DROP_ALERT_COOLDOWN_MS) return;
        preferences.edit().putLong(key, now).apply();
        if (Build.VERSION.SDK_INT >= 33 &&
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            handler.post(() -> Toast.makeText(this, asset.symbol + " упал на " +
                    quote.change.abs().setScale(1, RoundingMode.HALF_UP).toPlainString() +
                    "% за 24 часа. Проверь график.", Toast.LENGTH_LONG).show());
            return;
        }
        Intent intent = new Intent(this, MainActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, asset.id.hashCode(), intent,
                PendingIntent.FLAG_UPDATE_CURRENT | (Build.VERSION.SDK_INT >= 23 ? PendingIntent.FLAG_IMMUTABLE : 0));
        String percent = quote.change.abs().setScale(1, RoundingMode.HALF_UP).toPlainString();
        Notification notification;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notification = new Notification.Builder(this, ALERT_CHANNEL)
                    .setSmallIcon(R.drawable.ic_launcher)
                    .setContentTitle(asset.symbol + " заметно снизился")
                    .setContentText("Падение на " + percent + "% за 24 часа. Проверь график и реши сам.")
                    .setStyle(new Notification.BigTextStyle().bigText(
                            "Котировка " + asset.name + " снизилась на " + percent +
                                    "% за 24 часа. Открой Frilance, проверь график и реши, нужна ли виртуальная сделка."))
                    .setContentIntent(pendingIntent)
                    .setAutoCancel(true)
                    .build();
        } else {
            notification = new Notification.Builder(this)
                    .setSmallIcon(R.drawable.ic_launcher)
                    .setContentTitle(asset.symbol + " заметно снизился")
                    .setContentText("Падение на " + percent + "% за 24 часа. Проверь график.")
                    .setContentIntent(pendingIntent)
                    .setAutoCancel(true)
                    .build();
        }
        NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager != null) manager.notify(asset.id.hashCode(), notification);
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(ALERT_CHANNEL,
                    "Рыночные уведомления", NotificationManager.IMPORTANCE_DEFAULT);
            channel.setDescription("Уведомления о сильном изменении виртуальных рыночных котировок");
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) manager.createNotificationChannel(channel);
        }
    }

    private void requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33 &&
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED &&
                !notificationPermissionAsked) {
            notificationPermissionAsked = true;
            requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, NOTIFICATION_PERMISSION_REQUEST);
        }
    }

    private BigDecimal totalEquity() {
        BigDecimal total = cash;
        for (Asset asset : assets) {
            BigDecimal quantity = holding(asset.id);
            if (quantity.signum() <= 0) continue;
            Quote quote = quoteFor(asset);
            total = total.add(quote == null ? basis(asset.id) : TradeMath.marketValue(quantity, quote.price));
        }
        return total.setScale(18, RoundingMode.HALF_UP).stripTrailingZeros();
    }

    private BigDecimal holding(String id) {
        return holdings.getOrDefault(id, BigDecimal.ZERO);
    }

    private BigDecimal basis(String id) {
        return costBasis.getOrDefault(id, BigDecimal.ZERO);
    }

    private String positionSummary(Asset asset) {
        BigDecimal qty = holding(asset.id);
        if (qty.signum() == 0) return "ПОЗИЦИИ НЕТ · ВВЕДИ СУММУ НИЖЕ";
        BigDecimal value = quoteFor(asset) == null ? basis(asset.id) :
                TradeMath.marketValue(qty, quoteFor(asset).price);
        BigDecimal pnl = value.subtract(basis(asset.id));
        return "ПОЗИЦИЯ " + quantity(qty) + " " + asset.symbol + "  ·  P/L " + signedMoney(pnl);
    }

    private String priceFor(Asset asset) {
        Quote quote = quoteFor(asset);
        return quote == null ? "Загрузка…" : price(quote.price);
    }

    private String changeFor(Asset asset) {
        Quote quote = quoteFor(asset);
        if (quote == null) return "нет данных";
        return (quote.change.signum() > 0 ? "+" : "") +
                quote.change.setScale(2, RoundingMode.HALF_UP).toPlainString() + "% / 24ч";
    }

    private String quoteSource(Asset asset) {
        Quote quote = quoteFor(asset);
        return quote == null ? (asset.source.equals("binance") ? "Binance" : "DEX") : quote.source;
    }

    private Quote quoteFor(Asset asset) {
        return asset == null ? null : quotes.get(asset.id);
    }

    private Asset assetById(String id) {
        for (Asset asset : assets) if (asset.id.equals(id)) return asset;
        return assets.get(0);
    }

    private void trimTrades() {
        while (trades.size() > 80) trades.remove(trades.size() - 1);
    }

    private void toast(String message) {
        Toast.makeText(this, message, Toast.LENGTH_LONG).show();
    }

    private TextView sectionTitle(String value) {
        TextView view = text(value, 10, MUTED, true);
        view.setLetterSpacing(0.12f);
        return view;
    }

    private LinearLayout.LayoutParams topMargin(int value) {
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, -2);
        params.topMargin = dp(value);
        params.bottomMargin = dp(8);
        return params;
    }

    private TextView coinIcon(Asset asset, int size) {
        TextView icon = text(asset.icon, size >= 42 ? 19 : 15, MINT, true);
        icon.setGravity(Gravity.CENTER);
        icon.setBackground(background(Color.rgb(19, 36, 43), 12, Color.rgb(41, 67, 76)));
        return icon;
    }

    private TextView text(String value, float sizeSp, int color, boolean bold) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(sizeSp);
        view.setTextColor(color);
        view.setIncludeFontPadding(false);
        if (bold) view.setTypeface(Typeface.create("sans-serif", Typeface.BOLD));
        else view.setTypeface(Typeface.create("sans-serif", Typeface.NORMAL));
        return view;
    }

    private Button button(String value, int fill, int color) {
        Button button = new Button(this);
        button.setText(value);
        button.setTextColor(color);
        button.setTextSize(12);
        button.setAllCaps(false);
        button.setMinHeight(0);
        button.setMinimumHeight(0);
        button.setMinWidth(0);
        button.setMinimumWidth(0);
        button.setPadding(dp(7), 0, dp(7), 0);
        button.setTypeface(Typeface.create("sans-serif", Typeface.BOLD));
        button.setBackground(background(fill, 10, fill == MINT ? MINT : LINE));
        return button;
    }

    private GradientDrawable background(int fill, int radiusDp, int stroke) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(fill);
        drawable.setCornerRadius(dp(Math.min(radiusDp, 5)));
        if (stroke != Color.TRANSPARENT) drawable.setStroke(dp(1), stroke);
        return drawable;
    }

    private int dp(float value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    private static BigDecimal decimal(String raw, BigDecimal fallback) {
        try { return new BigDecimal(raw.trim().replace(',', '.')); }
        catch (Exception ignored) { return fallback; }
    }

    private static String money(BigDecimal value) {
        BigDecimal shown = (value == null ? BigDecimal.ZERO : value).setScale(2, RoundingMode.HALF_UP);
        return "$" + shown.toPlainString();
    }

    private static String moneyNumber(BigDecimal value) {
        if (value == null) return "0.00";
        return value.setScale(2, RoundingMode.HALF_UP).toPlainString();
    }

    private static String signedMoney(BigDecimal value) {
        return (value.signum() > 0 ? "+" : value.signum() < 0 ? "−" : "") + money(value.abs());
    }

    private static String quantity(BigDecimal value) {
        if (value == null || value.signum() == 0) return "0";
        String plain = value.stripTrailingZeros().toPlainString();
        if (plain.length() > 30) return value.stripTrailingZeros().toEngineeringString();
        return plain;
    }

    private static String price(BigDecimal value) {
        if (value == null || value.signum() == 0) return "—";
        BigDecimal abs = value.abs();
        BigDecimal shown;
        if (abs.compareTo(new BigDecimal("1000")) >= 0) shown = value.setScale(2, RoundingMode.HALF_UP);
        else if (abs.compareTo(BigDecimal.ONE) >= 0) shown = value.setScale(4, RoundingMode.HALF_UP);
        else if (abs.compareTo(new BigDecimal("0.01")) >= 0) shown = value.setScale(6, RoundingMode.HALF_UP);
        else shown = value.setScale(Math.min(16, Math.max(8, value.stripTrailingZeros().scale() + 2)),
                    RoundingMode.HALF_UP);
        shown = shown.stripTrailingZeros();
        if (shown.scale() < 2) shown = shown.setScale(2);
        return "$" + shown.toPlainString();
    }

    private static String changeLabel(BigDecimal value) {
        return (value.signum() > 0 ? "+" : "") + value.setScale(2, RoundingMode.HALF_UP).toPlainString() + "%";
    }

    private static String readText(InputStream input) throws Exception {
        StringBuilder out = new StringBuilder();
        byte[] buffer = new byte[8192];
        int count;
        try (InputStream in = input) {
            while ((count = in.read(buffer)) != -1) {
                out.append(new String(buffer, 0, count, java.nio.charset.StandardCharsets.UTF_8));
            }
        }
        return out.toString();
    }

    private void checkForUpdates(boolean userRequested) {
        if (updateCheckRunning) {
            if (userRequested) handler.post(() -> toast("Проверка уже выполняется."));
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
                connection.setRequestProperty("User-Agent", "Frilance-Android-Native");
                String body;
                try (InputStream in = connection.getInputStream()) { body = readText(in); }
                finally { connection.disconnect(); }

                JSONObject release = new JSONObject(body);
                String tag = release.optString("tag_name", "");
                int remoteCode = releaseCode(tag);
                String apkUrl = findApkUrl(release.optJSONArray("assets"));
                if (remoteCode <= BuildConfig.VERSION_CODE || apkUrl == null) {
                    if (userRequested) handler.post(() ->
                            toast(remoteCode <= BuildConfig.VERSION_CODE
                                    ? "Установлена последняя версия."
                                    : "APK не найден в последнем релизе."));
                    return;
                }
                String lastOffered = preferences.getString("last_offered_release", "");
                if (!userRequested && tag.equals(lastOffered)) return;
                handler.post(() -> offerUpdate(tag, apkUrl));
            } catch (Exception ignored) {
                if (userRequested) handler.post(() ->
                        toast("Не удалось проверить релизы. Проверь интернет."));
            } finally {
                updateCheckRunning = false;
            }
        });
    }

    private static int releaseCode(String tag) {
        String prefix = "frilance-v1.0.";
        if (!tag.startsWith(prefix)) return 0;
        try { return 1000 + Integer.parseInt(tag.substring(prefix.length())); }
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

    private void offerUpdate(String tag, String apkUrl) {
        if (isFinishing()) return;
        preferences.edit().putString("last_offered_release", tag).apply();
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
            handler.post(() -> {
                if (downloadDialog != null && downloadDialog.isShowing()) downloadDialog.dismiss();
                downloadDialog = null;
                if (finalFailure != null || finalApk == null || !finalApk.isFile()) {
                    toast("Не удалось загрузить APK. Попробуй позже.");
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
            toast("Не удалось открыть установщик Android.");
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == INSTALL_PERMISSION_REQUEST) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || getPackageManager().canRequestPackageInstalls()) {
                if (pendingUpdateApk != null && pendingUpdateApk.exists()) installApk(pendingUpdateApk);
            } else {
                toast("Разрешение не выдано. Обновление можно скачать ещё раз.");
            }
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST && grantResults.length > 0 &&
                grantResults[0] != PackageManager.PERMISSION_GRANTED) {
            notificationPermissionAsked = true;
        }
    }

    @Override
    @SuppressWarnings("deprecation")
    public void onBackPressed() {
        if (!currentTab.equals("chart")) {
            currentTab = "chart";
            renderCurrentScreen();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        if (downloadDialog != null && downloadDialog.isShowing()) downloadDialog.dismiss();
        updateExecutor.shutdownNow();
        marketExecutor.shutdownNow();
        super.onDestroy();
    }

    private final class NativeChartView extends View {
        private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private List<Candle> candles = new ArrayList<>();
        private List<BigDecimal> points = new ArrayList<>();
        private BigDecimal latest = BigDecimal.ZERO;
        private float zoomFactor = 1f;
        private final ScaleGestureDetector scaleDetector;

        NativeChartView(Context context) {
            super(context);
            setLayerType(View.LAYER_TYPE_SOFTWARE, null);
            scaleDetector = new ScaleGestureDetector(context,
                    new ScaleGestureDetector.SimpleOnScaleGestureListener() {
                        @Override
                        public boolean onScale(ScaleGestureDetector detector) {
                            zoomFactor = Math.max(1f, Math.min(8f, zoomFactor * detector.getScaleFactor()));
                            invalidate();
                            return true;
                        }
                    });
        }

        @Override
        public boolean onTouchEvent(MotionEvent event) {
            scaleDetector.onTouchEvent(event);
            return true;
        }

        private List<Candle> visibleCandles() {
            if (candles.isEmpty()) return candles;
            int count = Math.max(6, (int) Math.ceil(candles.size() / zoomFactor));
            int start = Math.max(0, candles.size() - count);
            return candles.subList(start, candles.size());
        }

        private List<BigDecimal> visiblePoints() {
            if (points.isEmpty()) return points;
            int count = Math.max(6, (int) Math.ceil(points.size() / zoomFactor));
            int start = Math.max(0, points.size() - count);
            return points.subList(start, points.size());
        }

        void setData(List<Candle> data, List<BigDecimal> series, BigDecimal current) {
            candles = data == null ? new ArrayList<>() : new ArrayList<>(data);
            points = series == null ? new ArrayList<>() : new ArrayList<>(series);
            latest = current == null ? BigDecimal.ZERO : current;
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float w = getWidth();
            float h = getHeight();
            if (w <= 0 || h <= 0) return;
            canvas.drawColor(BG);
            float left = dp(8);
            float right = w - dp(8);
            float top = dp(17);
            float bottom = h - dp(23);
            if (bottom <= top) return;

            List<Candle> visibleCandleData = visibleCandles();
            List<BigDecimal> visiblePointData = visiblePoints();
            ArrayList<BigDecimal> values = new ArrayList<>();
            if (!visibleCandleData.isEmpty()) {
                for (Candle candle : visibleCandleData) {
                    values.add(candle.high);
                    values.add(candle.low);
                }
            } else {
                values.addAll(visiblePointData);
            }
            if (latest.signum() > 0) values.add(latest);
            if (values.isEmpty()) {
                paint.setColor(MUTED);
                paint.setTextSize(dp(13));
                paint.setTextAlign(Paint.Align.CENTER);
                canvas.drawText("Подключаем реальные котировки…", w / 2f, h / 2f, paint);
                return;
            }

            BigDecimal minValue = values.get(0);
            BigDecimal maxValue = values.get(0);
            for (BigDecimal v : values) {
                if (v.compareTo(minValue) < 0) minValue = v;
                if (v.compareTo(maxValue) > 0) maxValue = v;
            }
            if (minValue.compareTo(maxValue) == 0) {
                BigDecimal pad = maxValue.abs().multiply(new BigDecimal("0.01"));
                if (pad.signum() == 0) pad = BigDecimal.ONE;
                minValue = minValue.subtract(pad);
                maxValue = maxValue.add(pad);
            } else {
                BigDecimal span = maxValue.subtract(minValue);
                BigDecimal pad = span.multiply(new BigDecimal("0.09"));
                minValue = minValue.subtract(pad);
                maxValue = maxValue.add(pad);
            }

            final BigDecimal low = minValue;
            final BigDecimal span = maxValue.subtract(minValue);
            paint.setStrokeWidth(dp(1));
            paint.setColor(Color.rgb(26, 37, 47));
            paint.setStyle(Paint.Style.STROKE);
            for (int i = 0; i <= 4; i++) {
                float y = top + (bottom - top) * i / 4f;
                canvas.drawLine(left, y, right, y, paint);
                BigDecimal labelValue = maxValue.subtract(span.multiply(BigDecimal.valueOf(i))
                        .divide(BigDecimal.valueOf(4), 24, RoundingMode.HALF_UP));
                paint.setStyle(Paint.Style.FILL);
                paint.setTextAlign(Paint.Align.LEFT);
                paint.setTextSize(dp(9));
                paint.setColor(MUTED);
                canvas.drawText(shortPrice(labelValue), left + dp(4), y - dp(3), paint);
                paint.setStyle(Paint.Style.STROKE);
                paint.setColor(Color.rgb(26, 37, 47));
            }

            if (visibleCandleData.size() >= 2) drawCandles(canvas, left, right, top, bottom, low, span, visibleCandleData);
            else drawLine(canvas, left, right, top, bottom, low, span, visiblePointData);

            if (latest.signum() > 0) {
                float y = yFor(latest, top, bottom, low, span);
                paint.setColor(MINT);
                paint.setStrokeWidth(dp(1));
                paint.setPathEffect(new android.graphics.DashPathEffect(new float[]{dp(4), dp(4)}, 0));
                canvas.drawLine(left, y, right, y, paint);
                paint.setPathEffect(null);
                paint.setStyle(Paint.Style.FILL);
                paint.setTextAlign(Paint.Align.RIGHT);
                paint.setTextSize(dp(10));
                canvas.drawText(shortPrice(latest), right - dp(4), Math.max(top + dp(11), y - dp(4)), paint);
            }
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(MUTED);
            paint.setTextSize(dp(9));
            paint.setTextAlign(Paint.Align.LEFT);
            String label = visibleCandleData.size() >= 2 ? "РЕАЛЬНЫЕ СВЕЧИ · BINANCE · МАСШТАБ ЖЕСТОМ" : "ИСТОРИЯ КОТИРОВОК · МАСШТАБ ЖЕСТОМ";
            canvas.drawText(label, left + dp(3), h - dp(5), paint);
        }

        private void drawCandles(Canvas canvas, float left, float right, float top, float bottom,
                                 BigDecimal min, BigDecimal span, List<Candle> data) {
            float plotWidth = right - left;
            float step = plotWidth / data.size();
            float candleWidth = Math.max(dp(2), Math.min(dp(9), step * 0.55f));
            for (int i = 0; i < data.size(); i++) {
                Candle c = data.get(i);
                float x = left + (i + 0.5f) * step;
                float yHigh = yFor(c.high, top, bottom, min, span);
                float yLow = yFor(c.low, top, bottom, min, span);
                float yOpen = yFor(c.open, top, bottom, min, span);
                float yClose = yFor(c.close, top, bottom, min, span);
                int color = c.close.compareTo(c.open) >= 0 ? MINT : RED;
                paint.setColor(color);
                paint.setStyle(Paint.Style.STROKE);
                paint.setStrokeWidth(dp(1));
                canvas.drawLine(x, yHigh, x, yLow, paint);
                paint.setStyle(Paint.Style.FILL);
                float bodyTop = Math.min(yOpen, yClose);
                float bodyBottom = Math.max(yOpen, yClose);
                if (bodyBottom - bodyTop < dp(2)) bodyBottom = bodyTop + dp(2);
                canvas.drawRect(x - candleWidth / 2f, bodyTop, x + candleWidth / 2f, bodyBottom, paint);
            }
        }

        private void drawLine(Canvas canvas, float left, float right, float top, float bottom,
                              BigDecimal min, BigDecimal span, List<BigDecimal> visiblePointData) {
            ArrayList<BigDecimal> series = new ArrayList<>(visiblePointData);
            if (latest.signum() > 0 && (series.isEmpty() ||
                    series.get(series.size() - 1).compareTo(latest) != 0)) series.add(latest);
            if (series.size() == 1) series.add(series.get(0));
            if (series.isEmpty()) {
                paint.setColor(MUTED);
                paint.setTextSize(dp(12));
                paint.setTextAlign(Paint.Align.CENTER);
                canvas.drawText("История появится после обновления цены", getWidth() / 2f, getHeight() / 2f, paint);
                return;
            }
            float step = series.size() > 1 ? (right - left) / (series.size() - 1) : 0;
            Path line = new Path();
            Path area = new Path();
            for (int i = 0; i < series.size(); i++) {
                float x = series.size() == 1 ? (left + right) / 2f : left + i * step;
                float y = yFor(series.get(i), top, bottom, min, span);
                if (i == 0) {
                    line.moveTo(x, y);
                    area.moveTo(x, bottom);
                    area.lineTo(x, y);
                } else {
                    line.lineTo(x, y);
                    area.lineTo(x, y);
                }
            }
            area.lineTo(right, bottom);
            area.close();
            paint.setStyle(Paint.Style.FILL);
            paint.setColor(Color.argb(24, 55, 230, 172));
            canvas.drawPath(area, paint);
            paint.setStyle(Paint.Style.STROKE);
            paint.setStrokeWidth(dp(2));
            paint.setStrokeCap(Paint.Cap.ROUND);
            paint.setStrokeJoin(Paint.Join.ROUND);
            paint.setColor(MINT);
            canvas.drawPath(line, paint);
            paint.setStyle(Paint.Style.FILL);
        }

        private float yFor(BigDecimal value, float top, float bottom, BigDecimal min, BigDecimal span) {
            float fraction = value.subtract(min).divide(span, 16, RoundingMode.HALF_UP).floatValue();
            fraction = Math.max(0f, Math.min(1f, fraction));
            return bottom - (bottom - top) * fraction;
        }

        private String shortPrice(BigDecimal value) {
            if (value.abs().compareTo(new BigDecimal("1000")) >= 0) {
                return new DecimalFormat("#,##0.##").format(value);
            }
            if (value.abs().compareTo(BigDecimal.ONE) >= 0) {
                return new DecimalFormat("0.##").format(value);
            }
            return value.stripTrailingZeros().toPlainString();
        }
    }

    private static final class Asset {
        final String id, name, symbol, pair, source, query, icon;
        Asset(String id, String name, String symbol, String pair, String source, String query, String icon) {
            this.id = id;
            this.name = name;
            this.symbol = symbol;
            this.pair = pair;
            this.source = source;
            this.query = query;
            this.icon = icon;
        }
    }

    private static final class Quote {
        final BigDecimal price, change;
        final String source;
        final long time;
        Quote(BigDecimal price, BigDecimal change, String source, long time) {
            this.price = price;
            this.change = change;
            this.source = source;
            this.time = time;
        }
    }

    private static final class Candle {
        final long time;
        final BigDecimal open, high, low, close;
        Candle(long time, BigDecimal open, BigDecimal high, BigDecimal low, BigDecimal close) {
            this.time = time;
            this.open = open;
            this.high = high;
            this.low = low;
            this.close = close;
        }
    }

    private static final class Trade {
        final long time;
        final String side, assetId;
        final BigDecimal quantity, price, amount, pnl;
        Trade(long time, String side, String assetId, BigDecimal quantity, BigDecimal price,
              BigDecimal amount, BigDecimal pnl) {
            this.time = time;
            this.side = side;
            this.assetId = assetId;
            this.quantity = quantity;
            this.price = price;
            this.amount = amount;
            this.pnl = pnl;
        }
    }
}
