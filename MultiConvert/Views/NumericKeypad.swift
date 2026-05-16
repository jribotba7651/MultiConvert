import SwiftUI

// Uses Grid (iOS 16+) instead of LazyVGrid because LazyVGrid has no column-spanning API.
// The "0" button must span 2 columns (width = 76×2 + 12 = 164pt), which requires
// .gridCellColumns(2) — only available on Grid's GridRow cells.
struct NumericKeypad: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                PadButton(key: .clear)    { state.clearInput() }
                PadButton(key: .back)     { state.deleteLastDigit() }
                PadButton(key: .decimal)  { state.appendDigit(".") }
                Color.clear.frame(width: 76, height: 76)
            }
            GridRow {
                PadButton(key: .digit("7")) { state.appendDigit("7") }
                PadButton(key: .digit("8")) { state.appendDigit("8") }
                PadButton(key: .digit("9")) { state.appendDigit("9") }
                Color.clear.frame(width: 76, height: 76)
            }
            GridRow {
                PadButton(key: .digit("4")) { state.appendDigit("4") }
                PadButton(key: .digit("5")) { state.appendDigit("5") }
                PadButton(key: .digit("6")) { state.appendDigit("6") }
                Color.clear.frame(width: 76, height: 76)
            }
            GridRow {
                PadButton(key: .digit("1")) { state.appendDigit("1") }
                PadButton(key: .digit("2")) { state.appendDigit("2") }
                PadButton(key: .digit("3")) { state.appendDigit("3") }
                Color.clear.frame(width: 76, height: 76)
            }
            GridRow {
                PadButton(key: .zero) { state.appendDigit("0") }
                    .gridCellColumns(2)
                Color.clear.frame(width: 76, height: 76)
                Color.clear.frame(width: 76, height: 76)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }
}

// MARK: - Key model

enum PadKey: Equatable {
    case digit(String)
    case zero
    case decimal
    case clear
    case back

    var label: String {
        switch self {
        case .digit(let d): d
        case .zero: "0"
        case .decimal: "."
        case .clear: "C"
        case .back: "⌫"
        }
    }

    var isUtility: Bool {
        switch self {
        case .clear, .back, .decimal: true
        default: false
        }
    }
}

// MARK: - Button

private struct PadButton: View {
    let key: PadKey
    let action: () -> Void

    @State private var pressed = false

    private let size: CGFloat = 76
    private let digitBg  = Color(hex: "#2A2A2C")
    private let utilityBg = Color(hex: "#3A3A3C")

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Group {
                if key == .zero {
                    Capsule()
                        .fill(digitBg)
                        .frame(width: size * 2 + 12, height: size)
                        .overlay(
                            Text(key.label)
                                .font(.system(size: 34, weight: .regular, design: .rounded))
                                .foregroundStyle(.white)
                        )
                } else {
                    Circle()
                        .fill(key.isUtility ? utilityBg : digitBg)
                        .frame(width: size, height: size)
                        .overlay(
                            Text(key.label)
                                .font(.system(size: 34, weight: .regular, design: .rounded))
                                .foregroundStyle(.white)
                        )
                }
            }
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
