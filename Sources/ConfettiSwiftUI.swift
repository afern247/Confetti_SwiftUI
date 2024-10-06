//
//  ConfettiView.swift
//  Confetti_SwiftUI
//
//  Created by Arturo on 10/6/24.
//

import SwiftUI

public enum ConfettiType: CaseIterable, Hashable {
    public enum Shape {
        case circle
        case triangle
        case square
        case slimRectangle
        case roundedCross
    }
    
    case shape(Shape)
    case text(String)
    case sfSymbol(symbolName: String)
    case image(String)
    
    public var view: AnyView {
        switch self {
        case .shape(.square):
            AnyView(Rectangle())
        case .shape(.triangle):
            AnyView(Triangle())
        case .shape(.slimRectangle):
            AnyView(SlimRectangle())
        case .shape(.roundedCross):
            AnyView(RoundedCross())
        case let .text(text):
            AnyView(Text(text))
        case .sfSymbol(let symbolName):
            AnyView(Image(systemName: symbolName))
        case .image(let image):
            AnyView(Image(image).resizable())
        default:
            AnyView(Circle())
        }
    }
    
    public static var allCases: [ConfettiType] {
        [.shape(.circle), .shape(.triangle), .shape(.square), .shape(.slimRectangle), .shape(.roundedCross)]
    }
}

public struct ConfettiCannon: View {
    @Binding var counter: Int
    @StateObject private var confettiConfig: ConfettiConfig
    
    @State var animate: [Bool] = []
    @State var finishedAnimationCounter = 0
    @State var firstAppear = false
    @State var error = ""
    
    /// renders configurable confetti animaiton
    /// - Parameters:
    ///   - counter: on any change of this variable the animation is run
    ///   - num: amount of confettis
    ///   - colors: list of colors that is applied to the default shapes
    ///   - confettiSize: size that confettis and emojis are scaled to
    ///   - rainHeight: vertical distance that confettis pass
    ///   - fadesOut: reduce opacity towards the end of the animation
    ///   - opacity: maximum opacity that is reached during the animation
    ///   - openingAngle: boundary that defines the opening angle in degrees
    ///   - closingAngle: boundary that defines the closing angle in degrees
    ///   - radius: explosion radius
    ///   - repetitions: number of repetitions of the explosion
    ///   - repetitionInterval: duration between the repetitions
    public init(counter: Binding<Int>,
                num: Int = 20,
                confettis: [ConfettiType] = ConfettiType.allCases,
                colors: [Color] = [.blue, .red, .green, .yellow, .pink, .purple, .orange],
                confettiSize: CGFloat = 10.0,
                rainHeight: CGFloat = 600.0,
                fadesOut: Bool = true,
                opacity: Double = 1.0,
                openingAngle: Angle = .degrees(60),
                closingAngle: Angle = .degrees(120),
                radius: CGFloat = 300,
                repetitions: Int = 0,
                repetitionInterval: Double = 1.0) {
        self._counter = counter
        var shapes = [AnyView]()
        
        for confetti in confettis {
            for color in colors {
                switch confetti {
                case .shape(_):
                    shapes.append(AnyView(confetti.view.foregroundColor(color).frame(width: confettiSize, height: confettiSize, alignment: .center)))
                case .image(_):
                    shapes.append(AnyView(confetti.view.frame(maxWidth: confettiSize, maxHeight: confettiSize)))
                default:
                    shapes.append(AnyView(confetti.view.foregroundColor(color).font(.system(size: confettiSize))))
                }
            }
        }
        
        _confettiConfig = StateObject(wrappedValue: ConfettiConfig(
            num: num,
            shapes: shapes,
            colors: colors,
            confettiSize: confettiSize,
            rainHeight: rainHeight,
            fadesOut: fadesOut,
            opacity: opacity,
            openingAngle: openingAngle,
            closingAngle: closingAngle,
            radius: radius,
            repetitions: repetitions,
            repetitionInterval: repetitionInterval
        ))
    }
    
    public var body: some View {
        ZStack {
            ForEach(finishedAnimationCounter..<animate.count, id: \.self) { i in
                ConfettiContainer(
                    finishedAnimationCounter: $finishedAnimationCounter,
                    confettiConfig: confettiConfig
                )
            }
        }
        .onAppear {
            firstAppear = true
        }
        .onChange(of: counter) { _, value in
            if firstAppear {
                for i in 0...confettiConfig.repetitions {
                    DispatchQueue.main.asyncAfter(deadline: .now() + confettiConfig.repetitionInterval * Double(i)) {
                        animate.append(false)
                        if value > 0 && value < animate.count {
                            animate[value-1].toggle()
                        }
                    }
                }
            }
        }
    }
}

struct ConfettiContainer: View {
    @Binding var finishedAnimationCounter: Int
    @StateObject var confettiConfig: ConfettiConfig
    @State var firstAppear = true
    
    var body: some View {
        ZStack {
            ForEach(0..<confettiConfig.num, id: \.self) { _ in
                ConfettiView(confettiConfig: confettiConfig)
            }
        }
        .onAppear {
            if firstAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + confettiConfig.animationDuration) {
                    self.finishedAnimationCounter += 1
                }
                firstAppear = false
            }
        }
    }
}

struct ConfettiView: View {
    @State var location: CGPoint = CGPoint(x: 0, y: 0)
    @State var opacity: Double = 0.0
    @StateObject var confettiConfig: ConfettiConfig
    
