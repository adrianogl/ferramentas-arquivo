import FileToolsCore
import SwiftUI

struct OnboardingView: View {
    let model: OnboardingModel
    let size: CGSize

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            footer
        }
        .frame(width: size.width, height: size.height)
        .background(Color.white)
        .foregroundStyle(Palette.navy)
        .environment(\.colorScheme, .light)
    }

    @ViewBuilder private var content: some View {
        switch model.step {
        case .welcome: WelcomeStep()
        case .accessibility: AccessibilityStep(model: model)
        case .finder: FinderStep(model: model)
        case .tryIt: TryItStep(model: model)
        case .done: DoneStep(model: model)
        }
    }

    private var footer: some View {
        HStack {
            StepDots(current: model.step)
            Spacer()
            HStack(spacing: 10) {
                if model.step != .welcome, model.step != .done {
                    Button("Voltar") { model.back() }
                        .buttonStyle(SecondaryButtonStyle())
                }
                primaryButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .overlay(alignment: .top) {
            Palette.border.frame(height: 1)
        }
    }

    @ViewBuilder private var primaryButton: some View {
        switch model.step {
        case .welcome:
            Button("Começar") { model.advance() }
                .buttonStyle(PrimaryButtonStyle(background: Palette.navy))
                .keyboardShortcut(.defaultAction)
        case .accessibility:
            if model.canContinue {
                continueButton
            } else {
                Button("Abrir Ajustes do Sistema") { model.openAccessibilitySettings() }
                    .buttonStyle(PrimaryButtonStyle(background: Palette.navy))
            }
        case .finder:
            if model.canContinue {
                continueButton
            } else if !model.finderGranted && model.finderRequested {
                Button("Abrir Ajustes do Sistema") { model.openAutomationSettings() }
                    .buttonStyle(PrimaryButtonStyle(background: Palette.navy))
            } else if !model.finderGranted {
                Button("Pedir permissão") { model.requestFinder() }
                    .buttonStyle(PrimaryButtonStyle(background: Palette.navy))
                    .disabled(model.isRequestingFinder)
            } else {
                Button("Abrir Ajustes do Sistema") { model.openAccessibilitySettings() }
                    .buttonStyle(PrimaryButtonStyle(background: Palette.navy))
            }
        case .tryIt:
            continueButton
        case .done:
            Button("Concluir") { model.advance() }
                .buttonStyle(PrimaryButtonStyle(background: Palette.navy))
                .keyboardShortcut(.defaultAction)
        }
    }

    private var continueButton: some View {
        Button("Continuar") { model.advance() }
            .buttonStyle(PrimaryButtonStyle(background: model.canContinue ? Palette.blue : Palette.inactive))
            .disabled(!model.canContinue)
            .keyboardShortcut(.defaultAction)
    }
}

private enum Palette {
    static let navy = Color(brand: AppConstants.Brand.navy)
    static let blue = Color(brand: AppConstants.Brand.blue)
    static let stepLabel = Color(brand: AppConstants.Brand.stepLabel)
    static let secondary = Color(brand: AppConstants.Brand.secondaryText)
    static let ground = Color(brand: AppConstants.Brand.lightGround)
    static let border = Color(brand: AppConstants.Brand.border)
    static let inactive = Color(brand: AppConstants.Brand.inactive)
    static let keycap = Color(brand: AppConstants.Brand.keycap)
    static let success = Color(brand: AppConstants.Brand.success)
    static let successText = Color(brand: AppConstants.Brand.successText)
    static let successGround = Color(brand: AppConstants.Brand.successGround)
    static let waiting = Color(brand: AppConstants.Brand.waiting)
    static let waitingText = Color(brand: AppConstants.Brand.waitingText)
}

private func strong(_ text: String) -> Text {
    Text(text).bold().foregroundStyle(Palette.navy)
}

private struct StepHeader: View {
    let step: OnboardingStep
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Passo \(step.rawValue + 1) de \(OnboardingStep.allCases.count)".uppercased())
                .font(.system(size: 12, weight: .bold))
                .kerning(0.72)
                .foregroundStyle(Palette.stepLabel)
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .kerning(-0.52)
        }
    }
}

private struct BodyText: View {
    let text: Text

    var body: some View {
        text
            .font(.system(size: 15))
            .lineSpacing(4)
            .foregroundStyle(Palette.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 18) {
            BrandMark()
                .frame(width: 96, height: 96)
            Text("Boas-vindas ao Ferramentas de Arquivo")
                .font(.system(size: 28, weight: .bold))
                .kerning(-0.56)
            BodyText(text: Text("Com ⌥ + clique direito num arquivo do Finder, um menu circular oferece sete ferramentas de PDF e imagem. Para isso funcionar, o macOS precisa de duas permissões. Leva menos de um minuto."))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AccessibilityStep: View {
    let model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            StepHeader(step: .accessibility, title: "Permitir o ⌥ + clique direito")
            BodyText(text: Text("O app precisa da permissão de \(strong("Acessibilidade")) para perceber o ⌥ + clique direito antes do Finder abrir o menu dele. Ele não lê o que você digita nem o conteúdo das janelas."))
            HStack(spacing: 14) {
                Image(systemName: "accessibility")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Palette.navy, in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ajustes do Sistema → Privacidade e Segurança → Acessibilidade")
                        .font(.system(size: 14, weight: .bold))
                    Text("Ative \(strong("Ferramentas de Arquivo")) na lista.")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.ground, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.border))
            if model.accessibilityGranted {
                StatusLine(symbol: "checkmark.circle", color: Palette.success, textColor: Palette.successText, text: "Acessibilidade concedida.")
            } else {
                StatusLine(symbol: "exclamationmark.circle", color: Palette.waiting, textColor: Palette.waitingText, text: "Aguardando a permissão. Esta tela atualiza sozinha.")
            }
        }
        .padding(.horizontal, 48)
        .padding(.top, 8)
    }
}

