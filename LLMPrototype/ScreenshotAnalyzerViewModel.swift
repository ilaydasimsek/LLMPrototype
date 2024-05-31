import Foundation
import SwiftUI
import Foundation
import llmfarm_core

class ScreenshotAnalyzerViewModel: ObservableObject {
    @Published var aiModelReady: Bool = false
    @Published var currentScreenShotURL: URL?
    @Published var loading: Bool = false
    @Published var output: String? = nil
    
    var aiModel: AI? = nil
    
    init() {
        setupAiModal()
    }

    func takeAndAnalyzeScreenshot() {
        guard let screenshot = saveScreenshot() else {
            return
        }
        self.currentScreenShotURL = screenshot
        analyzeScreenshot(screenshot)
    }
    
    private func setupAiModal() {

        let modelPath = Bundle.main.url(forResource: "ggml-model-q4_k", withExtension: "gguf")!.path()
        //load model
        let ai = AI(_modelPath: modelPath ,_chatName: "chat")
        var params:ModelAndContextParams = .default

        //set custom prompt format
        let clipModelPath = Bundle.main.url(forResource: "mmproj-model-f16", withExtension: "gguf")!.path()
        params.clip_model = clipModelPath
        params.promptFormat = .Custom
        params.custom_prompt_format = """
        SYSTEM: You are a helpful, respectful and honest assistant.
        USER: {prompt}
        ASSISTANT:
        """

        ai.initModel(ModelInference.LLama_mm, contextParams:params)
        ai.model?.modelLoadCompleteCallback = { result in
            self.aiModelReady = true
          
        }
        ai.loadModel()
        self.aiModel = ai
    }


    private func analyzeScreenshot(_ screenshotUrl: URL) {
        let maxOutputLength = 256
        var total_output = 0

        func mainCallback(_ str: String, _ time: Double) -> Bool {
            total_output += str.count
            if(total_output>maxOutputLength){
                return true
            }
            return false
        }
        
        loading = true
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let input_text = "Describe what this computer screenshot shows"
            _ = self.aiModel?.model?.make_image_embed("/Users/ilaydasimsek/Library/Containers/com.ilaydasimsek.LLMPrototype/Data/tmp/1717090088_1.jpg")
            let output = try? self.aiModel?.model?.predict(input_text, mainCallback)
            DispatchQueue.main.async {
                self.loading = false
                self.output = output
            }
        }
    }

    private func saveScreenshot() -> URL? {
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)

        return takeScreenshot(folderName: tempDirectoryURL.path())
    }

    private func takeScreenshot(folderName: String) -> URL? {
        
        var displayCount: UInt32 = 0;
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        var fileUrls: [URL] = []
        if (result != CGError.success) {
            print("error: \(result)")
            return nil
        }
        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
        
        if (result != CGError.success) {
            print("error: \(result)")
            return nil
        }
           
        for i in 1...displayCount {
            let unixTimestamp = createTimeStamp()
            let fileUrl = URL(fileURLWithPath: folderName + "\(unixTimestamp)" + "_" + "\(i)" + ".jpg", isDirectory: true)
            let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i-1)])!
            let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
            let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
            
            
            do {
                try jpegData.write(to: fileUrl, options: .atomic)
                fileUrls.append(fileUrl)
            }
            catch {
                print("error: \(error)")
                return nil
            }
        }
        return fileUrls.first
    }

    private func createTimeStamp() -> Int32 {
        return Int32(Date().timeIntervalSince1970)
    }
}
