//
//  ContentView.swift
//  Sauron
//
//  Created by Taha Tesser on 09.11.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack { UploadScreen() }
            .background(WindowConfigurator())
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
