import LocalAuthentication

/**
 * iOS Biometric Manager using LocalAuthentication (FaceID and TouchID).
 */
public class HardwareBiometricManager {
    private var localizedFallbackTitle: String?
    private var localizedCancelTitle: String?
    private var allowDevicePasscode = true

    public func configure(options: [String: Any]) {
        localizedFallbackTitle = options["localizedFallbackTitle"] as? String
        localizedCancelTitle = options["localizedCancelTitle"] as? String
        allowDevicePasscode = options["allowDevicePasscode"] as? Bool ?? true
    }

    public func canAuthenticate() -> Bool {
        let context = LAContext()
        var error: NSError?
        let policy: LAPolicy = allowDevicePasscode
            ? .deviceOwnerAuthentication
            : .deviceOwnerAuthenticationWithBiometrics
        return context.canEvaluatePolicy(policy, error: &error)
    }

    public func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = localizedFallbackTitle
        context.localizedCancelTitle = localizedCancelTitle
        let policy: LAPolicy = allowDevicePasscode
            ? .deviceOwnerAuthentication
            : .deviceOwnerAuthenticationWithBiometrics
        context.evaluatePolicy(policy, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
}
