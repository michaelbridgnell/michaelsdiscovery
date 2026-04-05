import SwiftUI

/// A music-note character with real personality:
/// - Round hollow/filled body with inner glow and rim light
/// - Eyes with multi-ring iris, animated pupil dilation, random blinks
/// - Squash-and-stretch on landing, anticipation dip before walks
/// - Stem sways gently
/// - Occasionally turns to face you and holds your gaze
/// - Eyes wander independently; sometimes go subtly wrong
struct WalkingGuy: View {

    private enum GuyState { case idle, anticipate, walkingRight, walkingLeft, facingCamera, landing }
    private enum NoteStyle { case quarter, whole, half }

    // ── Layout ──────────────────────────────────────────────────────
    private let bodyR:  CGFloat = 15
    private let legW:   CGFloat = 2.8
    private let legH:   CGFloat = 13
    private let stemW:  CGFloat = 2.4
    private let stemH:  CGFloat = 24
    private let eyeR:   CGFloat = 4.8
    private let maxX:   CGFloat = 38

    // ── State ────────────────────────────────────────────────────────
    @SwiftUI.State private var guyState:  GuyState  = .idle
    @SwiftUI.State private var noteStyle: NoteStyle = .quarter
    @SwiftUI.State private var gen = 0

    // Walk
    @SwiftUI.State private var bodyX:     CGFloat = 0
    @SwiftUI.State private var leftLeg:   Double  = 5
    @SwiftUI.State private var rightLeg:  Double  = -5

    // Bob / squash
    @SwiftUI.State private var bodyY:     CGFloat = 0
    @SwiftUI.State private var scaleX:    CGFloat = 1
    @SwiftUI.State private var scaleY:    CGFloat = 1

    // Stem sway
    @SwiftUI.State private var stemAngle: Double  = 0

    // Eyes
    @SwiftUI.State private var gazeX:     CGFloat = 0
    @SwiftUI.State private var gazeY:     CGFloat = 0
    @SwiftUI.State private var pupilScale:CGFloat = 1      // dilation
    @SwiftUI.State private var blinkT:    CGFloat = 1      // 1=open 0=closed
    @SwiftUI.State private var leftEyeExtraOffset:  CGSize = .zero
    @SwiftUI.State private var rightEyeExtraOffset: CGSize = .zero

    var isFilled: Bool { noteStyle != .whole }
    var facing: Bool   { guyState == .facingCamera }

    // ── Body ─────────────────────────────────────────────────────────
    var body: some View {
        ZStack(alignment: .bottom) {

            // Stem + flag
            stemAndFlag
                .rotationEffect(.degrees(stemAngle), anchor: .bottom)
                .offset(x: bodyR * 0.52,
                        y: -(legH + bodyR * 2 + stemH * 0.5 - bodyR * 0.05))
                .zIndex(0)

            // Body
            bodyCircle
                .scaleEffect(x: scaleX, y: scaleY, anchor: .bottom)
                .offset(y: -(legH + bodyR))
                .zIndex(2)

            // Legs
            HStack(spacing: bodyR * 0.55) {
                legView(angle: leftLeg)
                legView(angle: rightLeg)
            }
            .offset(y: -legH * 0.5)
            .zIndex(1)

            // Foot plate
            Capsule()
                .fill(Color(hex: "6d28d9"))
                .frame(width: bodyR * 1.4, height: 2.5)
                .zIndex(1)
        }
        .offset(x: bodyX, y: bodyY)
        .onAppear {
            startBob()
            swaySystem()
            scheduleNext(g: gen)
            scheduleGaze(g: gen)
            scheduleBlink(g: gen)
        }
    }

    // MARK: - Body circle

