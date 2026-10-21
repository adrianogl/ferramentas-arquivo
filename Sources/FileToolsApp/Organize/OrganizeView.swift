import AppKit
import FileToolsCore
import SwiftUI

struct OrganizeView: View {
    let viewModel: OrganizeViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                PageGrid(viewModel: viewModel)
                    .padding(AppConstants.Organize.gridPadding)
            }
            .background(Color(nsColor: .underPageBackgroundColor))
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.clearSelection)
            .dropDestination(for: URL.self) { urls, _ in
                viewModel.append(urls)
                return true
            }
            Divider()
            StatusBar(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.rotateSelection(by: -AppConstants.Organize.rotationStep)
                } label: {
                    Label("Girar à esquerda", systemImage: "rotate.left")
                }
                .help("Girar à esquerda (⌘←)")
                .disabled(!viewModel.hasSelection)
                Button {
                    viewModel.rotateSelection(by: AppConstants.Organize.rotationStep)
                } label: {
                    Label("Girar à direita", systemImage: "rotate.right")
                }
                .help("Girar à direita (⌘→)")
                .disabled(!viewModel.hasSelection)
                Button {
                    viewModel.deleteSelection()
                } label: {
                    Label("Apagar", systemImage: "trash")
                }
                .help("Apagar (⌫)")
                .disabled(!viewModel.hasSelection)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Adicionar…") { viewModel.onAdd?() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Salvar") { viewModel.onSave?() }
                    .buttonStyle(.borderedProminent)
                    .help("Salvar (⌘S)")
                    .disabled(!viewModel.canSave)
            }
        }
    }
}

struct PageGrid: View {
    let viewModel: OrganizeViewModel

    var body: some View {
        let spacing = AppConstants.Organize.gridSpacing
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: AppConstants.Organize.cellMinimumWidth), spacing: spacing)],
            spacing: spacing
        ) {
            ForEach(Array(viewModel.model.pages.enumerated()), id: \.element.id) { offset, page in
                PageCell(
                    page: page,
                    number: offset + 1,
                    isSelected: viewModel.selection.ids.contains(page.id),
                    cache: viewModel.thumbnails,
                    onClick: { viewModel.click(page.id, gesture: $0) },
                    onDrop: { viewModel.drop($0, onto: page.id) })
            }
        }
    }
}

private struct StatusBar: View {
    let viewModel: OrganizeViewModel

    var body: some View {
        HStack {
            Text(OrganizeText.status(
                pageCount: viewModel.model.pages.count, selectedCount: viewModel.selection.ids.count))
            Spacer()
            Text(OrganizeText.saveHint(for: viewModel.original))
        }
        .font(.system(size: AppConstants.Organize.statusSize))
        .foregroundStyle(.secondary)
        .padding(.horizontal, AppConstants.Organize.statusHorizontalPadding)
        .padding(.vertical, AppConstants.Organize.statusVerticalPadding)
    }
}

private struct PageCell: View {
    let page: OrganizePage
    let number: Int
    let isSelected: Bool
    let cache: ThumbnailCache
    let onClick: (PageSelection.Gesture) -> Void
    let onDrop: ([String]) -> Bool
    @State private var image: CGImage?
    @State private var isTargeted = false

    init(
        page: OrganizePage, number: Int, isSelected: Bool, cache: ThumbnailCache,
        onClick: @escaping (PageSelection.Gesture) -> Void, onDrop: @escaping ([String]) -> Bool
    ) {
        self.page = page
        self.number = number
        self.isSelected = isSelected
        self.cache = cache
        self.onClick = onClick
        self.onDrop = onDrop
        _image = State(initialValue: cache.cached(page.id))
    }

    var body: some View {
        VStack(spacing: AppConstants.Organize.labelSpacing) {
            Paper(image: image, rotation: page.rotation, isSelected: isSelected, isTargeted: isTargeted)
            Text("\(number)")
                .font(.system(size: AppConstants.Organize.numberSize, weight: isSelected ? .semibold : .regular))
                .monospacedDigit()
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .padding(.horizontal, AppConstants.Organize.pillHorizontalPadding)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: AppConstants.Organize.pillCornerRadius)
                            .fill(Color(brand: AppConstants.Organize.selection))
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onClick(Self.gesture(for: NSEvent.modifierFlags)) }
        .task(id: page.id) {
            guard image == nil else { return }
            image = await cache.load(page)
        }
        .draggable(page.id.uuidString) {
            Paper(image: image, rotation: page.rotation, isSelected: false, isTargeted: false)
        }
        .dropDestination(for: String.self) { items, _ in
            onDrop(items)
        } isTargeted: { isTargeted = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Página \(number)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private static func gesture(for flags: NSEvent.ModifierFlags) -> PageSelection.Gesture {
        if flags.contains(.shift) { return .extend }
        if flags.contains(.command) { return .toggle }
        return .single
    }
}

private struct Paper: View {
    let image: CGImage?
    let rotation: Int
    let isSelected: Bool
    let isTargeted: Bool

    var body: some View {
        let box = AppConstants.Organize.paperSize
        let isQuarterTurn = rotation % 180 != 0
        let fitted = Self.fit(aspect: aspect(quarterTurn: isQuarterTurn), in: box)
        let unrotated = isQuarterTurn ? CGSize(width: fitted.height, height: fitted.width) : fitted
        let corner = AppConstants.Organize.paperCornerRadius
        let outline = AppConstants.Organize.selectionWidth
        ZStack {
            RoundedRectangle(cornerRadius: corner).fill(Color.white)
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .clipShape(RoundedRectangle(cornerRadius: corner))
            }
        }
        .frame(width: unrotated.width, height: unrotated.height)
        .shadow(color: .black.opacity(AppConstants.Organize.paperShadowOpacity), radius: AppConstants.Organize.paperShadowRadius, y: 1)
        .overlay {
            if isSelected || isTargeted {
                RoundedRectangle(cornerRadius: corner + outline)
                    .stroke(
                        Color(brand: AppConstants.Organize.selection),
                        style: StrokeStyle(lineWidth: outline, dash: isTargeted && !isSelected ? AppConstants.Organize.targetDash : []))
                    .padding(-outline * 1.5)
            }
        }
        .rotationEffect(.degrees(Double(rotation)))
        .frame(width: box.width, height: box.height)
    }

    private func aspect(quarterTurn: Bool) -> CGFloat {
        guard let image, image.height > 0 else {
            let box = AppConstants.Organize.paperSize
            return box.width / box.height
        }
        let ratio = CGFloat(image.width) / CGFloat(image.height)
        return quarterTurn ? 1 / ratio : ratio
    }

    private static func fit(aspect: CGFloat, in box: CGSize) -> CGSize {
        if aspect > box.width / box.height {
            return CGSize(width: box.width, height: box.width / aspect)
        }
        return CGSize(width: box.height * aspect, height: box.height)
    }
}
