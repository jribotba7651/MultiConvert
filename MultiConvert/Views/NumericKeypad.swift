import SwiftUI

struct NumericKeypad: View {
    @Environment(AppState.self) private var state

    private let rows: [[KeypadKey]] = [
        [.clear, .back, .decimal, .digit("0")],
        [.digit("1"), .digit("2"), .digit("3"), .digit("4")],
        [.digit("5"), .digit("6"), .digit("7"), .digit("8")],
        [.digit("9")],
    ]

    private let grid: [[KeypadKey]] = [
        [.clear,     .back,      .decimal,   .digit("0")],
        [.digit("1"),.digit("2"),.digit("3"),.digit("4")],
        [.digit("5"),.digit("6"),.digit("7"),.digit("8")],
        [.digit("9")],
    ]

    var body: some View {
        VStack(spacing: 12) {
            row(keys: [.clear, .back, .decimal])
            row(keys: [.digit("7"), .digit("8"), .digit("9")])
            row(keys: [.digit("4"), .digit("5"), .digit("6")])
            row(keys: [.digit("1"), .digit("2"), .digit("3")])
            row(keys: [.digit("0")])
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func row(keys: [KeypadKey]) -> some View {
        HStack(spacing: 12) {
            ForEach(keys) { key in
                KeypadButton(key: key) { tap(key) }
            }
        }
    }

    private func tap(_ key: KeypadKey) {
        switch key {
        case .digit(let d): state.appendDigit(d)
        case .decimal:      state.appendDigit(".")
        case .clear:        state.clearInput()
        case .back:         state.deleteLastDigit()
        }
    }
}

// MARK: - Key Model

enum KeypadKey: Identifiable {
    case digit(String)
    case decimal
    case clear
    case back

    var id: String {
        switch self {
        case .digit(let d): "d\(d)"
        case .decimal: "decimal"
        case .clear: "clear"
        case .back: "back"
        }
    }

    var label: String {
        switch self {
        case .digit(let d): d
        case .decimal: "."
        case .clear: "C"
        case .back: "⌫"
        }
    }

    var isUtility: Bool {
        switch self {
        case .clear, .back: true
        default: false
        }
    }
}

// MARK: - Button View

struct KeypadButton: View {
    let key: KeypadKey
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Text(key.label)
                .font(Theme.keypadFont)
                .foregroundStyle(Theme.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    Circle()
                        .fill(pressed ? Theme.buttonPressed : buttonColor)
                        .aspectRatio(1, contentMode: .fit)
                )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }

    private var buttonColor: Color {
        if key.isUtility { return Theme.utilityButton }
        return Theme.digitButton
    }
}
