import FileToolsCore
import AppKit
import SwiftUI

struct SettingsView: View {
    let model: SettingsModel
    @State private var limitText = ""
    @FocusState private var limitFocused: Bool

    var body: some View {
        Form {
            Section("Limite de tamanho") {
                LabeledContent("Tamanho máximo") {
                    HStack(spacing: 6) {
                        TextField("Tamanho máximo", text: $limitText)
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                            .frame(width: AppConstants.Settings.limitFieldWidth)
                            .focused($limitFocused)
                            .onSubmit(finishEditingLimit)
                            .onChange(of: limitText) { _, text in
                                if let value = LimitInput.liveValue(text), value != model.limitMegabytes {
                                    model.setLimitMegabytes(value)
                                }
                            }
                            .onChange(of: limitFocused) { _, focused in
                                if !focused { finishEditingLimit() }
                            }
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
                Text("\(model.triggerModifier.glyph) + clique direito no arquivo, ou clique direito → Serviços.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: AppConstants.Settings.windowWidth)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            model.reload()
            limitText = LimitInput.format(model.limitMegabytes)
        }
        .onChange(of: model.limitMegabytes) { _, value in
            if LimitInput.parse(limitText) != value { limitText = LimitInput.format(value) }
        }
        .onAppear { model.startPolling() }
        .onDisappear {
            finishEditingLimit()
            model.stopPolling()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { note in
            if isSettingsWindow(note) {
                model.reload()
                model.startPolling()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { note in
            if isSettingsWindow(note) { model.stopPolling() }
        }
    }

    private func isSettingsWindow(_ note: Notification) -> Bool {
        (note.object as? NSWindow)?.title == AppConstants.Settings.windowTitle
    }

    private func finishEditingLimit() {
        let value = LimitInput.normalize(limitText, previous: model.limitMegabytes)
        model.setLimitMegabytes(value)
        limitText = LimitInput.format(model.limitMegabytes)
    }
}

private struct PermissionRow: View {
    let title: String
    let granted: Bool?
    let open: () -> Void

    var body: some View {
        LabeledContent {
            if granted == false {
                Button("Abrir Ajustes", action: open)
            }
        } label: {
            Label {
                Text(title)
            } icon: {
                switch granted {
                case true?:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: AppConstants.Settings.grantedColorHex))
                case false?:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color(hex: AppConstants.Settings.missingColorHex))
                case nil:
                    Image(systemName: "circle.dotted")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
