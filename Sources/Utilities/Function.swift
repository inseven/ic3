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

struct Function: EvaluationContext, Callable {

    static func checkLength<T>(_ array: [T], length: Int) throws {
        guard array.count == length else {
            throw CallableError.incorrectArguments
        }
    }

    let _call: (ArgumentProvider) throws -> Any?

    func call(with provider: ArgumentProvider) throws -> Any? {
        return try _call(provider)
    }

    func lookup(_ name: String) throws -> Any? {
        throw InContextError.unknownSymbol(name)
    }

}

extension Function {

    init<Result>(perform: @escaping () throws -> Result) {
        self._call = { provider in
            try provider.withArguments { arguments in
                try Self.checkLength(arguments, length: 0)
                return try perform()
            }
        }
    }

    init<Arg1, Result>(perform: @escaping (Arg1) throws -> Result) {
        self._call = { provider in
            return try provider.withArguments { arguments in
                try Self.checkLength(arguments, length: 1)
                guard let arg1 = arguments[0] as? Arg1 else {
                    throw CallableError.incorectType
                }
                return try perform(arg1)
            }
        }
    }

    init<Arg1, Arg2, Result>(perform: @escaping (Arg1, Arg2) throws -> Result) {
        self._call = { provider in
            return try provider.withArguments { arguments in
                try Self.checkLength(arguments, length: 2)
                guard let arg1 = arguments[0] as? Arg1,
                      let arg2 = arguments[1] as? Arg2
                else {
                    throw CallableError.incorectType
                }
                return try perform(arg1, arg2)
            }
        }
    }

}

func example() throws -> Any? {

    let proxy: [String: Any] = [
        "title": Function {
            return "Hello, World!"
        },
        "print": Function { (string: String) in
            print("Hello, \(string)!")
        }
    ]

    // Dispatch.
    let name = "print"
    let stack = [
        "Tom"
    ]

    guard let symbol = proxy[name] else {
        throw InContextError.unknownSymbol(name)
    }
    if let callable = symbol as? Function {
        return try callable.call(with: stack)
    } else {
        return symbol
    }

}