import LocalAuthentication
import Observation

@Observable
@MainActor
final class AppLockManager {
    static let shared = AppLockManager()
    private init() {}

    private let enabledKey  = "finery_app_lock_enabled"
    private let lockTimeout: TimeInterval = 60
    private var backgroundedAt: Date?

    var isEnabled: Bool {
        get {
            // Default true — lock is on out of the box
            guard UserDefaults.standard.object(forKey: enabledKey) != nil else { return true }
            return UserDefaults.standard.bool(forKey: enabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    var isLocked   = false
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

    // True when biometric HARDWARE is present (regardless of enrollment status)
    var isBiometricAvailable: Bool {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType != .none
    }

    // True when biometrics are enrolled and ready to evaluate right now
    var isBiometricReady: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    // Call once at cold launch, before phase = .main
    func lockOnLaunch() {
        guard isEnabled else { return }
        isLocked = true
        authFailed = false
    }

    // Call when scenePhase → .background
    func didEnterBackground() {
        guard isEnabled else { return }
        backgroundedAt = Date()
    }

    // Call when scenePhase → .active; locks only after 60 s of inactivity
    func didBecomeActive() {
        defer { backgroundedAt = nil }
        guard isEnabled, let at = backgroundedAt else { return }
        if Date().timeIntervalSince(at) >= lockTimeout {
            isLocked = true
            authFailed = false
        }
    }

    // Biometric auth — Face ID / Touch ID
    func authenticate() async {
        authFailed = false
        let ctx = LAContext()
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            await authenticateWithPasscode()
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

    // Device passcode fallback
    func authenticateWithPasscode() async {
        authFailed = false
        let ctx = LAContext()
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            isLocked = false; return
        }
        do {
            let ok = try await ctx.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Войдите в Finery"
            )
            if ok { isLocked = false }
        } catch {
            authFailed = true
        }
    }
}
