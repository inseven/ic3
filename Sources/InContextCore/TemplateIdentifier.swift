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

import SQLite
import UniformTypeIdentifiers

class TemplateIdentifier: RawRepresentable, Equatable, Codable, Hashable, CustomStringConvertible {

    let name: String

    var rawValue: String {
        return name
    }

    var description: String {
        return rawValue
    }

    init(_ name: String) {
        self.name = name
    }

    required init?(rawValue: String) {
        self.name = rawValue
    }

}

extension TemplateIdentifier: Fingerprintable {

    func combine(into fingerprint: inout Fingerprint) throws {
        try fingerprint.update(rawValue)
    }

}

extension TemplateIdentifier {

    var pathExtension: String {
        return URL(filePath: name).pathExtension
    }

    var type: UTType? {
        return UTType(filenameExtension: pathExtension)
    }

}

extension TemplateIdentifier: Value {

    typealias Datatype = String

    static var declaredDatatype: String {
        "text"
    }

    static func fromDatatypeValue(_ datatypeValue: String) -> TemplateIdentifier {
        return .init(rawValue: datatypeValue)!
    }

    var datatypeValue: String {
        return rawValue
    }

}