    var bodyCircle: some View {
        ZStack {
            // ── Outer glow ──────────────────────────────────────────
            Circle()
                .fill(Color(hex: "a855f7").opacity(isFilled ? 0.28 : 0.15))
                .frame(width: bodyR * 2 + 10, height: bodyR * 2 + 10)
                .blur(radius: 7)

            // ── Main fill ───────────────────────────────────────────
            Circle()
                .fill(isFilled
                    ? AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: "d8b4fe"), Color(hex: "7c3aed"), Color(hex: "3b0764")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    : AnyShapeStyle(Color(hex: "0e0618")))
                .frame(width: bodyR * 2, height: bodyR * 2)

            // ── Rim / stroke ─────────────────────────────────────────
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "e9d5ff"), Color(hex: "7c3aed")],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: isFilled ? 0 : 2.5
                )
                .frame(width: bodyR * 2, height: bodyR * 2)

            // ── Inner shadow ring (depth) ─────────────────────────────
            if isFilled {
                Circle()
                    .stroke(Color(hex: "3b0764").opacity(0.5), lineWidth: 5)
                    .frame(width: bodyR * 2 - 3, height: bodyR * 2 - 3)
                    .blur(radius: 2)
            }

            // ── Top specular highlight ───────────────────────────────
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(isFilled ? 0.35 : 0.12), Color.clear],
                        startPoint: .top, endPoint: .bottom)
                )
                .frame(width: bodyR * 0.9, height: bodyR * 0.55)
                .offset(x: -bodyR * 0.2, y: -bodyR * 0.45)
                .blur(radius: 1)

            // ── Eyes sitting on top of the circle ──────────────────
            HStack(spacing: eyeR * 1.15) {
                eyeView(extra: leftEyeExtraOffset)
                eyeView(extra: rightEyeExtraOffset)
            }
            .offset(y: -bodyR * 0.52)
        }
    }

    // MARK: - Eye

    func eyeView(extra: CGSize) -> some View {
        let pupilR  = eyeR * 0.48
        let irisR   = eyeR * 0.75
        let maxG    = eyeR * 0.2
        let bg      = isFilled ? Color.white       : Color(hex: "1a1035")
        let irisCol = isFilled ? Color(hex: "6d28d9") : Color(hex: "c084fc")
        let pupilCol = isFilled ? Color(hex: "0e0618") : Color.white

        return ZStack {
            // Sclera
            Circle()
                .fill(bg)
                .frame(width: eyeR * 2, height: eyeR * 2)

            // Iris — multi-ring for texture
            Circle()
                .fill(irisCol)
                .frame(width: irisR * 2, height: irisR * 2)
                .offset(x: gazeX * maxG, y: gazeY * maxG)

            // Iris inner ring (texture)
            Circle()
                .stroke(irisCol.opacity(0.4), lineWidth: 1)
                .frame(width: irisR * 1.3, height: irisR * 1.3)
                .offset(x: gazeX * maxG, y: gazeY * maxG)

            // Pupil — scales with dilation
            Circle()
                .fill(pupilCol)
                .frame(width: pupilR * 2 * pupilScale, height: pupilR * 2 * pupilScale)
                .offset(x: gazeX * maxG, y: gazeY * maxG)

            // Glint 1 (main)
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: pupilR * 0.5, height: pupilR * 0.5)
                .offset(x: gazeX * maxG + pupilR * 0.35,
                        y: gazeY * maxG - pupilR * 0.35)

            // Glint 2 (small secondary)
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: pupilR * 0.22, height: pupilR * 0.22)
                .offset(x: gazeX * maxG - pupilR * 0.3,
                        y: gazeY * maxG + pupilR * 0.25)

            // Eyelid blink — scaleY closes from top
            Rectangle()
                .fill(bg)
                .frame(width: eyeR * 2.2, height: eyeR * 2.2)
                .scaleEffect(y: 1 - blinkT, anchor: .top)
                .clipShape(Circle().scale(1.1))
        }
        .frame(width: eyeR * 2, height: eyeR * 2)
        .clipShape(Circle())
        .offset(extra)
    }

    // MARK: - Stem

    var stemAndFlag: some View {
        VStack(spacing: 0) {
            if noteStyle == .quarter {
                flagCanvas
                    .frame(width: 11, height: 12)
                    .offset(x: 5.5, y: 0.5)
            }
            if noteStyle == .half {
                // Half-note: just a small serif at top
                Capsule()
                    .fill(Color(hex: "9333ea"))
                    .frame(width: 6, height: 3)
                    .offset(x: 2)
            }
            RoundedRectangle(cornerRadius: 1.2)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "e9d5ff"), Color(hex: "7c3aed")],
                        startPoint: .top, endPoint: .bottom)
                )
                .frame(width: stemW, height: stemH)
        }
    }

    var flagCanvas: some View {
        Canvas { ctx, size in
            var p = Path()
            p.move(to: CGPoint(x: 0, y: 0))
            p.addCurve(
                to:       CGPoint(x: size.width,     y: size.height * 0.55),
                control1: CGPoint(x: size.width,     y: -size.height * 0.15),
                control2: CGPoint(x: size.width,     y: size.height * 0.2)
            )
            p.addCurve(
                to:       CGPoint(x: 0,              y: size.height),
                control1: CGPoint(x: size.width * 0.5, y: size.height * 0.8),
                control2: CGPoint(x: 0,              y: size.height * 0.95)
            )
            ctx.fill(p, with: .color(Color(hex: "9333ea")))
        }
    }

    // MARK: - Leg

    func legView(angle: Double) -> some View {
        RoundedRectangle(cornerRadius: legW / 2)
            .fill(LinearGradient(
                colors: [Color(hex: "a855f7"), Color(hex: "3b0764")],
                startPoint: .top, endPoint: .bottom))
            .frame(width: legW, height: legH)
            .rotationEffect(.degrees(angle), anchor: .top)
    }

    // MARK: - Continuous animations

    func startBob() {
        withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
            bodyY = -4
        }
    }

    func swaySystem() {
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            stemAngle = 4
        }
    }

    // MARK: - State machine

    func scheduleNext(g: Int) {
        let delay = Double.random(in: 1.8...4.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            switch Int.random(in: 0...4) {
            case 0: anticipateThenWalk(right: true,  g: g)
            case 1: anticipateThenWalk(right: false, g: g)
            case 2: faceCamera(g: g)
            case 3: morphNote(g: g)
            default: scheduleNext(g: g)
            }
        }
    }

    // Anticipation dip before walking (gives weight)
    func anticipateThenWalk(right: Bool, g: Int) {
        let goRight = bodyX < -maxX * 0.75 ? true
                    : bodyX >  maxX * 0.75 ? false
                    : right
        withAnimation(.easeIn(duration: 0.12)) {
            scaleX = 1.08; scaleY = 0.92
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            guard g == gen else { return }
            withAnimation(.easeOut(duration: 0.1)) {
                scaleX = 0.94; scaleY = 1.06
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard g == gen else { return }
                withAnimation(.easeOut(duration: 0.08)) { scaleX = 1; scaleY = 1 }
                guyState = goRight ? .walkingRight : .walkingLeft
                walkStep(remaining: Int.random(in: 5...10),
                         dir: goRight ? 1 : -1, g: g)
            }
        }
    }

    func walkStep(remaining: Int, dir: CGFloat, g: Int) {
        guard g == gen else { return }
        if remaining == 0 { landAndIdle(g: g); return }
        let even   = remaining % 2 == 0
        let newX   = min(maxX, max(-maxX, bodyX + dir * 3.8))
        let squashY: CGFloat = even ? 0.94 : 1.06
        let squashX: CGFloat = even ? 1.06 : 0.94
        withAnimation(.easeInOut(duration: 0.15)) {
            leftLeg  = even ?  26 : -6
            rightLeg = even ? -26 :  6
            bodyX    = newX
            scaleX   = squashX
            scaleY   = squashY
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            walkStep(remaining: remaining - 1, dir: dir, g: g)
        }
    }

    // Landing squash then settle
    func landAndIdle(g: Int) {
        withAnimation(.easeOut(duration: 0.12)) {
            scaleX = 1.14; scaleY = 0.86
            leftLeg = 5; rightLeg = -5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                scaleX = 1; scaleY = 1
                guyState = .idle
            }
            scheduleNext(g: g)
        }
    }

    func faceCamera(g: Int) {
        // Pupil dilates when making eye contact
        withAnimation(.easeOut(duration: 0.18)) {
            guyState = .facingCamera
            gazeX = 0; gazeY = -0.1
            pupilScale = 1.35
            leftEyeExtraOffset  = .zero
            rightEyeExtraOffset = .zero
        }
        let hold = Double.random(in: 1.0...2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            guard g == gen else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                guyState = .idle
                pupilScale = 1.0
            }
            scheduleNext(g: g)
        }
    }

    func morphNote(g: Int) {
        let styles: [NoteStyle] = [.whole, .half]
        let next = styles.randomElement()!
        withAnimation(.easeInOut(duration: 0.3)) { noteStyle = next }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...4)) {
            guard g == gen else { return }
            withAnimation(.easeInOut(duration: 0.3)) { noteStyle = .quarter }
            scheduleNext(g: g)
        }
    }

    // MARK: - Eye wander

    func scheduleGaze(g: Int) {
        let delay = Double.random(in: 0.6...2.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            let weird = Double.random(in: 0...1) < 0.12

            withAnimation(.easeInOut(duration: weird ? 0.1 : 0.28)) {
                if guyState == .facingCamera {
                    // Small drift while maintaining eye contact
                    gazeX = CGFloat.random(in: -0.3...0.3)
                    gazeY = CGFloat.random(in: -0.2...0.2)
                } else {
                    gazeX = CGFloat.random(in: -1...1)
                    gazeY = CGFloat.random(in: -0.8...0.8)
                }
                // Pupil reacts — dilates in dark gaze positions
                pupilScale = guyState == .facingCamera
                    ? 1.35
                    : CGFloat.random(in: 0.75...1.2)

                if weird {
                    leftEyeExtraOffset  = CGSize(width: CGFloat.random(in: -3.5...3.5),
                                                 height: CGFloat.random(in: -3.5...3.5))
                    rightEyeExtraOffset = CGSize(width: CGFloat.random(in: -3.5...3.5),
                                                 height: CGFloat.random(in: -3.5...3.5))
                } else {
                    leftEyeExtraOffset  = .zero
                    rightEyeExtraOffset = .zero
                }
            }
            scheduleGaze(g: g)
        }
    }

    // MARK: - Blink

    func scheduleBlink(g: Int) {
        let delay = Double.random(in: 2.5...6.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            // Close
            withAnimation(.easeIn(duration: 0.06)) { blinkT = 0 }
            // Open
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                withAnimation(.easeOut(duration: 0.08)) { blinkT = 1 }
                // Occasional double-blink
                if Double.random(in: 0...1) < 0.25 {
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
