import Foundation
import StoreKit
import UIKit

@MainActor
final class ReviewManager {
    static let appStoreID = "921339656"

    private let defaults: UserDefaults
    private let minimumSessionDuration: TimeInterval = 15
    private let actionsBeforePrompt = 3

    private enum Keys {
        static let meaningfulActionCount = "review.meaningfulActionCount"
        static let lastPromptDate = "review.lastPromptDate"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Records a meaningful action and requests review at milestones.
    /// Called after completing a session or calibrating.
    func checkAndRequestReview(sessionDuration: TimeInterval) {
        guard sessionDuration >= minimumSessionDuration else { return }
        recordAction()
    }

    /// Records a calibration as a meaningful action
    func recordCalibration() {
        recordAction()
    }

    /// Opens the App Store "Write a Review" page directly
    static func openWriteReview() {
        guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review") else { return }
        UIApplication.shared.open(url)
    }

    private func recordAction() {
        let count = defaults.integer(forKey: Keys.meaningfulActionCount) + 1
        defaults.set(count, forKey: Keys.meaningfulActionCount)

        // Prompt at 3, 10, 25 actions (then never again automatically)
        let milestones = [3, 10, 25]
        guard milestones.contains(count) else { return }

        // Don't prompt more than once per 60 days
        if let lastPrompt = defaults.object(forKey: Keys.lastPromptDate) as? Date,
           Date().timeIntervalSince(lastPrompt) < 60 * 24 * 60 * 60 {
            return
        }

        defaults.set(Date(), forKey: Keys.lastPromptDate)
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
