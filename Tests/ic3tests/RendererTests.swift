//
//  File.swift
//  
//
//  Created by Jason Barrie Morley on 19/07/2023.
//

import Foundation

import XCTest
@testable import ic3

import Stencil

// TODO: Move this into a separate method.
struct TestContext: EvaluationContext {

    // TODO: Consider some form of typesafe subscripted object (think SQLite.swift)
    func evaluate(call: BoundFunctionCall) throws -> Any? {
        if let _ = try call.arguments(Method("jump")) {
            return "*boing*"
        } else if let argument = try call.arguments(Method("titlecase")
            .argument("string", type: String.self)) {
            return argument.toTitleCase()
        } else if let argument = try call.arguments(Method("echo")
            .argument("string", type: String.self)) {
            return argument
        } else if let arguments = try call.arguments(Method("prefix")
            .argument("str1", type: String.self)
            .argument("str2", type: String.self)) {
            return arguments.0 + arguments.1
        }
        throw InContextError.unknownFunction(call.signature)
    }

    func lookup(_ name: String) throws -> Any? {
        // TODO: Throw error
        return nil
    }

}

public func XCTAssertEqualAsync<T>(_ expression1: @autoclosure () async throws -> T,
                                   _ expression2: @autoclosure () async throws -> T,
                                   _ message: @autoclosure () -> String = "",
                                   file: StaticString = #filePath,
                                   line: UInt = #line) async where T : Equatable {
    do {
        let result1 = try await expression1()
        let result2 = try await expression2()
        XCTAssertEqual(result1, result2, file: file, line: line)
    } catch {
        XCTFail(message(), file: file, line: line)
    }
}

public func XCTAssertNotEqualAsync<T>(_ expression1: @autoclosure () async throws -> T,
                                      _ expression2: @autoclosure () async throws -> T,
                                      _ message: @autoclosure () -> String = "",
                                      file: StaticString = #filePath,
                                      line: UInt = #line) async where T : Equatable {
    do {
        let result1 = try await expression1()
        let result2 = try await expression2()
        XCTAssertNotEqual(result1, result2, file: file, line: line)
    } catch {
        XCTFail(message(), file: file, line: line)
    }
}

class RendererTests: XCTestCase {

    func render(_ template: String, context: [String: Any] = [:]) throws -> String {
        let environment = Environment(extensions: [Site.ext()])
        return try environment.renderTemplate(string: template, context: context)
    }

    func testSimple() throws {
        XCTAssertEqual(try render("Hello {{ name }}!", context: ["name": "Jason"]),
                       "Hello Jason!")
    }

