import SwiftUI

struct LockScreenView: View {
    @State private var lock = AppLockManager.shared

    var body: some View {
        ZStack {
            FC.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(FC.cobalt.opacity(0.08))
                        .frame(width: 96, height: 96)
                    Image(systemName: biometricIcon)
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundStyle(FC.cobalt)
                }

                Spacer().frame(height: 28)

                Text("Finery заблокирован")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(FC.ink)

                Spacer().frame(height: 8)

                Group {
                    if lock.authFailed {
                        Text("Не удалось подтвердить личность")
                            .foregroundStyle(FC.danger)
                    } else {
                        Text("Для продолжения подтвердите личность")
                            .foregroundStyle(FC.inkSecondary)
                    }
                }
                .font(.system(.subheadline, design: .rounded))
                .multilineTextAlignment(.center)

                Spacer().frame(height: 36)

                VStack(spacing: 12) {
                    // Primary: biometric button — only when enrolled
                    if lock.isBiometricReady {
                        Button {
                            Task { await lock.authenticate() }
                        } label: {
                            Label(
                                "Войти через \(lock.biometricLabel)",
                                systemImage: biometricIcon
                            )
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FC.cobalt)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .accessibilityLabel("Войти через \(lock.biometricLabel)")
                    }

                    // Secondary: device passcode
                    Button {
                        Task { await lock.authenticateWithPasscode() }
                    } label: {
                        Text("Войти по коду устройства")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(FC.cobalt)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FC.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(FC.border, lineWidth: 1)
                            )
                    }
                    .accessibilityLabel("Войти по коду устройства")
                }

                Spacer().frame(height: 16)
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .task {
            if lock.isBiometricReady {
                await lock.authenticate()
            }
        }
    }

    private var biometricIcon: String {
        lock.biometricLabel == "Face ID" ? "faceid" : "touchid"
    }
}