    func getShape() -> AnyView {
        confettiConfig.shapes.randomElement() ?? AnyView(EmptyView())
    }
    
    func getColor() -> Color {
        confettiConfig.colors.randomElement() ?? .clear
    }
    
    func getSpinDirection() -> CGFloat {
        [-1.0, 1.0].randomElement() ?? 1.0
    }
    
    func getRandomExplosionTimeVariation() -> CGFloat {
        CGFloat((0...999).randomElement() ?? 0) / 2100
    }
    
    func getAnimationDuration() -> CGFloat {
        0.2 + confettiConfig.explosionAnimationDuration + getRandomExplosionTimeVariation()
    }
    
    func getAnimation() -> Animation {
        Animation.timingCurve(0.1, 0.8, 0, 1, duration: getAnimationDuration())
    }
    
    func getDistance() -> CGFloat {
        pow(CGFloat.random(in: 0.01...1), 2.0/7.0) * confettiConfig.radius
    }
    
    func getDelayBeforeRainAnimation() -> TimeInterval {
        confettiConfig.explosionAnimationDuration * 0.1
    }
    
    var body: some View {
        ConfettiAnimationView(shape: getShape(), color: getColor(), spinDirX: getSpinDirection(), spinDirZ: getSpinDirection())
            .offset(x: location.x, y: location.y)
            .opacity(opacity)
            .onAppear {
                withAnimation(getAnimation()) {
                    opacity = confettiConfig.opacity
                    
                    let randomAngle: CGFloat
                    if confettiConfig.openingAngle.degrees <= confettiConfig.closingAngle.degrees {
                        randomAngle = CGFloat.random(in: CGFloat(confettiConfig.openingAngle.degrees)...CGFloat(confettiConfig.closingAngle.degrees))
                    } else {
                        randomAngle = CGFloat.random(in: CGFloat(confettiConfig.openingAngle.degrees)...CGFloat(confettiConfig.closingAngle.degrees + 360)).truncatingRemainder(dividingBy: 360)
                    }
                    
                    let distance = getDistance()
                    
                    location.x = distance * cos(deg2rad(randomAngle))
                    location.y = -distance * sin(deg2rad(randomAngle))
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + getDelayBeforeRainAnimation()) {
                    withAnimation(Animation.timingCurve(0.12, 0, 0.39, 0, duration: confettiConfig.rainAnimationDuration)) {
                        location.y += confettiConfig.rainHeight
                        opacity = confettiConfig.fadesOut ? 0 : confettiConfig.opacity
                    }
                }
            }
    }
    
    func deg2rad(_ number: CGFloat) -> CGFloat {
        number * CGFloat.pi / 180
    }
}

struct ConfettiAnimationView: View {
    @State var shape: AnyView
    @State var color: Color
    @State var spinDirX: CGFloat
    @State var spinDirZ: CGFloat
    @State var firstAppear = true
    
    @State var move = false
    @State var xSpeed: Double = Double.random(in: 0.501...2.201)
    @State var zSpeed = Double.random(in: 0.501...2.201)
    @State var anchor = CGFloat.random(in: 0...1).rounded()
    
    var body: some View {
        shape
            .foregroundColor(color)
            .rotation3DEffect(.degrees(move ? 360 : 0), axis: (x: spinDirX, y: 0, z: 0))
            .animation(Animation.linear(duration: xSpeed).repeatCount(10, autoreverses: false), value: move)
            .rotation3DEffect(.degrees(move ? 360 : 0), axis: (x: 0, y: 0, z: spinDirZ), anchor: UnitPoint(x: anchor, y: anchor))
            .animation(Animation.linear(duration: zSpeed).repeatForever(autoreverses: false), value: move)
            .onAppear {
                if firstAppear {
                    move = true
                    firstAppear = false
                }
            }
    }
}

class ConfettiConfig: ObservableObject {
    @Published var num: Int
    @Published var shapes: [AnyView]
    @Published var colors: [Color]
    @Published var confettiSize: CGFloat
    @Published var rainHeight: CGFloat
    @Published var fadesOut: Bool
    @Published var opacity: Double
    @Published var openingAngle: Angle
    @Published var closingAngle: Angle
    @Published var radius: CGFloat
    @Published var repetitions: Int
    @Published var repetitionInterval: Double
    @Published var explosionAnimationDuration: Double
    @Published var rainAnimationDuration: Double
    
    var animationDuration: Double {
        explosionAnimationDuration + rainAnimationDuration
    }
    
    var openingAngleRad: CGFloat {
        CGFloat(openingAngle.degrees) * 180 / .pi
    }
    
    var closingAngleRad: CGFloat {
        CGFloat(closingAngle.degrees) * 180 / .pi
    }
    
    init(num: Int, shapes: [AnyView], colors: [Color], confettiSize: CGFloat, rainHeight: CGFloat, fadesOut: Bool, opacity: Double, openingAngle: Angle, closingAngle: Angle, radius: CGFloat, repetitions: Int, repetitionInterval: Double) {
        self.num = num
        self.shapes = shapes
        self.colors = colors
        self.confettiSize = confettiSize
        self.rainHeight = rainHeight
        self.fadesOut = fadesOut
        self.opacity = opacity
        self.openingAngle = openingAngle
        self.closingAngle = closingAngle
        self.radius = radius
        self.repetitions = repetitions
        self.repetitionInterval = repetitionInterval
        self.explosionAnimationDuration = Double(radius / 1300)
        self.rainAnimationDuration = Double((rainHeight + radius) / 200)
    }
}
