//
//  XCTestAsyncHelpers.swift
//  kokoTests
//
//  XCTest 內建的 XCTAssertThrowsError 只吃同步 autoclosure，
//  async 版本要自己補。
//

import XCTest

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail(
            message.isEmpty ? "預期會 throw，但順利回傳了" : message,
            file: file,
            line: line
        )
    } catch {
        errorHandler(error)
    }
}
