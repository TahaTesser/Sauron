//
//  FontLoader.swift
//  Sauron
//
//  Registers bundled custom fonts at runtime so they can be used
//  with Font.custom without modifying Info.plist.
//

import Foundation
import CoreText

enum FontLoader {
    static func registerBundledFonts() {
        // Collect font URLs from the bundle, both at root and /Fonts
        var urls: [URL] = []
        if let top = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) {
            urls.append(contentsOf: top)
        }
        if let fonts = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "Fonts") {
            urls.append(contentsOf: fonts)
        }
        let fontURLs = urls.filter { ["ttf", "otf"].contains($0.pathExtension.lowercased()) }
        for url in fontURLs {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
