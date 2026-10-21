import CoreGraphics
import PDFKit

public enum ScannedPageDetector {
    public static func isScanned(_ page: PDFPage) -> Bool {
        guard let pageRef = page.pageRef else { return false }
        let box = page.bounds(for: .cropBox)
        let pageArea = Int((box.width * box.height).rounded())
        return largestImageArea(in: pageRef) >= pageArea
    }

    private static func largestImageArea(in pageRef: CGPDFPage) -> Int {
        guard let pageDictionary = pageRef.dictionary else { return 0 }
        var resources: CGPDFDictionaryRef?
        var xObjects: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(pageDictionary, "Resources", &resources), let resources,
              CGPDFDictionaryGetDictionary(resources, "XObject", &xObjects), let xObjects
        else { return 0 }
        var largest = 0
        CGPDFDictionaryApplyBlock(xObjects, { _, object, _ in
            var stream: CGPDFStreamRef?
            guard CGPDFObjectGetValue(object, .stream, &stream), let stream,
                  let streamDictionary = CGPDFStreamGetDictionary(stream)
            else { return true }
            var subtype: UnsafePointer<CChar>?
            var width: CGPDFInteger = 0
            var height: CGPDFInteger = 0
            guard CGPDFDictionaryGetName(streamDictionary, "Subtype", &subtype), let subtype,
                  String(cString: subtype) == "Image",
                  CGPDFDictionaryGetInteger(streamDictionary, "Width", &width),
                  CGPDFDictionaryGetInteger(streamDictionary, "Height", &height)
            else { return true }
            largest = max(largest, width * height)
            return true
        }, nil)
        return largest
    }
}
