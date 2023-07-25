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

import Foundation
import ImageIO

class ImageImporter: Importer {

    let identifier = "app.incontext.importer.image"
    let legacyIdentifier = "import_photo"
    let version = 4

    func process(site: Site, file: File, settings: [AnyHashable: Any]) async throws -> ImporterResult {

        let fileURL = file.url

        let resourceURL = URL(filePath: fileURL.relevantRelativePath, relativeTo: site.filesURL)  // TODO: Make this a utiltiy and test it
        try FileManager.default.createDirectory(at: resourceURL, withIntermediateDirectories: true)

        // Load the original image.
        guard let image = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            throw InContextError.unknown
        }

        // TODO: Extract some of this data into the document.
        _ = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [String: Any]

        var assets: [Asset] = []

        // Perform the transforms.
        var transformMetadata: [String: [[String: Any]]] = [:]
        for transform in site.transforms {

            let options = [kCGImageSourceCreateThumbnailWithTransform: kCFBooleanTrue,
                       kCGImageSourceCreateThumbnailFromImageIfAbsent: kCFBooleanTrue,
                                  kCGImageSourceThumbnailMaxPixelSize: transform.width as NSNumber] as CFDictionary

            let destinationFilename = transform.basename + "." + (transform.format.preferredFilenameExtension ?? "")
            let destinationURL = resourceURL.appending(component: destinationFilename)

            // TODO: Doesn't work with SVG.
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(image, 0, options)!
            guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL,
                                                                    transform.format.identifier as CFString,
                                                                    1,
                                                                    nil) else {
                throw InContextError.unknown
            }
            CGImageDestinationAddImage(destination, thumbnail, nil)
            CGImageDestinationFinalize(destination)  // TODO: Handle error here?
            assets.append(Asset(fileURL: destinationURL as URL))

//            let availableRect = AVFoundation.AVMakeRect(aspectRatio: image.size, insideRect: .init(origin: .zero, size: maxSize))
//            let targetSize = availableRect.size

            let details = [
                "width": 100,
                "height": 100,
                "filename": "cheese",
                "url": destinationURL.relativePath.ensureLeadingSlash(),
            ] as [String: Any]

            for setName in transform.sets {
                transformMetadata[setName] = (transformMetadata[setName] ?? []) + [details]
            }
        }

        // Flatten the transform metadata to promote categories with single entires to top-level dictionaries.
        // TODO: This is legacy behaviour from InContext 2 and we should probably reconsider whether it makes sense
        let transformDetails = transformMetadata
            .compactMap { key, value -> (String, Any)? in
                guard !value.isEmpty else {
                    return nil
                }
                if value.count == 1 {
                    return (key, value[0])
                }
                return (key, value)
            }
            .reduce(into: [String: Any]()) { partialResult, element in
                partialResult[element.0] = element.1
            }

        let details = fileURL.basenameDetails()

        let document = Document(url: fileURL.siteURL,
                                parent: fileURL.parentURL,
                                type: "",
                                date: details.date,
                                metadata: transformDetails,
                                contents: "",
                                mtime: file.contentModificationDate,
                                template: "photo.html")
        return ImporterResult(documents: [document], assets: assets)
    }

}
