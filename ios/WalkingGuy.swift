import SwiftUI

struct WalkingGuy: View {

    private enum GuyState {
        case idle, walkingRight, walkingLeft, facingCamera, turningSide
    }

    private let bodyR:  CGFloat = 20
    private let stemH:  CGFloat = 26
    private let flagH:  CGFloat = 15
    private let flagW:  CGFloat = 13
    private let eyeR:   CGFloat = 7
    private let legH:   CGFloat = 22
    private let legW:   CGFloat = 4.5
    private let footW:  CGFloat = 11
    private let stemW:  CGFloat = 3.5
    private let maxX:   CGFloat = 28

    @SwiftUI.State private var guyState: GuyState = .idle
    @SwiftUI.State private var gen = 0

    @SwiftUI.State private var posX:  CGFloat = 0
    @SwiftUI.State private var bobY:  CGFloat = 0
    @SwiftUI.State private var turnT: CGFloat = 1   // 1=front, 0=side

    @SwiftUI.State private var legL: Double = 0
    @SwiftUI.State private var legR: Double = 0

    @SwiftUI.State private var gazeX:  CGFloat = 0
    @SwiftUI.State private var gazeY:  CGFloat = 0
    @SwiftUI.State private var blinkT: CGFloat = 1
    @SwiftUI.State private var pupilD: CGFloat = 1

