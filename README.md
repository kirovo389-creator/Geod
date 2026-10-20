# Frilance

Frilance is an Android-only, local crypto-market simulator. It starts with **$5.00 of virtual cash** and has no deposits, rewards, or real exchange orders.

## Features
- Dark exchange-inspired interface with a candlestick chart.
- Public market quotes from Binance for BTC, ETH, TON, NOT and DOGE.
- Public DEX market lookup through DexScreener for GRAM and BECAUSE; if no liquid market is found, the asset remains unavailable rather than showing a fabricated quote.
- Virtual fractional buy/sell orders with a simulated 0.10% fee.
- Locally stored balance and positions, plus a local-only leaderboard with generated opponents.
- Bankruptcy freezes play. There is no in-game restart or refill; clear Frilance app data in Android settings to start from a clean installation state.

## Build
The workflow in `.github/workflows/android-release.yml` builds an installable debug-signed APK and attaches it to a versioned GitHub Release. It runs after relevant pushes to `main`, or can be started manually from the Actions tab.

The app requires an internet connection for live quotes. All orders are virtual and are never sent to a real exchange. This is a game, not financial advice.

## Data notes
- Exchange ticker and candlestick API: Binance public market data.
- DEX token lookup: DexScreener public search API.
- The local leaderboard is not connected to other devices or players.


## Trading screen and updates

The market screen keeps the virtual cash balance in the top bar, expands the selected-asset chart, and pins quick buy/sell controls above navigation. Completed trades appear in a persistent last-trade label and in the local transaction history.

The selected Binance price is polled once per second while the app is open; the remaining market list is refreshed less often to avoid unnecessary public API requests. New APK releases are checked automatically at launch and periodically while the app stays open. Android still requires the user to confirm APK installation. The CI keeps a stable debug signing key through a GitHub Actions cache so successive builds can update an installed copy; if that cache is purged after a long inactive period, a fresh key can be generated and a reinstall may be needed.
