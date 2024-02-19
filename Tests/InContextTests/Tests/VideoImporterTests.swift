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

import XCTest
@testable import InContextCore

/* class VideoImporterTests: ContentTestCase {

    func testExtractTitle() async throws {

        try await withTemporaryDirectory { temporaryDirectoryURL in

            let videoURL = try self.bundle.throwingURL(forResource: "2022-05-31-17-55-03-royal-wave",
                                                       withExtension: "mov")
            let video = try File(url: videoURL)

            let importer = VideoImporter()
            let result = try await importer.process(file: video,
                                                    settings: VideoImporter.Settings(defaultCategory: "snapshots",
                                                                                     titleFromFilename: false,
                                                                                     defaultTemplate: TemplateIdentifier("video.html"),
                                                                                     inlineTemplate: TemplateIdentifier("video.html")),
                                                    outputURL: temporaryDirectoryURL)
            XCTAssertEqual(result.document?.title, "Royal Wave")
        }

//        // TODO: It shouldn't be necessary to pass the site into the importer.
//        let file = try defaultSourceDirectory.copy(try bundle.throwingURL(forResource: "IMG_0581", withExtension: "jpeg"),
//                                                   to: "image.jpeg",
//                                                   location: .content)
//        let importer = ImageImporter()
//        let settings =  ImageImporter.Settings(defaultCategory: "photos",
//                                               titleFromFilename: false,
//                                               defaultTemplate: TemplateIdentifier("photo.html"),
//                                               inlineTemplate: TemplateIdentifier("image.html"))
//        let result = try await importer.process(site: defaultSourceDirectory.site,
//                                                file: file,
//                                                settings: settings,
//                                                outputURL: defaultSourceDirectory.site.filesURL)
//        XCTAssertNotNil(result.document)
//        XCTAssertEqual(result.document?.title, "Hallgrímskirkja Church")
    }

}
*/