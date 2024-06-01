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
                Text(viewModel.screenshotAnalysisResult)
            }
            Spacer()
            if let timer = viewModel.countdownTimer, timer.timerRunning == true {
                Text(String(timer.countDown))
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity)
                    
            } else {
                Button("Take Screenshot and Analyze") {
                    viewModel.takeAndAnalyzeScreenshot()
                }.disabled(!viewModel.aiModelReady || viewModel.outputLoading)
            }
           
        }
        .padding()
    }
}

#Preview {
    ScreenshotAnalyzerView(viewModel: ScreenshotAnalyzerViewModel())
}
