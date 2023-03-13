//
//  SampleBufferSource.swift
//  realtime-cmaf-crash-sample
//
//  Created by Nonstrict on 13/03/2023.
//

import Foundation
import AppKit
import AVFoundation

/// Generates CMSampleBuffers from an image at 60 FPS, but 5% of the time deliver the sample.
/// This simulates what ScreenCaptureKit does when there aren't changes on screen all the time.
final class SampleBufferSource {
    var dimensions: CMVideoDimensions { formatDescription.dimensions }
    
    private let still: CVPixelBuffer
    private let formatDescription: CMVideoFormatDescription
    private var presentationTimeStamp = CMTime(value: 0, timescale: 60)
    
    private let queue = DispatchQueue(label: "SampleBufferSource")
    private let timer: DispatchSourceTimer
    
    init() {
        self.still = NSImage(named: "still")!.pixelBuffer()!
        self.formatDescription = try! CMVideoFormatDescription(imageBuffer: still)
        
        self.timer = DispatchSource.makeTimerSource(flags: [.strict], queue: queue)
    }
    
    func start(handler: @escaping (CMSampleBuffer) -> Void) {
        timer.setEventHandler {
            if let sample = self.nextSampleBuffer() {
                handler(sample)
            }
        }
        timer.schedule(deadline: .now(), repeating: .nanoseconds(16_666_666)) // 60 FPS
        timer.resume()
    }

    private func nextSampleBuffer() -> CMSampleBuffer? {
        defer { presentationTimeStamp.value += 1 }
        
        // We don't always produce a sample, just like ScreenCaptureKit doesn't produce samples if nothing changes on screen
        guard (0..<100).randomElement()! <= 95 else { return nil }

        let timingInfo = CMSampleTimingInfo(duration: .indefinite,
                                            presentationTimeStamp: presentationTimeStamp,
                                            decodeTimeStamp: .invalid)
        return try! CMSampleBuffer(imageBuffer: still, formatDescription: formatDescription, sampleTiming: timingInfo)
    }
}

private extension NSImage {
    func pixelBuffer() -> CVPixelBuffer? {
        let width = size.width
        let height = size.height
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        
        guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(resultPixelBuffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {return nil}
        
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext
        draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()

        CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return resultPixelBuffer
    }
}
