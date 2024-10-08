//
//  SlimRectangle.swift
//  Confetti_SwiftUI
//
//  Created by Arturo on 10/6/24.
//

import SwiftUI

public struct SlimRectangle: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: 4*rect.maxY/5))
        path.addLine(to: CGPoint(x: rect.maxX, y: 4*rect.maxY/5))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        return path
    }
}

struct SlimRectangle_Previews: PreviewProvider {
    static var previews: some View {
        SlimRectangle()
    }
}
