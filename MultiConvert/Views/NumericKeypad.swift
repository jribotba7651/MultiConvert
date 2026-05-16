import SwiftUI

struct NumericKeypad: View {
    @Environment(AppState.self) private var state

    // GeometryReader fills all offered space vertically, which would crowd the list
    // above it. Fix: pin the outer frame to the computed height so the VStack in
    // ContentView allocates exactly the right amount.
    @State private var computedHeight: CGFloat = 480

    private let horizontalPadding: CGFloat = 16
    private let interButtonSpacing: CGFloat = 12
    private let numColumns: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            let totalSpacing = interButtonSpacing * (numColumns - 1)
            let availableWidth = geometry.size.width - (horizontalPadding * 2) - totalSpacing
            let d = availableWidth / numColumns

            let gridColumns = Array(
                repeating: GridItem(.flexible(), spacing: interButtonSpacing),
                count: Int(numColumns)
            )

            LazyVGrid(columns: gridColumns, spacing: interButtonSpacing) {

                // Row 1: utilities + col-4 placeholder
                PadButton(key: .clear,   diameter: d) { state.clearInput() }
                PadButton(key: .back,    diameter: d) { state.deleteLastDigit() }
                PadButton(key: .decimal, diameter: d) { state.appendDigit(".") }
                emptyCell(size: d)

                // Row 2
                PadButton(key: .digit("7"), diameter: d) { state.appendDigit("7") }
                PadButton(key: .digit("8"), diameter: d) { state.appendDigit("8") }
                PadButton(key: .digit("9"), diameter: d) { state.appendDigit("9") }
                emptyCell(size: d)

                // Row 3
                PadButton(key: .digit("4"), diameter: d) { state.appendDigit("4") }
                PadButton(key: .digit("5"), diameter: d) { state.appendDigit("5") }
                PadButton(key: .digit("6"), diameter: d) { state.appendDigit("6") }
                emptyCell(size: d)

                // Row 4
                PadButton(key: .digit("1"), diameter: d) { state.appendDigit("1") }
                PadButton(key: .digit("2"), diameter: d) { state.appendDigit("2") }
                PadButton(key: .digit("3"), diameter: d) { state.appendDigit("3") }
                emptyCell(size: d)

                // Row 5: zero spans cols 1-2 via explicit wider frame;
                // col-2 placeholder below it has hit-testing off so it doesn't
                // block touches from the overlapping zero button.
                PadButton(key: .zero, diameter: d, zeroSpacing: interButtonSpacing) {
                    state.appendDigit("0")
                }
                emptyCell(size: d)  // col 2 — hidden under zero, no hit-testing
                emptyCell(size: d)  // col 3
                emptyCell(size: d)  // col 4
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 24)
            .onAppear          { computedHeight = keypadHeight(diameter: d) }
            .onChange(of: geometry.size.width) { _, newW in
                let newD = (newW - horizontalPadding * 2 - totalSpacing) / numColumns
                computedHeight = keypadHeight(diameter: newD)
            }
        }
        .frame(height: computedHeight)
    }

    // 5 rows × diameter + 4 inter-row gaps + bottom padding
    private func keypadHeight(diameter: CGFloat) -> CGFloat {
        5 * diameter + 4 * interButtonSpacing + 24
    }

    // Non-interactive spacer cell for empty grid positions
    @ViewBuilder
    private func emptyCell(size: CGFloat) -> some View {
        Color.clear
            .frame(width: size, height: size)
            .allowsHitTesting(false)
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
        case .zero:    "0"
        case .decimal: "."
        case .clear:   "C"
        case .back:    "⌫"
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
    let diameter: CGFloat
    var zeroSpacing: CGFloat = 0   // only used when key == .zero
    let action: () -> Void

    @State private var pressed = false

    private let digitBg   = Color(hex: "#2A2A2C")
    private let utilityBg = Color(hex: "#3A3A3C")

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            let fs = diameter * 0.42

            if key == .zero {
                Capsule()
                    .fill(digitBg)
                    .frame(width: (diameter * 2) + zeroSpacing, height: diameter)
                    .overlay(
                        Text(key.label)
                            .font(.system(size: fs, weight: .regular, design: .rounded))
                            .foregroundStyle(.white)
                    )
            } else {
                Circle()
                    .fill(key.isUtility ? utilityBg : digitBg)
                    .frame(width: diameter, height: diameter)
                    .overlay(
                        Text(key.label)
                            .font(.system(size: fs, weight: .regular, design: .rounded))
                            .foregroundStyle(.white)
                    )
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
