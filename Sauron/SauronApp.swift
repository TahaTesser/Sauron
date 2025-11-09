//
//  SauronApp.swift
//  Sauron
//
//  Created by Taha Tesser on 09.11.2025.
//

import SwiftUI

@main
struct SauronApp: App {
    init() {
        FontLoader.registerBundledFonts()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
