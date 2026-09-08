import SwiftUI

struct SpringToggle: View {
    @Binding var isOn: Bool
    var onChanged: (() -> Void)? = nil

    @GestureState private var isPressing = false

    private let width: CGFloat = 51
    private let height: CGFloat = 31
    private let thumbSize: CGFloat = 27

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? FC.cobalt : Color(white: 0.78))
                .animation(.easeInOut(duration: 0.2), value: isOn)

            Circle()
                .fill(.white)
                .frame(width: thumbSize, height: thumbSize)
                .scaleEffect(isPressing ? 0.87 : 1.0)
                .padding(2)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressing)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isOn)
        }
        .frame(width: width, height: height)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressing) { _, state, _ in state = true }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isOn.toggle()
                    }
                    onChanged?()
                }
        )
    }
}
