//
//  DynamicFormBuilderApp.swift
//  DynamicFormBuilder
//
//  Created by Rahul Kiumar on 23/05/26.
//

import SwiftUI

@main
struct DynamicFormBuilderApp: App {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}
