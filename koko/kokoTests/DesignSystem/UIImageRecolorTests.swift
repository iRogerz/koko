//
//  UIImageRecolorTests.swift
//  kokoTests
//
//  `UIImage.replacingColor(_:with:)` 的行為防線。
//
//  它存在的唯一理由是「Zeplin 沒給 KO 的選中版素材」，
//  而它必須做到 `withTintColor` 做不到的事：**只換一個顏色**，
//  不要把整個不透明區域壓成同一色。這裡就釘這兩件事。
//

import XCTest
@testable import koko

@MainActor
final class UIImageRecolorTests: XCTestCase {

    private let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    private let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
    private let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)

    /// 左半紅、右半藍：只有紅色該被換掉，藍色必須原封不動。
    /// 這正是 KO 素材的情境（換 KO 字、保留圓底）。
    func test_replacingColor_changesOnlyTheMatchingColor() async throws {
        let image = makeTwoToneImage()

        let recolored = image.replacingColor(red, with: green)

        assertPixel(in: recolored, at: CGPoint(x: 0.25, y: 0.5), equals: green, "紅色那半沒被換成綠色")
        assertPixel(in: recolored, at: CGPoint(x: 0.75, y: 0.5), equals: blue, "藍色那半被動到了")
    }

    /// 透明區必須維持透明 —— 被填色的話 KO 按鈕會變成一個方塊。
    func test_replacingColor_keepsTransparentPixelsTransparent() async throws {
        let image = makeTwoToneImage(rightHalfTransparent: true)

        let recolored = image.replacingColor(red, with: green)

        let alpha = try XCTUnwrap(alphaComponent(in: recolored, at: CGPoint(x: 0.75, y: 0.5)))
        XCTAssertEqual(alpha, 0, accuracy: 1, "透明區被填色了")
    }

    /// 對照組：`withTintColor` 會把紅藍兩半一起壓成同一色。
    /// 這條說明為什麼不能用它取代 `replacingColor`。
    func test_tintColor_flattensEveryOpaqueColor_soItCannotBeUsedInstead() async throws {
        let image = makeTwoToneImage()

        let tinted = image.withTintColor(green, renderingMode: .alwaysOriginal)
        let rendered = UIGraphicsImageRenderer(size: tinted.size).image { _ in
            tinted.draw(at: .zero)
        }

        assertPixel(in: rendered, at: CGPoint(x: 0.25, y: 0.5), equals: green)
        assertPixel(
            in: rendered,
            at: CGPoint(x: 0.75, y: 0.5),
            equals: green,
            "若這裡不再是綠色，代表 tintColor 行為變了，可以考慮拿掉 replacingColor"
        )
    }

    // MARK: - Helpers

    private func makeTwoToneImage(rightHalfTransparent: Bool = false) -> UIImage {
        let size = CGSize(width: 20, height: 10)
        return UIGraphicsImageRenderer(size: size).image { context in
            red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))

            guard !rightHalfTransparent else { return }
            blue.setFill()
            context.fill(CGRect(x: 10, y: 0, width: 10, height: 10))
        }
    }

    /// `at` 是 0～1 的相對位置，避免依賴螢幕倍率。
    ///
    /// 整張解到 buffer 再取值，不玩偏移繪製的花招。取樣點都在垂直中線上，
    /// 所以 bitmap 是否上下顛倒不影響結果。
    private func rgba(in image: UIImage, at point: CGPoint) -> [CGFloat]? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let x = min(Int(CGFloat(width) * point.x), width - 1)
        let y = min(Int(CGFloat(height) * point.y), height - 1)
        let offset = y * bytesPerRow + x * 4

        return (0..<4).map { CGFloat(pixels[offset + $0]) }
    }

    private func alphaComponent(in image: UIImage, at point: CGPoint) -> CGFloat? {
        rgba(in: image, at: point)?[3]
    }

    private func assertPixel(
        in image: UIImage,
        at point: CGPoint,
        equals color: UIColor,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let actual = rgba(in: image, at: point) else {
            return XCTFail("讀不到像素 \(point)", file: file, line: line)
        }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(actual[0], red * 255, accuracy: 8, message, file: file, line: line)
        XCTAssertEqual(actual[1], green * 255, accuracy: 8, message, file: file, line: line)
        XCTAssertEqual(actual[2], blue * 255, accuracy: 8, message, file: file, line: line)
    }
}
