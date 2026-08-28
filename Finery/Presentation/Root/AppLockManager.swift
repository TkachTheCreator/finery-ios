import LocalAuthentication
import Observation

@Observable
@MainActor
final class AppLockManager {
    static let shared = AppLockManager()
    private init() {}

    private let enabledKey = "finery_app_lock_enabled"

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    var isLocked = false
    var authFailed = false

    var biometricLabel: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch ctx.biometryType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        default:       return "Биометрия"
        }
    }

    var isBiometricAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func lockIfNeeded() {
        guard isEnabled else { return }
        isLocked = true
        authFailed = false
    }

    func authenticate() async {
        authFailed = false
        let ctx = LAContext()
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            isLocked = false
            return
        }
        do {
            let ok = try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Войдите в Finery"
            )
            if ok { isLocked = false }
        } catch {
            authFailed = true
        }
    }
}
