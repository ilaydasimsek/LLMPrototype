//
//  LLMPrototypeApp.swift
//  LLMPrototype
//
//  Created by İlayda Şimşek on 30.05.2024.
//

import SwiftUI

@main
struct LLMPrototypeApp: App {
    var viewModel = ScreenshotAnalyzerViewModel()

    var body: some Scene {
        WindowGroup {
            ScreenshotAnalyzerView(viewModel: viewModel)
        }
    }
}
