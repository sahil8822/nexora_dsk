import UIKit
import AudioToolbox

/// iOS Feedback Manager for Haptics and Vibrations.
public class HardwareFeedbackManager {
    public func vibrate(duration: Int) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    public func haptic(type: String) {
        switch type {
        case "impact":
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        case "success":
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        case "warning":
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        case "error":
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        default:
            break
        }
    }
}