    // At a guess, Sentcil is using `Mirror` to acheive this. That might be why it's not working for dynamic variables?
    func testProperty() throws {
        struct Person {
            var name = "Jason"
        }
        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
                       "Hello Jason!")
    }

    func testDynamicPropertyFails() throws {
        class Person {
            var name: String { "Jason" }
            init() { }
        }
        XCTAssertNotEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
                          "Hello Jason!")
    }

    // From testing, it seems like Swift dynamic properties don't work out of the box with Stencil. That would make
    // sense as I imagine it's using key-value coding which I believe only works with classes that inherit from
    // NSObject.
    func testObjCDynamicProperty() throws {
        @objc class Person: NSObject {
            @objc var name: String { "Jason" }
            override init() { super.init() }
        }
        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
                       "Hello Jason!")
    }

    func testDictionary() {
        let person = [
            "name": "Jason"
        ]
        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": person]),
                       "Hello Jason!")
    }

    // TODO: Check to see if Mirror returns functions and dynamic properties
    // TODO: Check function calls with parameters (probably not)
    // TODO: Test subcontexts as a repalcement for with?
    // TODO: Consider LiquidKit as an alternative

    func testDynamicMemberLookup() {
        class Person: DynamicMemberLookup {
            var name: String { "Jason" }
            subscript(dynamicMember member: String) -> Any? {
                print(member)
                switch member {
                case "name":
                    return name
                default:
                    return nil
                }
            }
        }
        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
                       "Hello Jason!")
    }

    // Similarly to dynamic properties, functions only seem to work with NSObjects and (presumably) key-value lookup,
    // though I guess Mirror might be way more capable in NSObject-land (something to check).
    func testFunction() {
        @objc class Person: NSObject {
            @objc func name() -> String {
                return "Jason"
            }
        }
        XCTAssertEqual(try render("Hello {{ person.name }}!", context: ["person": Person()]),
                       "Hello Jason!")
    }

    // TODO: Bug fix; should always push a context if it's empty at render time.

    func testSetString() {
        XCTAssertEqual(try render("{% set name = \"Jason\" %}Hello {{ name }}!", context: ["tick": "tock"]),
                       "Hello Jason!")
    }

    func testSetInt() {
        XCTAssertEqual(try render("{% set value = 42 %}The answer is {{ value }}!", context: ["tick": "tock"]),
                       "The answer is 42!")
    }

    func testSetDouble() {
        XCTAssertEqual(try render("{% set value = 3.14159 %}Pi = {{ value }}!", context: [:]),
                       "Pi = 3.14159!")
    }

    func testVariable() {
        XCTAssertEqual(try render("{% set value = tick %}tick = {{ value }}!", context: ["tick": "tock"]),
                       "tick = tock!")
    }

    // TODO: Support assigning with identifiers.

    func testFunctionCall() {
        XCTAssertEqual(try render("{% set value = object.titlecase(string: \"jason\") %}Hello {{ value }}!",
                                  context: ["object": TestContext()]),
                       "Hello Jason!")
    }

    // TODO: Test top-level context function _without_ faked up object.

    func testStringCount() {
        XCTAssertEqual(try render("{% set value = \"cheese\".count %}{{ value }}!",
                                  context: ["object": TestContext()]),
                       "6!")
    }

    func testEchoCallable() {
        XCTAssertEqual(try render("{% set value = object.echo(string: \"jason\") %}{{ value }}",
                                  context: ["object": TestContext()]),
                       "jason")
    }

    func testEchoCallableLookup() {
        XCTAssertEqual(try render("{% set value = object.echo(string: name) %}{{ value }}",
                                  context: ["object": TestContext(), "name": "jason"]),
                       "jason")
    }

    func testEchoCallableChain() {
        XCTAssertEqual(try render("{% set value = object.echo(string: object.echo(string: \"jason\")) %}{{ value }}",
                                  context: ["object": TestContext(), "name": "jason"]),
                       "jason")
    }

    func testMultipleArguments() {
        XCTAssertEqual(try render("{% set value = object.prefix(str1: \"abc\", str2: \"def\") %}{{ value }}",
                                  context: ["object": TestContext()]),
                       "abcdef")
    }

    func testContextWithCallableBlock() {
        let context = [
            "increment": CallableBlock(Method("increment")
                .argument("value", type: Int.self)) { value in
                    return value + 1
                }
        ]
        XCTAssertEqual(try render("{% set value = increment(value: 1) %}{{ value }}",
                                  context: context),
                       "2")
    }

    func testParseSet() throws {
        let operation = try SetOperation(string: "set value = utils.increment(value: 1)")
        let lookup = Executable(operand: nil, operation: .lookup("utils"))
        let call = FunctionCall(name: "increment", arguments: [NamedResultable(name: "value", result: .int(1))])
        let perform = Executable(operand: Resultable.executable(lookup), operation: .call(call))
        let expected = SetOperation(identifier: "value", result: .executable(perform))
        XCTAssertEqual(operation, expected)
    }

    func testContextWithDictionaryContainingCallableBlock() {
        let context = [
            "utils": [
                "increment": CallableBlock(Method("increment").argument("value", type: Int.self)) { value in
                    return value + 1
                }
            ]
        ]
        XCTAssertEqual(try render("{% set value = utils.increment(value: 1) %}{{ value }}",
                                  context: context),
                       "2")
    }

    func testArrayAssignment() {
        XCTAssertEqual(try render("{% set values = [1, 2] %}{% for value in values %}{{ value }},{% endfor %}",
                                  context: ["object": TestContext()]),
                       "1,2,")
    }

    func testArrayExtendAssignment() {
        XCTAssertEqual(try render("{% set values = [1, 2] %}{% set values = values.extending(values: [3, 4]) %}{% for value in values %}{{ value }},{% endfor %}",
                                  context: ["object": TestContext()]),
                       "1,2,3,4,")
    }

    func testArrayOutput() {
        XCTAssertEqual(try render("{% set values = [1, 2] %}{% if values %}{{ values }}{% endif %}",
                                  context: ["object": TestContext()]),
                       "[1, 2]")
    }

    func testUpdate() {
        XCTAssertEqual(try render("{% set name = \"bob\" %}{% update name = \"alice\" %}{{ name }}"),
                       "alice")
    }

    func testNestedDictionaryFromJSON() throws {
        let dictionary = "{\"one\": {\"two\": \"three\"}}"
        let json = dictionary.data(using: .utf8)
        let context = try JSONSerialization.jsonObject(with: json!) as! [String: Any]
        XCTAssertEqual(try render("{% set name = \"bob\" %}{% update name = \"alice\" %}{{ one.two }}", context: context),
                       "three")
    }

    // These tests are just here to remind me that, out of the box, calculations fail silently in Stencil.
    func testCalculationsFailSilently() throws {
        XCTAssertEqual(try render("{{ 10 }}", context: [:]), "10")
        XCTAssertNotEqual(try render("{{ 10 + 1 }}", context: [:]), "11")
    }

    func testCalculationsUsingSet() throws {

        // add
        XCTAssertEqual(try render("{% set result = add(lhs: 10, rhs: 1) %}{{ result }}", context: [:]),
                       "11")
        XCTAssertEqual(try render("{% set result = add(lhs: 10.0, rhs: 1) %}{{ result }}", context: [:]),
                       "11.0")
        XCTAssertEqual(try render("{% set result = add(lhs: 10, rhs: 2.0) %}{{ result }}", context: [:]),
                       "12.0")
        XCTAssertEqual(try render("{% set result = add(lhs: 10.0, rhs: 3.0) %}{{ result }}", context: [:]),
                       "13.0")

        // div
        XCTAssertEqual(try render("{% set result = div(lhs: 5, rhs: 2) %}{{ result }}", context: [:]),
                       "2")
        XCTAssertEqual(try render("{% set result = div(lhs: 5.0, rhs: 2) %}{{ result }}", context: [:]),
                       "2.5")
        XCTAssertEqual(try render("{% set result = div(lhs: 5, rhs: 2.0) %}{{ result }}", context: [:]),
                       "2.5")
        XCTAssertEqual(try render("{% set result = div(lhs: 5.0, rhs: 2.0) %}{{ result }}", context: [:]),
                       "2.5")

        // mul
        XCTAssertEqual(try render("{% set result = mul(lhs: 2, rhs: 3) %}{{ result }}", context: [:]),
                       "6")
        XCTAssertEqual(try render("{% set result = mul(lhs: 5.0, rhs: 9) %}{{ result }}", context: [:]),
                       "45.0")
        XCTAssertEqual(try render("{% set result = mul(lhs: 3, rhs: 6.0) %}{{ result }}", context: [:]),
                       "18.0")
        XCTAssertEqual(try render("{% set result = mul(lhs: 5.0, rhs: 2.0) %}{{ result }}", context: [:]),
                       "10.0")
    }

    // TODO: Update to use set.
//    func testIncludeContext() async throws {
//        try await withTemporaryDirectory { templatesURL in
//            let template = "{{ secondary }}"
//            print(templatesURL)
//            let templateURL = templatesURL.appendingPathComponent("template.html")
//            try template.write(to: templateURL, atomically: true, encoding: .utf8)
//            let loader = FileSystemLoader(paths: [.init(templatesURL.path)])
//            let environment = Environment(loader: loader, extensions: [Site.ext()])
//            let result = try await environment.renderTemplate(string: "{% for page in pages %}{% include \"template.html\" secondary %}{% endfor %}",
//                                                              context: ["pages": ["title": "title", "content": "content"], "secondary": ["one": "one_value"]])
//            XCTAssertEqual(result, "cheese")
//        }
//    }

}

// TODO: Move this out.
func withTemporaryDirectory(perform: @escaping (URL) async throws -> Void) async throws {
    let fileManager = FileManager.default
    let url = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    defer {
        do {
            try fileManager.removeItem(at: url)
        } catch {
            print("Failed to delete temporary directory at '\(url.path)' with error \(error).")
            exit(EXIT_FAILURE)
        }
    }
    try await perform(url)
}
