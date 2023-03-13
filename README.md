# CMAF Compliant Writing Real Time Sample

Minimal sample to demonstrate writing out CMAF compliant segments from a real source fails with an error on Intel macs on Ventura.

The error is in the `AVFoundationErrorDomain` with code `-11800`, containing an underlying error in the `NSOSStatusErrorDomain` with code `-16364`.

## Reproduction conditions

- The `AVAssetWriter` must be configured with `outputFileTypeProfile` set to `.mpeg4CMAFCompliant`.
- The `AVAssetWriterInput` added to the writer must have `expectsMediaDataInRealTime` set to `true`.
- Samples must be appended to the input either:
  - At an variable rate, for example because no new sample is generated when there is no change at the souce (like ScreenCaptureKit does).
  - Frames are delivered significantly faster than 60 FPS.
- The application must run on an Intel mac, Apple Silicon macs are not affected.

## Demonstrating the issue

This repository contains a sample app demonstrating the issue:
- Open `realtime-cmaf-crash-sample.xcodeproj` in Xcode 14.2 or newer on an Intel mac
- Build & run the app
- Hit the "Start" button

After about 5 segments are delivered to the delegate the app will crash.

## Workaround

- On the `AVAssetWriter` change `outputFileTypeProfile` to `mpeg4AppleHLS`.
  - Note that this will either produce a different format output.
- On the `AVAssetWriterInput` set `expectsMediaDataInRealTime` to `false`.
  - Might have unexpected side effects dropping frames because `isReadyForMoreMediaData` might become inaccurate.

## Authors

[Nonstrict B.V.](https://nonstrict.eu), [Mathijs Kadijk](https://github.com/mac-cain13) & [Tom Lokhorst](https://github.com/tomlokhorst), released under [MIT License](LICENSE.md).
