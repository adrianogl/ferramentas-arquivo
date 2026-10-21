import FileToolsCore
import SwiftUI

struct SettingsView: View {
    let model: SettingsModel
    @State private var limitText = ""

    private var locale: Locale { Locale(identifier: AppConstants.Settings.localeIdentifier) }

    var body: some View {
        Form {
            Section("Limite de tamanho") {
                LabeledContent("Tamanho máximo") {
                    HStack(spacing: 6) {
                        TextField("Tamanho máximo", text: $limitText)
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                            .frame(width: AppConstants.Settings.limitFieldWidth)
                            .onChange(of: limitText) { _, text in commit(text) }
                        Text("MB")
                        Stepper(
                            "Tamanho máximo",
                            value: Binding(get: { model.limitMegabytes }, set: { model.setLimitMegabytes($0) }),
                            in: SettingsStore.limitMegabytesRange,
                            step: AppConstants.Settings.limitStep)
                            .labelsHidden()
                    }
                }
                Text("Vale para Otimizar PDF, Imagens para PDF e Juntar PDFs.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Geral") {
                Picker("Tecla do menu circular", selection: Binding(get: { model.triggerModifier }, set: { model.setTriggerModifier($0) })) {
                    ForEach(TriggerModifier.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                Toggle("Abrir ao iniciar sessão", isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
            }
            Section("Permissões") {
                PermissionRow(title: "Acessibilidade", granted: model.accessibilityGranted, open: Permissions.openAccessibilitySettings)
                PermissionRow(title: "Automação do Finder", granted: model.finderAutomationGranted, open: Permissions.openAutomationSettings)
            }
            Section("Ações") {
                ForEach(Constants.actions, id: \.id) { action in
                    Label {
                        Text(action.title)
                    } icon: {
                        Image(systemName: action.symbol)
                            .foregroundStyle(Color(hex: action.colorHex))
                            .frame(width: AppConstants.Settings.actionSymbolWidth)
                    }
                }
                Text("\(model.triggerModifier.glyph) + clique direito no arquivo, ou clique direito → Ações Rápidas.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: AppConstants.Settings.windowWidth)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            model.reload()
            limitText = format(model.limitMegabytes)
        }
        .onChange(of: model.limitMegabytes) { _, value in
            if parse(limitText) != value { limitText = format(value) }
        }
        .task { await model.pollPermissions() }
    }

    private func commit(_ text: String) {
        guard let value = parse(text), SettingsStore.limitMegabytesRange.contains(value) else { return }
        if value != model.limitMegabytes { model.setLimitMegabytes(value) }
    }

    private func parse(_ text: String) -> Double? {
        try? Double(text.trimmingCharacters(in: .whitespaces), format: .number.locale(locale))
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)).locale(locale))
    }
}

private struct PermissionRow: View {
    let title: String
    let granted: Bool
    let open: () -> Void

    var body: some View {
        LabeledContent {
            if !granted {
                Button("Abrir Ajustes", action: open)
            }
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(Color(hex: granted ? AppConstants.Settings.grantedColorHex : AppConstants.Settings.missingColorHex))
            }
        }
    }
}
