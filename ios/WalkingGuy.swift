import SwiftUI

/// Music note character matching the sketch:
/// - Large round body (whole-note circle)
/// - Two small eyes sitting on TOP of the circle
/// - Stem rising up from between the eyes
/// - Two short legs at the bottom
/// - Occasionally transforms into a quarter-note (filled head + stem + flag)
/// - Eyes wander and sometimes appear in unexpected places
struct WalkingGuy: View {

    private enum GuyState { case idle, walkingRight, walkingLeft, facingCamera }
    private enum NoteStyle { case whole, quarter, half }

    // Body
    private let bodyR:  CGFloat = 14   // radius of main circle
    private let legW:   CGFloat = 2.5
    private let legH:   CGFloat = 12
    private let stemW:  CGFloat = 2.2
    private let stemH:  CGFloat = 22
    private let eyeR:   CGFloat = 4.5

    // Bounds — he won't walk past ±40pt from centre
    private let maxX: CGFloat = 40

    @SwiftUI.State private var guyState: GuyState = .idle
    @SwiftUI.State private var noteStyle: NoteStyle = .quarter
    @SwiftUI.State private var leftLeg:  Double = 6
    @SwiftUI.State private var rightLeg: Double = -6
    @SwiftUI.State private var bodyX:  CGFloat = 0
    @SwiftUI.State private var bodyY:  CGFloat = 0

    // Eye offsets — can be weird/off-centre
    @SwiftUI.State private var leftEyeOffset:  CGSize = .zero
    @SwiftUI.State private var rightEyeOffset: CGSize = .zero
    @SwiftUI.State private var gazeX: CGFloat = 0
    @SwiftUI.State private var gazeY: CGFloat = 0

    @SwiftUI.State private var gen = 0

