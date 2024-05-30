//
//  LLMPrototypeApp.swift
//  LLMPrototype
//
//  Created by İlayda Şimşek on 30.05.2024.
//

import SwiftUI

@main
struct LLMPrototypeApp: App {
    var viewModel = ScreenshotHandlerViewModel()

    var body: some Scene {
        WindowGroup {
            ScreenshotHandlerView(viewModel: viewModel)
        }
    }
}
