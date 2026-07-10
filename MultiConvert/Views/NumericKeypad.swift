import SwiftUI

struct NumericKeypad: View {
    @Environment(AppState.self) private var state
    @Environment(PurchaseManager.self) private var purchase

    private let hPad: CGFloat = 12
    private let spacing: CGFloat = 10

    // Compute once from screen width — no GeometryReader, no @State, no re-render.
    // Cap differs by tier: free users get 64pt max (ad banner reclaims 50pt at bottom),
    // premium users get 84pt max (no banner, more vertical room).
    // Used as button HEIGHT here — width is flexible, filling its grid cell
    // edge-to-edge for the rounded-rectangle keys.
    private var d: CGFloat {
        Self.buttonDiameter(screenWidth: UIScreen.main.bounds.width, isPremium: purchase.isPremium)
    }

    private var keypadHeight: CGFloat {
        (4 * d) + (3 * spacing) + 24
    }

    // Static so PurchaseManagerTests can call it directly without a View instance.
    static func buttonDiameter(
        screenWidth: CGFloat,
        isPremium: Bool,
        hPad: CGFloat = 16,
        spacing: CGFloat = 12
    ) -> CGFloat {
        let computed = (screenWidth - hPad * 2 - spacing * 2) / 3
        let cap: CGFloat = isPremium ? 84 : 64
        return min(computed, cap)
    }

    var body: some View {
        VStack(spacing: spacing) {
            keyRow([.digit("7"), .digit("8"), .digit("9")])
            keyRow([.digit("4"), .digit("5"), .digit("6")])
            keyRow([.digit("1"), .digit("2"), .digit("3")])
            keyRow([.decimal, .digit("0"), .back])
        }
        .padding(.horizontal, hPad)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .frame(height: keypadHeight)
    }

    private func keyRow(_ keys: [PadKey]) -> some View {
        HStack(spacing: spacing) {
            ForEach(keys, id: \.self) { key in
                PadButton(
                    key: key,
                    height: d,
                    action: { handle(key) },
                    onLongPress: key == .back ? state.clearInput : nil
                )
            }
        }
    }

    private func handle(_ key: PadKey) {
        switch key {
        case .digit(let v): state.appendDigit(v)
        case .decimal:      state.appendDigit(".")
        case .clear:        state.clearInput()
        case .back:         state.deleteLastDigit()
        }
    }
}

// MARK: - Key model

enum PadKey: Hashable {
    case digit(String)
    case decimal
    case clear
    case back

    var label: String {
        switch self {
        case .digit(let d): return d
        case .decimal:      return "."
        case .clear:        return "C"
        case .back:         return "⌫"
        }
    }

    var isUtility: Bool {
        switch self {
        case .clear, .back, .decimal: return true
        default: return false
        }
    }
}

// MARK: - Button

private struct PadButton: View {
    let key: PadKey
    let height: CGFloat
    let action: () -> Void
    var onLongPress: (() -> Void)? = nil

    @State private var pressed = false

    private let digitBg   = Color(hex: "#2A2A2C")
    private let utilityBg = Color(hex: "#3A3A3C")

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(key.isUtility ? utilityBg : digitBg)
                Text(key.label)
                    .font(.system(size: height * 0.38, weight: .regular, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.95 : 1.0)
        .opacity(pressed ? 0.8 : 1.0)
        .animation(.easeOut(duration: 0.08), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if let onLongPress {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onLongPress()
                    }
                }
        )
    }
}
