// MIT License
//
// Copyright (c) 2023 Jason Barrie Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import AVFoundation
import Foundation

class VideoImporter: Importer {

    let identifier = "app.incontext.importer.video"
    let legacyIdentifier = "import_video"
    let version = 5

    func process(site: Site, file: File, settings: [AnyHashable: Any]) async throws -> ImporterResult {
        let video = AVAsset(url: file.url)
        let outputURL = site.outputURL(relativePath: file.url.deletingPathExtension().relativePath + ".mov")
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        await export(video: video,
                     withPreset: AVAssetExportPresetHighestQuality,
                     toFileType: .mov,
                     atURL: outputURL)

//        https://img.ly/blog/working-with-large-video-and-image-files-on-ios-with-swift/#resizingavideo
//        let newAsset = AVAsset(url:Bundle.main.url(forResource: "jumping-man", withExtension: "mov")!) //1
//        var newSize = <some size that you've calculated> //2
//        let resizeComposition = AVMutableVideoComposition(asset: newAsset, applyingCIFiltersWithHandler: { request in
//          let filter = CIFilter(name: "CILanczosScaleTransform") //3
//          filter?.setValue(request.sourceImage, forKey: kCIInputImageKey)
//          filter?.setValue(<some scale factor>, forKey: kCIInputScaleKey) //4
//          let resultImage = filter?.outputImage
//          request.finish(with: resultImage, context: nil)
//        })
//        resizeComposition.renderSize = newSize //5

        return ImporterResult(assets: [Asset(fileURL: outputURL)])
    }

    // https://developer.apple.com/documentation/avfoundation/media_reading_and_writing/exporting_video_to_alternative_formats
    func export(video: AVAsset,
                withPreset preset: String = AVAssetExportPresetHighestQuality,
                toFileType outputFileType: AVFileType = .mov,
                atURL outputURL: URL) async {

        // Check the compatibility of the preset to export the video to the output file type.
        guard await AVAssetExportSession.compatibility(ofExportPreset: preset,
                                                       with: video,
                                                       outputFileType: outputFileType) else {
            // TODO: Fail!
            print("The preset can't export the video to the output file type.")
            return
        }

        // Create and configure the export session.
        guard let exportSession = AVAssetExportSession(asset: video,
                                                       presetName: preset) else {
            // TODO: Fail!
            print("Failed to create export session.")
            return
        }
        exportSession.outputFileType = outputFileType
        exportSession.outputURL = outputURL

        // Convert the video to the output file type and export it to the output URL.
        await exportSession.export()
    }

}