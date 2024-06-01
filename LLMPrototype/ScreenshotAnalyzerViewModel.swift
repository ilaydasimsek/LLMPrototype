import Foundation
import SwiftUI
import Foundation
import llmfarm_core
import Combine

class CountDownTimer: ObservableObject {
    
    @Published var countDown: Int
    @Published var timerRunning: Bool = false
    let completionCallback: () -> Void
    var timer: Timer?
    
    init(countDown: Int = 5, completionCallback: @escaping () -> Void) {
        self.countDown = countDown
        self.completionCallback = completionCallback
    }
    
    func startTimer() {
        timerRunning = true
        self.timer = Timer.scheduledTimer(timeInterval: 1,
                                          target: self,
                                          selector: #selector(onCountDownTick),
                                          userInfo: nil,
                                          repeats: true)
    }
    @objc
    func onCountDownTick() {
        if countDown <= 1 {
            timer?.invalidate()
            completionCallback()
            timerRunning = false
        } else {
            countDown -= 1
        }
    }
}

class ScreenshotAnalyzerViewModel: ObservableObject {
    @Published var aiModelReady: Bool = false
    @Published var outputLoading: Bool = false
    
    @Published var screenshotAnalysisResult: String = ""
    @Published var currentScreenShotURL: URL?
    @Published var countdownTimer: CountDownTimer?
    
    var countdownTimerCancellable: AnyCancellable? = nil

    var aiModel: AI? = nil
    
    init() {
        setupAiModal()
    }
    
    func takeAndAnalyzeScreenshot() {
        self.screenshotAnalysisResult = ""
        self.currentScreenShotURL = nil
        
        self.countdownTimer = CountDownTimer { [weak self] in
            guard let self = self, let screenshot = saveScreenshot() else {
                return
            }
            self.currentScreenShotURL = screenshot
            analyzeScreenshot(screenshot)
            countdownTimerCancellable?.cancel()
        }
        self.countdownTimerCancellable = self.countdownTimer?.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
        countdownTimer?.startTimer()
    }
    
    private func setupAiModal() {
        
        guard let modelPath = Bundle.main.url(forResource: "MobileVLM-3B-Q4_K_M", withExtension: "gguf")?.path() else {
            print("Could not load provided model")
            return
        }
        //load model
        let ai = AI(_modelPath: modelPath ,_chatName: "chat")
        var params:ModelAndContextParams = .default
        
        //set custom prompt format
        guard let clipModelPath = Bundle.main.url(forResource: "MobileVLM-3B-mmproj-f16", withExtension: "gguf")?.path() else {
            print("Could not load clip model")
            return
        }
        
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
        let maxOutputLength = 1000
        var total_output = 0
        
        func mainCallback(_ str: String, _ time: Double) -> Bool {
            total_output += str.count
            DispatchQueue.main.sync {
                if (self.outputLoading) {
                    self.outputLoading = false
                }
                self.screenshotAnalysisResult += str
            }
            if(total_output>maxOutputLength){
                return true
            }
            return false
        }
        
        outputLoading = true
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let input_text = "Describe what this computer screenshot shows"
            _ = self.aiModel?.model?.make_image_embed(screenshotUrl.path())
            let _ = try? self.aiModel?.model?.predict(input_text, mainCallback)
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
