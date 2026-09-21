import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 从 Bundle 文本资源加载日漫立ち絵（casual / lingerie）
enum EmbeddedPortrait {
    private static func loadB64(_ name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "b64.txt"),
              let s = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func image(named resource: String) -> Image? {
        #if canImport(UIKit)
        guard let b64 = loadB64(resource), let data = Data(base64Encoded: b64), let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
        #else
        return nil
        #endif
    }

    static var casualImage: Image? { image(named: "casual") }
    static var lingerieImage: Image? { image(named: "lingerie") }
    static var casualUIImage: UIImage? {
        #if canImport(UIKit)
        guard let b64 = loadB64("casual"), let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
        #else
        return nil
        #endif
    }
    static var lingerieUIImage: UIImage? {
        #if canImport(UIKit)
        guard let b64 = loadB64("lingerie"), let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
        #else
        return nil
        #endif
    }
}
