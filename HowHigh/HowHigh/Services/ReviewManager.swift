import Foundation
import StoreKit
import UIKit

@MainActor
final class ReviewManager {
    private let settingsStore: SettingsStore

    /// Session milestones at which to request reviews: 3rd, 8th, 20th, 50th, 100th
    private let reviewMilestones: Set<Int> = [3, 8, 20, 50, 100]

    /// Minimum session duration (in seconds) to count as a meaningful session
    private let minimumSessionDuration: TimeInterval = 15

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    /// Checks if we should request a review after completing a session
    /// - Parameter sessionDuration: Duration of the completed session in seconds
    func checkAndRequestReview(sessionDuration: TimeInterval) {
        guard sessionDuration >= minimumSessionDuration else {
            return
        }

        settingsStore.incrementCompletedSessions()
        let completedCount = settingsStore.completedSessionsCount

        guard reviewMilestones.contains(completedCount) else {
            return
        }

        requestReview()
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            settingsStore.recordReviewRequested()
        }
    }
}
