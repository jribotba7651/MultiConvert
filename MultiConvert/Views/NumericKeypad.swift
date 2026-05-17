import SwiftUI

struct NumericKeypad: View {
    @Environment(AppState.self) private var state
    @Environment(PurchaseManager.self) private var purchase

    private let hPad: CGFloat = 16
    private let spacing: CGFloat = 12

    // Compute once from screen width — no GeometryReader, no @State, no re-render.
    // Cap differs by tier: free users get 72pt max (ad banner reclaims 50pt at bottom),
    // premium users get 84pt max (no banner, more vertical room).
    private var d: CGFloat {
        Self.buttonDiameter(screenWidth: UIScreen.main.bounds.width, isPremium: purchase.isPremium)
    }

    // Static so PurchaseManagerTests can call it directly without a View instance.
    static func buttonDiameter(
        screenWidth: CGFloat,
        isPremium: Bool,
        hPad: CGFloat = 16,
        spacing: CGFloat = 12
    ) -> CGFloat {
        let computed = (screenWidth - hPad * 2 - spacing * 3) / 4
        let cap: CGFloat = isPremium ? 84 : 72
        return min(computed, cap)
    }

    var body: some View {
        VStack(spacing: spacing) {
            keyRow([.clear, .back, .decimal])
            keyRow([.digit("7"), .digit("8"), .digit("9")])
            keyRow([.digit("4"), .digit("5"), .digit("6")])
            keyRow([.digit("1"), .digit("2"), .digit("3")])
            zeroRow
        }
        .padding(.horizontal, hPad)
        .padding(.bottom, 24)
    }

    // Three buttons + one transparent col-4 placeholder that the arrows sit above.
    private func keyRow(_ keys: [PadKey]) -> some View {
        HStack(spacing: spacing) {
            ForEach(keys, id: \.self) { key in
                PadButton(key: key, diameter: d) { handle(key) }
            }
            Color.clear
                .frame(width: d, height: d)
                .allowsHitTesting(false)
        }
    }

    // Zero spans cols 1+2: width = 2d + 1 gap, so it aligns exactly with
    // the right edge of col-2 in the rows above. Cols 3 and 4 are transparent.
    private var zeroRow: some View {
        HStack(spacing: spacing) {
            PadButton(key: .zero, diameter: d, zeroSpacing: spacing) {
                state.appendDigit("0")
            }
            Color.clear
                .frame(width: d, height: d)
                .allowsHitTesting(false)
            Color.clear
                .frame(width: d, height: d)
                .allowsHitTesting(false)
        }
    }

    private func handle(_ key: PadKey) {
        switch key {
        case .digit(let v): state.appendDigit(v)
        case .zero:         state.appendDigit("0")
        case .decimal:      state.appendDigit(".")
        case .clear:        state.clearInput()
        case .back:         state.deleteLastDigit()
        }
    }
}

// MARK: - Key model

enum PadKey: Hashable {
    case digit(String)
    case zero
    case decimal
    case clear
    case back

    var label: String {
        switch self {
        case .digit(let d): return d
        case .zero:         return "0"
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
    let diameter: CGFloat
    var zeroSpacing: CGFloat = 0
    let action: () -> Void

    @State private var pressed = false

    private let digitBg   = Color(hex: "#2A2A2C")
    private let utilityBg = Color(hex: "#3A3A3C")

    private var buttonWidth: CGFloat {
        key == .zero ? diameter * 2 + zeroSpacing : diameter
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            ZStack {
                if key == .zero {
                    Capsule().fill(digitBg)
                } else {
                    Circle().fill(key.isUtility ? utilityBg : digitBg)
                }
                Text(key.label)
                    .font(.system(size: diameter * 0.42, weight: .regular, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: buttonWidth, height: diameter)
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
    }
}