    @SwiftUI.State private var stemSway: Double = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            character
                .offset(x: posX, y: bobY)
        }
        .frame(width: maxX * 2 + 100, height: 106)
        .onAppear {
            startBob()
            startStemSway()
            scheduleNext(g: gen)
            scheduleGaze(g: gen)
            scheduleBlink(g: gen)
        }
    }

    // MARK: - Whole character (ZStack, body center = origin)

    var character: some View {
        ZStack {
            // Body
            bodyCircle

            // Left eye
            singleEye
                .offset(x: -eyeR * 1.1 * turnT,
                        y: -(bodyR + eyeR * 0.45))
                .opacity(turnT > 0.3 ? Double((turnT - 0.3) / 0.7) : 0)
                .zIndex(3)

            // Right eye
            singleEye
                .offset(x: eyeR * 0.5 * turnT,
                        y: -(bodyR + eyeR * 0.55))
                .zIndex(3)

            // Stem
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "5b21b6"))
                .frame(width: stemW, height: stemH)
                .rotationEffect(.degrees(stemSway))
                .offset(x: bodyR * 0.65 * turnT,
                        y: -(bodyR * 0.2 + stemH * 0.5))
                .zIndex(2)

            // Flag
            let stemTopX = bodyR * 0.65 * turnT + stemW * 0.5
            let stemTopY = -(bodyR * 0.2 + stemH)
            Canvas { ctx, size in
                var p = Path()
                p.move(to: .init(x: 0, y: 0))
                p.addCurve(to:       .init(x: size.width, y: size.height * 0.55),
                           control1: .init(x: size.width * 1.1, y: 0),
                           control2: .init(x: size.width * 1.1, y: size.height * 0.28))
                p.addCurve(to:       .init(x: 0, y: size.height),
                           control1: .init(x: size.width * 0.7, y: size.height * 0.72),
                           control2: .init(x: 0, y: size.height * 0.88))
                ctx.fill(p, with: .color(Color(hex: "5b21b6")))
            }
            .frame(width: flagW, height: flagH)
            .offset(x: stemTopX + flagW * 0.5,
                    y: stemTopY + flagH * 0.5)
            .opacity(Double(turnT))
            .zIndex(2)

            // Legs
            HStack(spacing: max(2, bodyR * 0.45 * turnT)) {
                legAndFoot(angle: legL)
                legAndFoot(angle: legR)
            }
            .offset(y: bodyR + 1)
            .zIndex(1)
        }
        .frame(width: 90, height: 96)
    }

    // MARK: - Body

    var bodyCircle: some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: "6d28d9"))
                .frame(width: bodyR * 2 * turnT + legW,
                       height: bodyR * 2)

            Ellipse()
                .fill(Color(hex: "9d5aff").opacity(0.5))
                .frame(width: bodyR * 1.1 * turnT,
                       height: bodyR * 0.75)
                .offset(x: -bodyR * 0.25 * turnT, y: -bodyR * 0.38)
        }
    }

    // MARK: - Eye

    var singleEye: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: eyeR * 2, height: eyeR * 2)

            Circle()
                .fill(Color(hex: "5b21b6"))
                .frame(width: eyeR * 1.25, height: eyeR * 1.25)
                .offset(x: gazeX * eyeR * 0.3, y: gazeY * eyeR * 0.3)

            Circle()
                .fill(Color(hex: "0d0010"))
                .frame(width: eyeR * 0.6 * pupilD, height: eyeR * 0.6 * pupilD)
                .offset(x: gazeX * eyeR * 0.3, y: gazeY * eyeR * 0.3)

            Circle()
                .fill(Color.white)
                .frame(width: eyeR * 0.38, height: eyeR * 0.38)
                .offset(x: gazeX * eyeR * 0.3 + eyeR * 0.3,
                        y: gazeY * eyeR * 0.3 - eyeR * 0.32)

            Rectangle()
                .fill(Color.white)
                .frame(width: eyeR * 2.2, height: eyeR * 2.2)
                .scaleEffect(y: 1 - blinkT, anchor: .top)
                .clipShape(Circle().scale(1.08))
        }
        .frame(width: eyeR * 2, height: eyeR * 2)
        .clipShape(Circle())
    }

    // MARK: - Legs + feet

    func legAndFoot(angle: Double) -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: legW / 2)
                .fill(Color(hex: "5b21b6"))
                .frame(width: legW, height: legH)
                .rotationEffect(.degrees(angle), anchor: .top)

            Capsule()
                .fill(Color(hex: "4c1d95"))
                .frame(width: footW * max(0.3, CGFloat(cos(angle * .pi / 180)).magnitude) + 2,
                       height: legW * 0.75)
                .offset(x: CGFloat(sin(angle * .pi / 180)) * legH * 0.5)
        }
    }

    // MARK: - Continuous animations

    func startBob() {
        withAnimation(.easeInOut(duration: 0.78).repeatForever(autoreverses: true)) {
            bobY = -5
        }
    }

    func startStemSway() {
        withAnimation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true)) {
            stemSway = 5
        }
    }

    // MARK: - State machine

    func scheduleNext(g: Int) {
        let delay = Double.random(in: 2.0...5.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            switch Int.random(in: 0...4) {
            case 0: beginWalk(right: true,  g: g)
            case 1: beginWalk(right: false, g: g)
            case 2: faceCamera(g: g)
            case 3: turnSide(g: g)
            default: scheduleNext(g: g)
            }
        }
    }

    func beginWalk(right: Bool, g: Int) {
        let go = posX < -maxX * 0.8 ? true : posX > maxX * 0.8 ? false : right
        guyState = go ? .walkingRight : .walkingLeft
        walkStep(remaining: Int.random(in: 4...9), dir: go ? 1 : -1, g: g)
    }

    func walkStep(remaining: Int, dir: CGFloat, g: Int) {
        guard g == gen else { return }
        let newX = posX + dir * 5
        if remaining == 0 || (dir > 0 && newX > maxX) || (dir < 0 && newX < -maxX) {
            finishWalk(g: g); return
        }
        let even = remaining % 2 == 0
        withAnimation(.easeInOut(duration: 0.16)) {
            legL = even ?  28 : -8
            legR = even ? -28 :  8
            posX = newX
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            walkStep(remaining: remaining - 1, dir: dir, g: g)
        }
    }

    func finishWalk(g: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            guyState = .idle; legL = 0; legR = 0
        }
        scheduleNext(g: g)
    }

    func faceCamera(g: Int) {
        withAnimation(.easeOut(duration: 0.2)) {
            guyState = .facingCamera; turnT = 1
            gazeX = 0; gazeY = 0; pupilD = 1.6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.2...2.8)) {
            guard g == gen else { return }
            withAnimation(.easeInOut(duration: 0.25)) { guyState = .idle; pupilD = 1 }
            scheduleNext(g: g)
        }
    }

    func turnSide(g: Int) {
        guyState = .turningSide
        withAnimation(.easeInOut(duration: 0.35)) { turnT = 0.18 }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.8...1.6)) {
            guard g == gen else { return }
            withAnimation(.easeInOut(duration: 0.30)) { turnT = 1; guyState = .idle }
            scheduleNext(g: g)
        }
    }

    // MARK: - Gaze

    func scheduleGaze(g: Int) {
        let delay = Double.random(in: 0.8...2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            let snap = guyState == .facingCamera
            withAnimation(.easeInOut(duration: snap ? 0.06 : 0.35)) {
                gazeX = snap ? 0 : CGFloat.random(in: -1...1)
                gazeY = snap ? 0 : CGFloat.random(in: -0.7...0.7)
                if !snap { pupilD = CGFloat.random(in: 0.8...1.2) }
            }
            scheduleGaze(g: g)
        }
    }

    // MARK: - Blink

    func scheduleBlink(g: Int) {
        let delay = Double.random(in: 2.5...7.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            withAnimation(.easeIn(duration: 0.06)) { blinkT = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                withAnimation(.easeOut(duration: 0.08)) { blinkT = 1 }
                if Double.random(in: 0...1) < 0.22 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        withAnimation(.easeIn(duration: 0.06)) { blinkT = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                            withAnimation(.easeOut(duration: 0.08)) { blinkT = 1 }
                        }
                    }
                }
            }
            scheduleBlink(g: g)
        }
    }
}
