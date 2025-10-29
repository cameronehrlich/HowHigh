import Foundation
import StoreKit
import UIKit

@MainActor
final class ReviewManager {
    /// Minimum session duration (in seconds) to count as a meaningful session
    private let minimumSessionDuration: TimeInterval = 15

    /// Requests a review after completing a meaningful session
    /// Apple's SKStoreReviewController automatically limits to 3 prompts per year
    /// - Parameter sessionDuration: Duration of the completed session in seconds
    func checkAndRequestReview(sessionDuration: TimeInterval) {
        guard sessionDuration >= minimumSessionDuration else {
            return
        }

        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
