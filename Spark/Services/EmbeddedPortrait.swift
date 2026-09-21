import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 从 Bundle / 内嵌常量加载日漫立ち絵（casual / lingerie）
enum EmbeddedPortrait {
    private static func loadB64(_ name: String) -> String? {
        switch name {
        case "casual":
            let v = CasualArtB64.value
            if !v.isEmpty { return v }
        case "lingerie":
            let v = LingerieArtB64.value
            if !v.isEmpty { return v }
        default:
            break
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "b64.txt"),
           let s = try? String(contentsOf: url, encoding: .utf8) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
        }
        var acc = ""
        for i in 0..<16 {
            guard let url = Bundle.main.url(forResource: "\(name).b64.part\(i)", withExtension: "txt"),
                  let s = try? String(contentsOf: url, encoding: .utf8) else { break }
            acc += s.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return acc.isEmpty ? nil : acc
    }

    static var casualImage: Image? {
        #if canImport(UIKit)
        return decodeImage(named: "casual")
        #else
        return nil
        #endif
    }

    static var lingerieImage: Image? {
        #if canImport(UIKit)
        return decodeImage(named: "lingerie")
        #else
        return nil
        #endif
    }

    #if canImport(UIKit)
    private static func decodeImage(named resource: String) -> Image? {
        guard let b64 = loadB64(resource), let data = Data(base64Encoded: b64), let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
    }

    static var casualUIImage: UIImage? {
        guard let b64 = loadB64("casual"), let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
    }

    static var lingerieUIImage: UIImage? {
        guard let b64 = loadB64("lingerie"), let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
    }
    #endif
}
