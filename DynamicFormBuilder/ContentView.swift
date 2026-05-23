//
//  ContentView.swift
//  DynamicFormBuilder
//
//  Created by Rahul Kiumar on 23/05/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        FormRendererView()
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager.shared)
}
