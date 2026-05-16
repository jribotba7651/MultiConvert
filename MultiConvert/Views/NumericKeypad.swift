import SwiftUI

struct NumericKeypad: View {
    @Environment(AppState.self) private var state

    private let spacing: CGFloat = 12

    var body: some View {
        VStack(spacing: spacing) {
            row([.clear, .back, .decimal])
            row([.digit("7"), .digit("8"), .digit("9")])
            row([.digit("4"), .digit("5"), .digit("6")])
            row([.digit("1"), .digit("2"), .digit("3")])
            zeroRow
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    private func row(_ keys: [PadKey]) -> some View {
        HStack(spacing: spacing) {
            ForEach(keys, id: \.self) { key in
                PadButton(key: key) { handle(key) }
            }
            // Empty 4th column placeholder (reserved for cycler arrows visually)
            Color.clear
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .allowsHitTesting(false)
        }
    }

    private var zeroRow: some View {
        HStack(spacing: spacing) {
            PadButton(key: .zero) { state.appendDigit("0") }
                .frame(maxWidth: .infinity)
            // Two empty cells for cols 3 and 4
            Color.clear
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .allowsHitTesting(false)
            Color.clear
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .allowsHitTesting(false)
        }
    }

    private func handle(_ key: PadKey) {
        switch key {
        case .digit(let d): state.appendDigit(d)
        case .zero:         state.appendDigit("0")
        case .decimal:      state.appendDigit(".")
        case .clear:        state.clearInput()
        case .back:         state.deleteLastDigit()
        }
    }
}

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

private struct PadButton: View {
    let key: PadKey
    let action: () -> Void

    @State private var pressed = false

    private let digitBg   = Color(hex: "#2A2A2C")
    private let utilityBg = Color(hex: "#3A3A3C")

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                Group {
                    if key == .zero {
                        Capsule()
                            .fill(digitBg)
                            .overlay(label(side: side))
                    } else {
                        Circle()
                            .fill(key.isUtility ? utilityBg : digitBg)
                            .frame(width: side, height: side)
                            .overlay(label(side: side))
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            }
            .aspectRatio(key == .zero ? 2 : 1, contentMode: .fit)
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

    private func label(side: CGFloat) -> some View {
        Text(key.label)
            .font(.system(size: side * 0.42, weight: .regular, design: .rounded))
            .foregroundStyle(.white)
    }
}
