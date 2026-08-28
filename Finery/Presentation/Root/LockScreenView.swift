import SwiftUI

struct LockScreenView: View {
    @State private var lock = AppLockManager.shared

    var body: some View {
        ZStack {
            FC.background.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(FC.cobalt)
                VStack(spacing: 8) {
                    Text("Finery заблокирован")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(FC.ink)
                    if lock.authFailed {
                        Text("Не удалось войти. Повторите попытку.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(FC.danger)
                    }
                }
                Button {
                    Task { await lock.authenticate() }
                } label: {
                    Label("Войти через \(lock.biometricLabel)", systemImage: lock.biometricLabel == "Face ID" ? "faceid" : "touchid")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(FC.cobalt)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .task { await lock.authenticate() }
    }
}
