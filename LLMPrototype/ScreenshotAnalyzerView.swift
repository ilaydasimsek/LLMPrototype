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
            if viewModel.outputLoading {
                ProgressView()
            } else {
                Text(viewModel.output ?? "")
            }
            Spacer()
            Button("Take Screenshot and Analyze") {
                viewModel.takeAndAnalyzeScreenshot()
            }.disabled(!viewModel.aiModelReady || viewModel.outputLoading)
            Text("Pressing the button will take a screenshot after 5 seconds. You can change to another screen in the mean time to take a screenshot of the screen you want.")
        }
        .padding()
    }
}

#Preview {
    ScreenshotAnalyzerView(viewModel: ScreenshotAnalyzerViewModel())
}
