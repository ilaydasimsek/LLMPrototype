import SwiftUI
import llmfarm_core_cpp

struct ScreenshotAnalyzerView: View {
    
    @ObservedObject var viewModel: ScreenshotAnalyzerViewModel
    
    var body: some View {
        VStack {
            if let url: URL = viewModel.currentScreenShotURL {
                Image(nsImage: NSImage(contentsOf: url)!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 500, height: 500)
            } else {
                Spacer()
                    .frame(width: 500, height: 500)
            }
            if viewModel.loading {
                ProgressView()
            } else {
                Text(viewModel.output ?? "")
            }
            Spacer()
            Button("Take Screenshot") {
                viewModel.takeAndAnalyzeScreenshot()
            }.disabled(!viewModel.aiModelReady)
        }
        .padding()
    }
}

#Preview {
    ScreenshotAnalyzerView(viewModel: ScreenshotAnalyzerViewModel())
}
