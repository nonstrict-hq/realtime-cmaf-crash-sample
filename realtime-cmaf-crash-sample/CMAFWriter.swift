//
//  CMAFWriter.swift
//  realtime-cmaf-crash-sample
//
//  Created by Nonstrict on 13/03/2023.
//

import Foundation
import AVFoundation

/// AVAssetWriter that outputs CMAF compliant segments and receives its input in real time (from for example ScreenCaptureKit)
final class CMAFWriter {
    private let assetWriter: AVAssetWriter
    private let assetWriterInput: AVAssetWriterInput

    private let delegate = NoopDelegate()
    
    init(dimensions: CMVideoDimensions) {
        assetWriter = AVAssetWriter(contentType: .mpeg4Movie)
        assetWriter.outputFileTypeProfile = AVFileTypeProfile.mpeg4CMAFCompliant // Changing to `mpeg4AppleHLS` seems to workaround the issue
        assetWriter.shouldOptimizeForNetworkUse = true
        assetWriter.preferredOutputSegmentInterval = CMTime(seconds: 2, preferredTimescale: 1)
        assetWriter.initialSegmentStartTime = .zero
        assetWriter.delegate = delegate
        
        assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: dimensions.width,
            AVVideoHeightKey: dimensions.height,
        ])
        assetWriterInput.expectsMediaDataInRealTime = true // Disabling this seems to workaround the issue
        
        if assetWriter.canAdd(assetWriterInput) {
            assetWriter.add(assetWriterInput)
        } else {
            fatalError("Unable to add input to writer.")
        }
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
    }
    
    func append(_ sampleBuffer: CMSampleBuffer) {
        if assetWriterInput.isReadyForMoreMediaData {
            assetWriterInput.append(sampleBuffer)
        }

        if let assetWriterError = assetWriter.error {
            fatalError("Asset writer failed with error: \(assetWriterError)")
        }
    }
}

final class NoopDelegate: NSObject, AVAssetWriterDelegate {
    func assetWriter(_ writer: AVAssetWriter, didOutputSegmentData segmentData: Data, segmentType: AVAssetSegmentType, segmentReport: AVAssetSegmentReport?) {
        // No implementation needed to exercise the issue
        print("Got segment starting at \(segmentReport?.trackReports.first?.earliestPresentationTimeStamp.seconds ?? -1)")
    }
}
