// Shared/DesignSystem/Foundation/View+DSShadow.swift

import SwiftUI

extension View {
    /// 그림자 스타일 토큰을 적용하는 헬퍼.
    func dsShadow(_ style: DSShadowStyle) -> some View {
        shadow(
            color:  style.color,
            radius: style.radius,
            x:      style.x,
            y:      style.y
        )
    }
}
