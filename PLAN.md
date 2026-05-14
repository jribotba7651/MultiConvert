# MultiConvert — Build Plan

## File Tree

```
MultiConvert/
├── MultiConvert.xcodeproj/
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/MultiConvert.xcscheme
├── MultiConvert/
│   ├── App/
│   │   └── MultiConvertApp.swift
│   ├── Models/
│   │   ├── Currency.swift
│   │   └── CurrencyRate.swift
│   ├── Services/
│   │   ├── RateProvider.swift
│   │   ├── FiatProvider.swift
│   │   ├── CryptoProvider.swift
│   │   ├── RateCache.swift
│   │   └── ConversionEngine.swift
│   ├── Utilities/
│   │   ├── Theme.swift
│   │   ├── CurrencyFormatter.swift
│   │   └── MRUCache.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── ConversionListView.swift
│   │   ├── ConversionRowView.swift
│   │   ├── NumericKeypad.swift
│   │   ├── CurrencyPickerView.swift
│   │   └── SettingsView.swift
│   ├── App/
│   │   └── AppState.swift
│   └── Resources/
│       └── Assets.xcassets/
├── MultiConvertTests/
│   ├── ConversionMathTests.swift
│   ├── MRUCacheTests.swift
│   ├── CacheStalenessTests.swift
│   └── CurrencyFormattingTests.swift
├── MultiConvertUITests/
│   └── MultiConvertUITests.swift
├── MultiConvertWidget/
│   ├── MultiConvertWidgetBundle.swift
│   └── MultiConvertWidget.swift
├── PLAN.md
├── DECISIONS.md
└── README.md
```

## Build Phases

1. Models + Utilities + Services (with tests)
2. Views (ContentView → keypad → full screen)
3. Widget
4. xcodeproj generation (Python script)
5. Full test suite
6. Docs (DECISIONS.md, README.md)
7. Git commits + tag v0.1.0-mvp

## Architecture

- **MV pattern** with @Observable (no MVVM)
- **Rate storage**: all rates stored as "units per USD" internally
  - Conversion formula: `result = amount * ratesPerUSD[to] / ratesPerUSD[from]`
- **MRU Cache**: max 10 currencies, persisted to UserDefaults as JSON
- **Rate Cache**: JSON file in Caches directory, 24h staleness threshold
- **Widget**: shared UserDefaults (App Group) for pinned base amount

## API Decisions

- Fiat: frankfurter.app (open source, free, no key — exchangerate.host now requires subscription)
- Crypto: coingecko.com free tier (no key required)
```
