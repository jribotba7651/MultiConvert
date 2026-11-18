import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct ConversionRow: Hashable {
    let code: String
    let value: String
}

struct ConversionEntry: TimelineEntry {
    let date: Date
    let baseLabel: String
    let rows: [ConversionRow]
    let isStale: Bool
    /// Shown instead of rows when there is no cached data yet.
    let message: String?
}

// MARK: - Provider

struct ConversionProvider: TimelineProvider {
    func placeholder(in context: Context) -> ConversionEntry {
        Self.sampleEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (ConversionEntry) -> Void) {
        // The widget gallery preview may use sample data if the app has never
        // fetched rates; a real widget on the home screen never does.
        let entry = Self.buildEntry()
        if context.isPreview && entry.message != nil {
            completion(Self.sampleEntry)
        } else {
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ConversionEntry>) -> Void) {
        // The app reloads timelines whenever rates or settings change; this
        // hourly policy only re-evaluates staleness.
        let next = Calendar.current.date(byAdding: .minute, value: 60, to: Date()) ?? Date()
        completion(Timeline(entries: [Self.buildEntry()], policy: .after(next)))
    }

    // MARK: - Build from shared App Group data

    static func buildEntry() -> ConversionEntry {
        let defaults = AppGroup.defaults

        let amountText = (defaults.string(forKey: AppGroup.Keys.widgetBase) ?? "1")
            .replacingOccurrences(of: ",", with: ".")
        let amount = Double(amountText) ?? 1
        let base = defaults.string(forKey: AppGroup.Keys.widgetCurrency)
            .flatMap(Currency.find(code:)) ?? .usd

        var decimals = defaults.integer(forKey: AppGroup.Keys.decimalPlaces)
        if decimals == 0 { decimals = 2 }
        let style = (defaults.object(forKey: AppGroup.Keys.separatorStyle) as? Int)
            .flatMap(SeparatorStyle.init(rawValue:)) ?? .deviceDefault

        let baseLabel = "\(CurrencyFormatter.groupedInput(trimmed(amount), separatorStyle: style)) \(base.code)"

        guard let snapshot = RateCache().snapshot else {
            return ConversionEntry(
                date: Date(), baseLabel: baseLabel, rows: [], isStale: false,
                message: "Open MultiConvert to load rates"
            )
        }

        let rows: [ConversionRow] = targetCurrencies(excluding: base, defaults: defaults)
            .compactMap { currency in
                guard let value = snapshot.convert(amount: amount, from: base.code, to: currency.code) else {
                    return nil
                }
                let text = CurrencyFormatter.format(
                    value, currency: currency, decimalPlaces: decimals, separatorStyle: style
                )
                return ConversionRow(code: currency.code, value: text)
            }

        return ConversionEntry(
            date: Date(),
            baseLabel: baseLabel,
            rows: rows,
            isStale: snapshot.isStale,
            message: rows.isEmpty ? "No rates for \(base.code) yet" : nil
        )
    }

    /// The user's own currency list from the app (minus the widget base),
    /// up to four entries.
    private static func targetCurrencies(excluding base: Currency, defaults: UserDefaults) -> [Currency] {
        var codes: [String] = []
        if let data = defaults.data(forKey: AppGroup.Keys.recentCurrencies),
           let stored = try? JSONDecoder().decode([String].self, from: data) {
            codes = stored
        }
        if codes.isEmpty { codes = ["USD", "EUR", "GBP", "JPY", "BTC"] }
        return Array(
            codes.filter { $0 != base.code }
                .compactMap(Currency.find(code:))
                .prefix(4)
        )
    }

    /// "1" instead of "1.0"; keeps up to two decimals otherwise.
    private static func trimmed(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.2f", v)
    }

    // Placeholder / gallery preview only. Never shown as live data.
    static let sampleEntry = ConversionEntry(
        date: Date(),
        baseLabel: "100 USD",
        rows: [
            ConversionRow(code: "EUR", value: "€92.60"),
            ConversionRow(code: "JPY", value: "¥14,920"),
            ConversionRow(code: "GBP", value: "£78.90"),
            ConversionRow(code: "BTC", value: "₿ 0.001540"),
        ],
        isStale: false,
        message: nil
    )
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    let entry: ConversionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if let message = entry.message {
                messageView(message)
            } else {
                ForEach(entry.rows.prefix(2), id: \.code) { item in
                    conversionRow(item)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .containerBackground(Color(hex: "#1A1A1F"), for: .widget)
    }

    private var header: some View {
        HStack {
            Text(entry.baseLabel)
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

    private func conversionRow(_ item: ConversionRow) -> some View {
        HStack {
            Text(item.code)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9A9AA8"))
            Spacer()
            Text(item.value)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#F0EFE8"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

}

struct MediumWidgetView: View {
    let entry: ConversionEntry

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                headerStack
                if let message = entry.message {
                    messageView(message)
                } else {
                    ForEach(entry.rows.prefix(2), id: \.code) { item in
                        conversionRow(item)
                    }
                }
            }
            if entry.message == nil {
                Divider().background(Color(hex: "#26262D"))
                VStack(alignment: .leading, spacing: 6) {
                    Spacer().frame(height: 18)
                    ForEach(entry.rows.dropFirst(2).prefix(2), id: \.code) { item in
                        conversionRow(item)
                    }
                }
            }
        }
        .padding(14)
        .containerBackground(Color(hex: "#1A1A1F"), for: .widget)
    }

    private var headerStack: some View {
        HStack(spacing: 6) {
            Text(entry.baseLabel)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#D4943A"))
            if entry.isStale {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#C85A2A"))
            }
        }
    }

    private func conversionRow(_ item: ConversionRow) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(item.code)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9A9AA8"))
            Text(item.value)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#F0EFE8"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

}

private func messageView(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 11, weight: .regular, design: .rounded))
        .foregroundStyle(Color(hex: "#9A9AA8"))
        .fixedSize(horizontal: false, vertical: true)
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
