import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ConversionEntry: TimelineEntry {
    let date: Date
    let baseAmount: Double
    let baseCurrency: String
    let conversions: [(code: String, name: String, value: Double, isCrypto: Bool)]
    let isStale: Bool
}

// MARK: - Provider

struct ConversionProvider: TimelineProvider {
    func placeholder(in context: Context) -> ConversionEntry {
        sampleEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (ConversionEntry) -> Void) {
        completion(buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ConversionEntry>) -> Void) {
        let entry = buildEntry()
        // Refresh every 60 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 60, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    // MARK: - Build

    private func buildEntry() -> ConversionEntry {
        let defaults = UserDefaults.standard
        let baseAmountStr = defaults.string(forKey: "widgetBaseAmount") ?? "1"
        let baseAmount = Double(baseAmountStr) ?? 1
        let baseCurrencyCode = defaults.string(forKey: "widgetBaseCurrency") ?? "USD"

        guard let data = try? Data(contentsOf: cacheFileURL()),
              let snapshot = try? JSONDecoder().decode(RateSnapshot.self, from: data),
              let fromRate = snapshot.ratesPerUSD[baseCurrencyCode],
              fromRate > 0
        else {
            return sampleEntry()
        }

        let targets: [String] = ["EUR", "JPY", "GBP", "BTC"]
        var conversions: [(code: String, name: String, value: Double, isCrypto: Bool)] = []

        for code in targets {
            guard let toRate = snapshot.ratesPerUSD[code] else { continue }
            let value = baseAmount * toRate / fromRate
            let isCrypto = ["BTC", "ETH", "SOL", "USDC", "USDT"].contains(code)
            let name = currencyName(code)
            conversions.append((code: code, name: name, value: value, isCrypto: isCrypto))
        }

        return ConversionEntry(
            date: Date(),
            baseAmount: baseAmount,
            baseCurrency: baseCurrencyCode,
            conversions: conversions,
            isStale: snapshot.isStale
        )
    }

    private func sampleEntry() -> ConversionEntry {
        ConversionEntry(
            date: Date(),
            baseAmount: 100,
            baseCurrency: "USD",
            conversions: [
                (code: "EUR", name: "Euro",       value: 92.6,      isCrypto: false),
                (code: "JPY", name: "Yen",        value: 14920,     isCrypto: false),
                (code: "GBP", name: "Pound",      value: 78.9,      isCrypto: false),
                (code: "BTC", name: "Bitcoin",    value: 0.00154,   isCrypto: true),
            ],
            isStale: false
        )
    }

    private func cacheFileURL() -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("multiconvert_rates.json")
    }

    private func currencyName(_ code: String) -> String {
        let names: [String: String] = [
            "USD": "Dollar", "EUR": "Euro", "JPY": "Yen", "GBP": "Pound",
            "CAD": "C. Dollar", "AUD": "A. Dollar", "CHF": "Franc",
            "CNY": "Yuan", "KRW": "Won", "MXN": "Peso", "BRL": "Real",
            "BTC": "Bitcoin", "ETH": "Ethereum", "SOL": "Solana",
            "USDC": "USD Coin", "USDT": "Tether",
        ]
        return names[code] ?? code
    }
}

// MARK: - Local RateSnapshot (shared model, no module dependency)

private struct RateSnapshot: Codable {
    let ratesPerUSD: [String: Double]
    let fetchedAt: Date
    var isStale: Bool { Date().timeIntervalSince(fetchedAt) > 86_400 }
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    let entry: ConversionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            ForEach(entry.conversions.prefix(2), id: \.code) { item in
                conversionRow(item)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .containerBackground(Color(hex: "#1A1A1F"), for: .widget)
    }

    private var header: some View {
        HStack {
            Text("\(formatAmount(entry.baseAmount)) \(entry.baseCurrency)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#D4943A"))
            Spacer()
            if entry.isStale {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#C85A2A"))
            }
        }
    }

    private func conversionRow(_ item: (code: String, name: String, value: Double, isCrypto: Bool)) -> some View {
        HStack {
            Text(item.code)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9A9AA8"))
            Spacer()
            Text(formatValue(item.value, isCrypto: item.isCrypto))
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#F0EFE8"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func formatAmount(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.2f", v)
    }

    private func formatValue(_ v: Double, isCrypto: Bool) -> String {
        isCrypto ? String(format: "%.6f", v) : String(format: "%.2f", v)
    }
}

struct MediumWidgetView: View {
    let entry: ConversionEntry

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                headerStack
                ForEach(entry.conversions.prefix(2), id: \.code) { item in
                    conversionRow(item)
                }
            }
            Divider().background(Color(hex: "#26262D"))
            VStack(alignment: .leading, spacing: 6) {
                Spacer().frame(height: 18)
                ForEach(entry.conversions.dropFirst(2).prefix(2), id: \.code) { item in
                    conversionRow(item)
                }
            }
        }
        .padding(14)
        .containerBackground(Color(hex: "#1A1A1F"), for: .widget)
    }

    private var headerStack: some View {
        Text("\(formatBase(entry.baseAmount)) \(entry.baseCurrency)")
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(hex: "#D4943A"))
    }

    private func conversionRow(_ item: (code: String, name: String, value: Double, isCrypto: Bool)) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(item.code)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9A9AA8"))
            Text(formatValue(item.value, isCrypto: item.isCrypto))
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#F0EFE8"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private func formatBase(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.2f", v)
    }

    private func formatValue(_ v: Double, isCrypto: Bool) -> String {
        isCrypto ? String(format: "%.6f", v) : String(format: "%.2f", v)
    }
}

// MARK: - Color helper for widget (can't import Theme module)

private extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >>  8) & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}

// MARK: - Widget Definition

struct MultiConvertWidget: Widget {
    let kind = "MultiConvertWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ConversionProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("MultiConvert")
        .description("Live currency conversions at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

struct MultiConvertMediumWidget: Widget {
    let kind = "MultiConvertMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ConversionProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("MultiConvert")
        .description("Live currency conversions — 4 pairs.")
        .supportedFamilies([.systemMedium])
    }
}
