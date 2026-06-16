import SwiftUI
import AVKit

final class LoopingVideoPlayer: ObservableObject {
    let player: AVQueuePlayer
    private var looper: AVPlayerLooper?

    init(resourceName: String, resourceExtension: String) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
            player = AVQueuePlayer()
            return
        }
        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none
        queuePlayer.play()
        player = queuePlayer
    }
}

struct LoopingVideoBackground: View {
    @StateObject private var videoPlayer = LoopingVideoPlayer(resourceName: "blue_glow_background", resourceExtension: "mp4")

    var body: some View {
        VideoPlayer(player: videoPlayer.player)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.08),
                        Color.black.opacity(0.35),
                        Color.black.opacity(0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}
