import UIKit

/**
 * iOS Feedback Manager for Haptics and Vibrations.
 */
public class HardwareFeedbackManager {
    public func vibrate(duration: Int) {
        // iOS doesn't support custom duration for standard vibration easily, 
        // we use the system sound for short vibration
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    public func haptic(type: String) {
        switch type {
        case "impact":
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case "success":
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case "warning":
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case "error":
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        default:
            break
        }
    }
}
