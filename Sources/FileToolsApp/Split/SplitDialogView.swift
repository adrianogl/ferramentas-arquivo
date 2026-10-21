import FileToolsCore
import SwiftUI

struct SplitDialogView: View {
    let onCancel: () -> Void
    let onConfirm: (SplitMode) -> Void
    @State private var form: SplitForm
    @FocusState private var isRangeFocused: Bool

    init(form: SplitForm, onCancel: @escaping () -> Void, onConfirm: @escaping (SplitMode) -> Void) {
        _form = State(initialValue: form)
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: AppConstants.Split.rowSpacing) {
                RadioRow(label: "Separar todas as páginas", isOn: form.choice == .allPages, select: { form.choice = .allPages }) {
                    EmptyView()
                } detail: {
                    Caption(text: form.allPagesCaption)
                }
                RadioRow(label: "Extrair páginas:", isOn: form.choice == .extract, select: selectExtract) {
                    rangeField
                } detail: {
                    if let error = form.rangeError {
                        Text(error)
                            .font(.system(size: AppConstants.Split.captionSize))
                            .foregroundStyle(Color(brand: AppConstants.Split.errorText))
                    } else {
                        Caption(text: form.extractCaption)
                    }
                }
            }
            .padding(.horizontal, AppConstants.Split.horizontalPadding)
            .padding(.top, AppConstants.Split.topPadding)

            HStack(spacing: AppConstants.Split.buttonSpacing) {
                Spacer()
                Button("Cancelar", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Dividir", action: confirm)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!form.canConfirm)
            }
            .controlSize(.large)
            .padding(.horizontal, AppConstants.Split.horizontalPadding)
            .padding(.top, AppConstants.Split.footerTopPadding)
            .padding(.bottom, AppConstants.Split.bottomPadding)
        }
        .font(.system(size: AppConstants.Split.textSize))
        .frame(width: AppConstants.Split.width, alignment: .leading)
    }

    private var rangeField: some View {
        TextField(
            "ex.: 1-3, 5",
            text: Binding(get: { form.rangeText }, set: { form.editRange($0) }))
            .textFieldStyle(.roundedBorder)
            .frame(width: AppConstants.Split.fieldWidth)
            .focused($isRangeFocused)
            .onSubmit(confirm)
            .overlay {
                if form.rangeError != nil {
                    RoundedRectangle(cornerRadius: AppConstants.Split.fieldCornerRadius)
                        .strokeBorder(Color(brand: AppConstants.Split.errorBorder))
                        .padding(-1)
                        .shadow(color: Color(brand: AppConstants.Split.errorBorder).opacity(AppConstants.Split.errorGlowOpacity), radius: AppConstants.Split.errorGlowRadius)
                        .allowsHitTesting(false)
                }
            }
    }

    private func selectExtract() {
        form.choice = .extract
        isRangeFocused = true
    }

    private func confirm() {
        guard let mode = form.mode else { return }
        onConfirm(mode)
    }
}

private struct Caption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: AppConstants.Split.captionSize))
            .foregroundStyle(.secondary)
    }
}

private struct RadioRow<Accessory: View, Detail: View>: View {
    let label: String
    let isOn: Bool
    let select: () -> Void
    @ViewBuilder let accessory: Accessory
    @ViewBuilder let detail: Detail

    var body: some View {
        HStack(alignment: .top, spacing: AppConstants.Split.radioSpacing) {
            RadioDot(isOn: isOn)
                .padding(.top, AppConstants.Split.radioTopInset)
                .contentShape(Rectangle())
                .onTapGesture(perform: select)
                .accessibilityElement()
                .accessibilityLabel(label)
                .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
                .accessibilityAction(.default, select)
            VStack(alignment: .leading, spacing: AppConstants.Split.captionSpacing) {
                HStack(spacing: AppConstants.Split.fieldSpacing) {
                    Text(label)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: select)
                    accessory
                }
                detail
            }
        }
    }
}

private struct RadioDot: View {
    let isOn: Bool

    var body: some View {
        let size = AppConstants.Split.radioSize
        Circle()
            .fill(isOn ? Color.white : Color(nsColor: .controlBackgroundColor))
            .overlay {
                Circle().strokeBorder(
                    isOn ? Color(brand: AppConstants.Split.accent) : Color(brand: AppConstants.Split.radioBorder),
                    lineWidth: isOn ? AppConstants.Split.radioOnBorder : 1)
            }
            .frame(width: size, height: size)
    }
}
