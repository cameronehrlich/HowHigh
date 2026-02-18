import SwiftUI

enum IdleTimerPolicy {
    static func shouldDisableIdleTimer(keepScreenOn: Bool, scenePhase: ScenePhase) -> Bool {
        keepScreenOn && scenePhase != .background
    }
}
