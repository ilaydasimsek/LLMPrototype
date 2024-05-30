import SwiftUI

struct ScreenshotHandlerView: View {
    
    @ObservedObject var viewModel: ScreenshotHandlerViewModel
    
    var body: some View {
        VStack {
            Button("Start Taking Screenshots") {
                viewModel.startSavingScreenshots()
            }
            Button("Stop Taking Screenshot") {
                viewModel.stopSavingScreenshots()
            }
        }
        .padding()
    }
}

#Preview {
    ScreenshotHandlerView(viewModel: ScreenshotHandlerViewModel())
}
