import SwiftUI
import Lottie

struct LottieSuccessView: UIViewRepresentable {
    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: "success")
        view.loopMode = .playOnce
        view.contentMode = .scaleAspectFit
        view.play()
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
