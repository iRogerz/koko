//
//  UIImage+Recolor.swift
//  koko
//
//  把素材裡某一個平塗顏色換掉，其餘（含透明區）原樣保留。
//
//  **為什麼需要它**：Zeplin 只匯出中央 KO 按鈕的 Off（灰）版 `icTabbarHomeOff`，
//  沒有選中版。而 `withTintColor` / template rendering **做不到**這件事 ——
//  它們是用 alpha 當遮罩，會把整個不透明區域壓成同一色，
//  KO 素材的橫條、圓底、字會一起變成一團粉紅色塊。
//
//  這張素材剛好只有三個平塗色且互不重疊（`#FFFFFF` 橫條、`#F5F5F5` 圓、`#999999` KO 字），
//  所以逐像素替換是安全的。
//
//  ⚠️ **這是權宜之計。** 正解是請設計師從 Zeplin 匯出 On 版素材
//  （命名慣例上應該叫 `icTabbarHomeOn`，就像已經有的 `icTabbarFriendsOn`）。
//  拿到之後把這個檔案連同呼叫端一起刪掉。
//

import UIKit

extension UIImage {

    /// 把接近 `source` 的像素換成 `target`。透明區與其他顏色不動。
    ///
    /// - Parameter tolerance: 每個色版可接受的差距（0～1）。素材是平塗色，
    ///   預設值只是用來吃掉邊緣抗鋸齒，不需要調大。
    func replacingColor(
        _ source: UIColor,
        with target: UIColor,
        tolerance: CGFloat = 0.1
    ) -> UIImage {
        // 向量 PDF 先以螢幕倍率點陣化，才有像素可以換。
        let flattened = UIGraphicsImageRenderer(size: size).image { _ in
            draw(at: .zero)
        }

        guard
            let cgImage = flattened.cgImage,
            let source = source.rgbaComponents,
            let target = target.rgbaComponents
        else {
            return self
        }

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
            return self
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let limit = tolerance * 255

        for index in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = CGFloat(pixels[index + 3])
            guard alpha > 0 else { continue }

            // bitmap 是 premultiplied，比對前要把 source 也乘上同樣的 alpha，
            // 這樣邊緣的抗鋸齒像素才不會被誤判成「不是這個顏色」。
            let scale = alpha / 255
            guard
                abs(CGFloat(pixels[index]) - source.red * 255 * scale) <= limit,
                abs(CGFloat(pixels[index + 1]) - source.green * 255 * scale) <= limit,
                abs(CGFloat(pixels[index + 2]) - source.blue * 255 * scale) <= limit
            else {
                continue
            }

            pixels[index] = UInt8((target.red * 255 * scale).rounded())
            pixels[index + 1] = UInt8((target.green * 255 * scale).rounded())
            pixels[index + 2] = UInt8((target.blue * 255 * scale).rounded())
        }

        guard let recolored = context.makeImage() else { return self }

        return UIImage(
            cgImage: recolored,
            scale: flattened.scale,
            orientation: flattened.imageOrientation
        )
    }
}

private extension UIColor {

    struct RGBA {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
    }

    var rgbaComponents: RGBA? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return RGBA(red: red, green: green, blue: blue, alpha: alpha)
    }
}
