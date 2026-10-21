import CoreGraphics
import Foundation
import PDFKit

public enum PDFAssembler {
    public static func assemble(_ pages: [PDFPageSource]) throws(ActionFailure) -> Data {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data),
              let ctx = CGContext(consumer: consumer, mediaBox: nil, nil)
        else { throw .writeFailed }
        var rotations: [Int] = []
        for source in pages {
            switch source {
            case let .vector(page, extraRotation):
                rotations.append(drawVector(page, extraRotation: extraRotation, in: ctx))
            case let .image(image, pageSize, rotation):
                drawImage(image, pageSize: pageSize, rotation: rotation, in: ctx)
                rotations.append(0)
            }
        }
        ctx.closePDF()
        guard data.length > 0 else { throw .writeFailed }
        return try applyRotations(rotations, to: data as Data)
    }

    public static func imagePageSize(for image: CGImage) -> CGSize {
        let longSide = CGFloat(max(image.width, image.height))
        let scale = Constants.imagePageLongSide / longSide
        return CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
    }

    private static func normalized(_ degrees: Int) -> Int {
        ((degrees % 360) + 360) % 360
    }

    private static func applyRotations(_ rotations: [Int], to data: Data) throws(ActionFailure) -> Data {
        guard rotations.contains(where: { $0 != 0 }) else { return data }
        guard let document = PDFDocument(data: data), document.pageCount == rotations.count else {
            throw .writeFailed
        }
        for (index, rotation) in rotations.enumerated() {
            document.page(at: index)?.rotation = rotation
        }
        guard let rotated = document.dataRepresentation() else { throw .writeFailed }
        return rotated
    }

    private static func drawVector(_ page: PDFPage, extraRotation: Int, in ctx: CGContext) -> Int {
        guard let copy = page.copy() as? PDFPage else { return 0 }
        let totalRotation = normalized(copy.rotation + extraRotation)
        copy.rotation = 0
        var box = CGRect(origin: .zero, size: copy.bounds(for: .cropBox).size)
        let info = [kCGPDFContextMediaBox as String: Data(bytes: &box, count: MemoryLayout<CGRect>.size)]
        ctx.beginPDFPage(info as CFDictionary)
        copy.transform(ctx, for: .cropBox)
        copy.draw(with: .cropBox, to: ctx)
        ctx.endPDFPage()
        return totalRotation
    }

    private static func drawImage(_ image: CGImage, pageSize: CGSize, rotation: Int, in ctx: CGContext) {
        let turns = normalized(rotation)
        let swapped = turns % 180 != 0
        var box = CGRect(
            origin: .zero,
            size: swapped ? CGSize(width: pageSize.height, height: pageSize.width) : pageSize
        )
        let info = [kCGPDFContextMediaBox as String: Data(bytes: &box, count: MemoryLayout<CGRect>.size)]
        ctx.beginPDFPage(info as CFDictionary)
        switch turns {
        case 90:
            ctx.translateBy(x: 0, y: pageSize.width)
            ctx.rotate(by: -.pi / 2)
        case 180:
            ctx.translateBy(x: pageSize.width, y: pageSize.height)
            ctx.rotate(by: .pi)
        case 270:
            ctx.translateBy(x: pageSize.height, y: 0)
            ctx.rotate(by: .pi / 2)
        default:
            break
        }
        ctx.draw(image, in: CGRect(origin: .zero, size: pageSize))
        ctx.endPDFPage()
    }
}