private struct StatusLine: View {
    let symbol: String
    let color: Color
    let textColor: Color
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(textColor)
        }
    }
}

private struct FinderStep: View {
    let model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepHeader(step: .finder, title: "Saber qual arquivo você clicou")
            BodyText(text: Text("Para ler a seleção do Finder, o app pede para \(strong("controlar o Finder")). Ele só pergunta quais arquivos estão selecionados e nunca move, apaga ou renomeia nada."))
            VStack(spacing: 8) {
                PermissionRow(name: "Acessibilidade", granted: model.accessibilityGranted, grantedText: "concedida")
                PermissionRow(name: "Controle do Finder", granted: model.finderGranted, grantedText: "concedido")
            }
            Text("Ao clicar em \"Pedir permissão\", o macOS mostra um aviso. Responda \(strong("Permitir")). Se recusar sem querer, dá para ligar depois em Ajustes do Sistema → Privacidade e Segurança → Automação.")
                .font(.system(size: 13))
                .lineSpacing(3)
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 48)
        .padding(.top, 8)
    }
}

private struct PermissionRow: View {
    let name: String
    let granted: Bool
    let grantedText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: granted ? "checkmark.circle" : "exclamationmark.circle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(granted ? Palette.success : Palette.waiting)
            Text("\(Text(name).bold()) \(granted ? grantedText : "pendente")")
                .font(.system(size: 14))
                .foregroundStyle(granted ? Palette.successText : Palette.waitingText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(granted ? Palette.successGround : Palette.ground, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            if !granted { RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.border) }
        }
    }
}

private struct TryItStep: View {
    let model: OnboardingModel

    var body: some View {
        HStack(alignment: .center, spacing: 28) {
            VStack(alignment: .leading, spacing: 16) {
                StepHeader(step: .tryIt, title: "Experimente agora")
                BodyText(text: Text("Abrimos uma janela do Finder com o arquivo \(strong(AppConstants.Onboarding.sampleFileName)). Segure \(strong("⌥")) e clique com o botão direito nele."))
                if model.triedIt {
                    StatusLine(symbol: "checkmark.circle", color: Palette.success, textColor: Palette.successText, text: "Funcionou. O app reconheceu o arquivo.")
                } else {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Palette.stepLabel)
                        Text("Esperando o ⌥ + clique direito…")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Palette.stepLabel)
                    }
                    Button("Pular este passo") { model.skipTryIt() }
                        .buttonStyle(.plain)
                        .font(.system(size: 13))
                        .underline()
                        .foregroundStyle(Palette.secondary)
                        .padding(.vertical, 10)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            TryItIllustration()
        }
        .padding(.horizontal, 48)
        .padding(.top, 8)
        .frame(maxHeight: .infinity)
    }
}

private struct DoneStep: View {
    let model: OnboardingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Palette.success)
                Text("Tudo pronto")
                    .font(.system(size: 26, weight: .bold))
                    .kerning(-0.52)
            }
            BodyText(text: Text("O app fica na barra de menus, perto do relógio. Por lá você abre as configurações quando quiser. Dois ajustes rápidos antes de começar:"))
            VStack(spacing: 0) {
                SettingRow(title: "Limite de tamanho", detail: "Para Otimizar, Imagens para PDF e Juntar") {
                    HStack(spacing: 6) {
                        TextField(
                            "Limite de tamanho",
                            value: Binding(get: { model.limitMegabytes }, set: { model.setLimitMegabytes($0) }),
                            format: .number.precision(.fractionLength(1)))
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 56)
                        Text("MB")
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.secondary)
                    }
                }
                Palette.border.frame(height: 1)
                SettingRow(title: "Abrir ao iniciar sessão", detail: "Assim o ⌥ + clique direito funciona sempre") {
                    Toggle("Abrir ao iniciar sessão", isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .tint(Palette.blue)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.border))
        }
        .padding(.horizontal, 48)
        .padding(.top, 8)
    }
}

private struct SettingRow<Control: View>: View {
    let title: String
    let detail: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.secondary)
            }
            Spacer()
            control
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct StepDots: View {
    let current: OnboardingStep

    var body: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= current.rawValue ? Palette.blue : Palette.inactive)
                    .frame(width: step == current ? 20 : 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Passo \(current.rawValue + 1) de \(OnboardingStep.allCases.count)")
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    let background: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(minHeight: 36)
            .background(background.opacity(configuration.isPressed ? 0.85 : 1), in: RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Palette.navy)
            .padding(.horizontal, 16)
            .frame(minHeight: 36)
            .background(configuration.isPressed ? Palette.ground : Color.white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.inactive))
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}
