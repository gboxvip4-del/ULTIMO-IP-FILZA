import SwiftUI
import UIKit

struct LoginView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var contentVisible = false

    private let accent = AppTheme.accent

    var body: some View {
        ZStack {
            LoginBackdrop(accent: accent)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 26) {
                    Spacer(minLength: 34)

                    VStack(spacing: 11) {
                        ZStack {
                            Circle()
                                .fill(accent.opacity(0.24))
                                .frame(width: 96, height: 96)
                                .blur(radius: 18)
                            AppLogo(size: 76)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                                }
                                .shadow(color: accent.opacity(0.34), radius: 14, y: 4)
                        }
                        .frame(height: 88)

                        Text("GBOXIOSVIP")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .tracking(0.4)
                            .foregroundStyle(.white)

                        Text("ACESSO À SUA CONTA")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2.1)
                            .foregroundStyle(accent)
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("CHAVE DE ACESSO")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.3)
                                .foregroundStyle(accent)

                            Text("Informe sua chave de acesso. A API identifica o IP desta conexão e verifica se ele foi liberado.")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        SecureField("Digite sua chave de acesso", text: $viewModel.accessKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(.white)
                            .tint(accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(
                                Color.white.opacity(0.07),
                                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            }

                        Button(action: submit) {
                            Group {
                                if viewModel.isLoading {
                                    HStack(spacing: 10) {
                                        ProgressView().tint(.white)
                                        Text("Validando chave...")
                                    }
                                } else if viewModel.isRevalidating {
                                    HStack(spacing: 10) {
                                        ProgressView().tint(.white)
                                        Text("Validando chave...")
                                    }
                                } else {
                                    Label("Validar chave", systemImage: "key.fill")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    colors: [accent, Color(red: 0.00, green: 0.28, blue: 0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                            )
                            .shadow(color: accent.opacity(0.36), radius: 10, y: 4)
                        }
                        .disabled(viewModel.isLoading || viewModel.isRevalidating)
                        .buttonStyle(.plain)

                        if viewModel.showError {
                            Text(viewModel.errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(Color(red: 1.0, green: 0.40, blue: 0.40))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 2)
                        }
                    }
                    .padding(22)
                    .background(
                        Color(red: 0.012, green: 0.030, blue: 0.018),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [accent.opacity(0.62), Color.white.opacity(0.08), accent.opacity(0.24)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: accent.opacity(0.16), radius: 20, y: 8)
                    .frame(maxWidth: 420)

                    Spacer(minLength: 20)

                    Text("A API VERIFICA A CHAVE E O IP LIBERADO")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.3)
                        .foregroundStyle(Color.white.opacity(0.42))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 8)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.24)) {
                contentVisible = true
            }
        }
    }

    private func submit() {
        guard !viewModel.isLoading, !viewModel.isRevalidating else { return }
        Task { await viewModel.login() }
    }
}

private struct LoginBackdrop: View {
    let accent: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.black, Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [accent.opacity(0.30), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 380
                )

                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    path.move(to: CGPoint(x: 0, y: height * 0.18))
                    path.addLine(to: CGPoint(x: width * 0.27, y: height * 0.10))
                    path.addLine(to: CGPoint(x: width * 0.42, y: height * 0.21))
                    path.move(to: CGPoint(x: width, y: height * 0.72))
                    path.addLine(to: CGPoint(x: width * 0.76, y: height * 0.80))
                    path.addLine(to: CGPoint(x: width * 0.92, y: height * 0.92))
                }
                .stroke(accent.opacity(0.18), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}


struct AuthenticatedRootView: View {
    var body: some View {
        ContentView()
    }
}
