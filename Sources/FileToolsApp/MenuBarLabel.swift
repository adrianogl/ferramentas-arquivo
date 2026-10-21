import AppKit
import SwiftUI

struct MenuBarLabel: View {
    var body: some View {
        if let image = Self.templateImage {
            Image(nsImage: image)
        } else {
            Image(systemName: AppConstants.MenuBar.fallbackSymbol)
        }
    }

    private static let templateImage: NSImage? = {
        guard let url = Bundle.main.url(
            forResource: AppConstants.MenuBar.iconResource,
            withExtension: AppConstants.MenuBar.iconExtension
        ), let image = NSImage(contentsOf: url) else {
            Log.app.error("MenuBarIcon.pdf ausente no bundle; usando o SF Symbol")
            return nil
        }
        image.isTemplate = true
        return image
    }()
}
