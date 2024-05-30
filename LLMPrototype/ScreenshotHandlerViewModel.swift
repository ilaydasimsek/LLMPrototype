import Foundation
import SwiftUI

class ScreenshotHandlerViewModel: ObservableObject {
    
    private var timer: Timer?
        
    func startSavingScreenshots() {
        if let _ = timer {
            return
        }
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(saveScreenshot), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func stopSavingScreenshots() {
        timer?.invalidate()
        timer = nil
    }

    
    @objc
    func saveScreenshot() {
        let tempDirectoryURL = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)

        takeScreenshot(folderName: tempDirectoryURL.path())
    }

    private func takeScreenshot(folderName: String) {
        
        var displayCount: UInt32 = 0;
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        if (result != CGError.success) {
            print("error: \(result)")
            return
        }
        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
        
        if (result != CGError.success) {
            print("error: \(result)")
            return
        }
           
        for i in 1...displayCount {
            let unixTimestamp = createTimeStamp()
            let fileUrl = URL(fileURLWithPath: folderName + "\(unixTimestamp)" + "_" + "\(i)" + ".jpg", isDirectory: true)
            let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i-1)])!
            let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
            let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
            
            
            do {
                try jpegData.write(to: fileUrl, options: .atomic)
            }
            catch {print("error: \(error)")}
        }
    }

    private func createTimeStamp() -> Int32 {
        return Int32(Date().timeIntervalSince1970)
    }
}