    var isFilled: Bool { noteStyle == .quarter }

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── Stem ────────────────────────────────────────────────────
            VStack(spacing: 0) {
                // Flag for quarter note
                if noteStyle == .quarter {
                    flagShape
                        .frame(width: 10, height: 11)
                        .offset(x: 5, y: 1)
                }
                // Stem bar
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(hex: "9333ea"))
                    .frame(width: stemW, height: stemH)
            }
            // Position stem above the body circle, centred slightly right
            .offset(x: bodyR * 0.55,
                    y: -(legH + bodyR * 2 + stemH * 0.5 +
                         (noteStyle == .quarter ? 11 : 0) - bodyR * 0.1))
            .zIndex(0)

            // ── Main body circle ────────────────────────────────────────
            ZStack {
                // Body
                Circle()
                    .fill(isFilled
                          ? LinearGradient(colors: [Color(hex: "c084fc"), Color(hex: "6d28d9")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Color.clear, Color.clear],
                                           startPoint: .top, endPoint: .bottom))
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "9333ea"), lineWidth: isFilled ? 0 : 2.5)
                    )
                    .frame(width: bodyR * 2, height: bodyR * 2)

                // Glint (only when filled)
                if isFilled {
                    Ellipse()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: bodyR * 0.6, height: bodyR * 0.4)
                        .offset(x: -bodyR * 0.25, y: -bodyR * 0.25)
                }

                // Eyes sit on top of the circle body
                HStack(spacing: eyeR * 1.1) {
                    eyeView
                        .offset(leftEyeOffset)
                    eyeView
                        .offset(rightEyeOffset)
                }
                // Eyes ride on top of circle
                .offset(y: -bodyR * 0.55)
            }
            .offset(y: -(legH + bodyR))
            .zIndex(2)

            // ── Legs ────────────────────────────────────────────────────
            HStack(spacing: bodyR * 0.5) {
                legView(angle: leftLeg)
                legView(angle: rightLeg)
            }
            .offset(y: -(legH * 0.5))
            .zIndex(1)

            // ── Foot line ───────────────────────────────────────────────
            Capsule()
                .fill(Color(hex: "7c3aed"))
                .frame(width: bodyR * 1.3, height: 2.5)
                .zIndex(1)
        }
        .offset(x: bodyX, y: bodyY)
        .onAppear {
            startBob()
            scheduleNext(g: gen)
            scheduleGaze(g: gen)
        }
    }

    // MARK: - Eye

    var eyeView: some View {
        let pupilR = eyeR * 0.52
        let maxG   = eyeR * 0.22
        return ZStack {
            Circle()
                .fill(isFilled ? Color.white : Color(hex: "1a0533"))
                .frame(width: eyeR * 2, height: eyeR * 2)
            Circle()
                .fill(isFilled ? Color(hex: "1a0533") : Color.white)
                .frame(width: pupilR * 2, height: pupilR * 2)
                .offset(x: gazeX * maxG, y: gazeY * maxG)
            // Glint
            Circle()
                .fill(Color.white.opacity(isFilled ? 0.7 : 0.3))
                .frame(width: pupilR * 0.45, height: pupilR * 0.45)
                .offset(x: gazeX * maxG + pupilR * 0.3,
                        y: gazeY * maxG - pupilR * 0.3)
        }
    }

    // MARK: - Leg

    func legView(angle: Double) -> some View {
        RoundedRectangle(cornerRadius: legW / 2)
            .fill(Color(hex: "7c3aed"))
            .frame(width: legW, height: legH)
            .rotationEffect(.degrees(angle), anchor: .top)
    }

    // MARK: - Quarter-note flag

    var flagShape: some View {
        Canvas { ctx, size in
            var p = Path()
            p.move(to: CGPoint(x: 0, y: 0))
            p.addCurve(
                to: CGPoint(x: size.width, y: size.height * 0.6),
                control1: CGPoint(x: size.width * 0.8, y: -size.height * 0.2),
                control2: CGPoint(x: size.width, y: size.height * 0.2)
            )
            p.addCurve(
                to: CGPoint(x: 0, y: size.height),
                control1: CGPoint(x: size.width * 0.5, y: size.height * 0.85),
                control2: CGPoint(x: 0, y: size.height * 0.95)
            )
            ctx.fill(p, with: .color(Color(hex: "9333ea")))
        }
    }

    // MARK: - Bob

    func startBob() {
        withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
            bodyY = -3.5
        }
    }

    // MARK: - State machine

    func scheduleNext(g: Int) {
        let delay = Double.random(in: 1.5...4.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            let roll = Int.random(in: 0...4)
            switch roll {
            case 0: startWalk(right: true,  g: g)
            case 1: startWalk(right: false, g: g)
            case 2: faceCamera(g: g)
            case 3: morphNote(g: g)
            default: scheduleNext(g: g)
            }
        }
    }

    func startWalk(right: Bool, g: Int) {
        // Reverse direction if near edge
        let goRight = (bodyX < -maxX * 0.7) ? true
                    : (bodyX >  maxX * 0.7) ? false
                    : right
        guyState = goRight ? .walkingRight : .walkingLeft
        let steps = Int.random(in: 4...9)
        walkStep(remaining: steps, dir: goRight ? 1 : -1, g: g)
    }

    func walkStep(remaining: Int, dir: CGFloat, g: Int) {
        guard g == gen else { return }
        if remaining == 0 { finishWalk(g: g); return }
        let even = remaining % 2 == 0
        let newX = min(maxX, max(-maxX, bodyX + dir * 3.5))
        withAnimation(.easeInOut(duration: 0.16)) {
            leftLeg  = even ?  24 : -6
            rightLeg = even ? -24 :  6
            bodyX    = newX
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            walkStep(remaining: remaining - 1, dir: dir, g: g)
        }
    }

    func finishWalk(g: Int) {
        withAnimation(.spring(response: 0.3)) {
            guyState = .idle
            leftLeg  = 6
            rightLeg = -6
        }
        scheduleNext(g: g)
    }

    func faceCamera(g: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            guyState = .facingCamera
            gazeX = 0; gazeY = 0
            // Eyes drift to centre and look straight at you
            leftEyeOffset  = .zero
            rightEyeOffset = .zero
        }
        let hold = Double.random(in: 0.9...2.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            guard g == gen else { return }
            withAnimation(.easeInOut(duration: 0.2)) { guyState = .idle }
            scheduleNext(g: g)
        }
    }

    func morphNote(g: Int) {
        // Randomly switch note style for a bit, then revert
        let styles: [NoteStyle] = [.whole, .quarter, .half]
        let next = styles.filter { $0 != noteStyle }.randomElement()!
        withAnimation(.easeInOut(duration: 0.25)) { noteStyle = next }
        let hold = Double.random(in: 1.5...4.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            guard g == gen else { return }
            withAnimation(.easeInOut(duration: 0.25)) { noteStyle = .quarter }
            scheduleNext(g: g)
        }
    }

    // MARK: - Eye wander (eyes move independently + sometimes go weird)

    func scheduleGaze(g: Int) {
        let delay = Double.random(in: 0.7...2.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }

            // ~15% chance eyes go to a weird/unexpected position
            let weird = Double.random(in: 0...1) < 0.15
            withAnimation(.easeInOut(duration: weird ? 0.12 : 0.3)) {
                gazeX = CGFloat.random(in: -1...1)
                gazeY = CGFloat.random(in: -1...1)
                if weird {
                    // Eyes drift apart or one goes rogue
                    leftEyeOffset  = CGSize(width: CGFloat.random(in: -3...3),
                                            height: CGFloat.random(in: -3...3))
                    rightEyeOffset = CGSize(width: CGFloat.random(in: -3...3),
                                            height: CGFloat.random(in: -3...3))
                } else {
                    leftEyeOffset  = .zero
                    rightEyeOffset = .zero
                }
            }
            scheduleGaze(g: g)
        }
    }
}
