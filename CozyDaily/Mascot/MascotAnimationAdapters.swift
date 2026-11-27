import SwiftUI
import CozyCore

// Hai adapter dưới đây chỉ được biên dịch khi bạn thêm package tương ứng vào `project.yml`:
//   Lottie: https://github.com/airbnb/lottie-ios  (product "Lottie", from 4.4.0)
//   Rive:   https://github.com/rive-app/rive-ios  (product "RiveRuntime", from 6.0.0)

#if canImport(Lottie)
import Lottie

struct LottieMascotProvider: MascotAnimationProvider {
    func canRender(resource: String) -> Bool {
        Bundle.main.url(forResource: resource, withExtension: "json") != nil
    }

    func makeView(resource: String, state: MascotState, isPaused: Bool) -> AnyView {
        AnyView(
            LottieView(animation: .named(resource))
                .playbackMode(isPaused ? .paused : .playing(.toProgress(1, loopMode: .loop)))
                .resizable()
                .scaledToFit()
                .id(resource)
        )
    }
}
#endif

#if canImport(RiveRuntime)
import RiveRuntime

struct RiveMascotProvider: MascotAnimationProvider {
    func canRender(resource: String) -> Bool {
        Bundle.main.url(forResource: resource, withExtension: "riv") != nil
    }

    func makeView(resource: String, state: MascotState, isPaused: Bool) -> AnyView {
        AnyView(RiveMascot(resource: resource, isPaused: isPaused).id(resource))
    }
}

private struct RiveMascot: View {
    var isPaused: Bool
    @StateObject private var model: RiveViewModel

    init(resource: String, isPaused: Bool) {
        self.isPaused = isPaused
        _model = StateObject(wrappedValue: RiveViewModel(fileName: resource))
    }

    var body: some View {
        model.view()
            .onAppear { if isPaused { model.pause() } }
            .onChange(of: isPaused) { _, paused in
                if paused { model.pause() } else { model.play() }
            }
    }
}
#endif
