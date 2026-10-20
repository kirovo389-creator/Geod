# Frilance

Frilance is a native Java Android crypto-market simulator. It starts with **$5.00 of virtual cash** and never sends orders to a real exchange.

## Features
- Native Android interface built in Java; no HTML, JavaScript, or WebView.
- A chart that fills the available screen without vertical scrolling, with separate Market and Portfolio tabs.
- Public market quotes from Binance for BTC, ETH, TON, NOT and DOGE.
- Public DEX market lookup through DexScreener for GRAM and BECAUSE. If a valid quote is not found, the app does not invent one.
- High-precision fractional positions and virtual buy/sell orders with no intermediate cent rounding.
- Portfolio equity includes available cash plus the current market value of open positions.
- Persistent virtual cash, holdings, cost basis and transaction history.
- Notification when an asset's reported 24-hour change is at or below -15%, with a six-hour cooldown per asset.
- In-app update checks for published APK releases.

## Trading math

Wallet amounts and positions are kept as decimal strings and calculated with BigDecimal. Display formatting does not change the stored amount. For example, buying $5 of an asset at $100 creates 0.05 units; if its price later reaches $128, the position is worth $6.40 before sale. Selling credits the full calculated proceeds to virtual cash. Very small quantities remain small quantities—their gains and losses are proportional to the amount held.

## Build

The workflow in .github/workflows/android-release.yml runs Java unit tests, builds a debug-signed APK, and attaches it to a versioned GitHub Release after relevant pushes to main. It can also be started manually from the Actions tab.

All market data is fetched from public Binance and DexScreener APIs. An internet connection is required for fresh quotes. This is a simulator, not financial advice.
