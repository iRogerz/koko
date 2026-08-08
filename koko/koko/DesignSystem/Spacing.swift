//
//  Spacing.swift
//  koko
//
//  間距 token，取自 `docs/design-spec.md` §3。
//  ViewController 內不得寫魔術數字（CLAUDE.md architecture rule 6）。
//

import CoreGraphics

enum Spacing {

    /// 4pt
    static let xs: CGFloat = 4

    /// 8pt
    static let s: CGFloat = 8

    /// 12pt
    static let m: CGFloat = 12

    /// 16pt
    static let l: CGFloat = 16
}
