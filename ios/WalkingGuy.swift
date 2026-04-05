import SwiftUI

/// Music note character matching the hand-drawn sketch:
/// Large circle body, eyes poking above the top of the circle,
/// stem rising between the eyes, simple stick legs with small feet.
/// Can turn sideways (circle squishes to thin oval = 3D effect).
struct WalkingGuy: View {

    private enum GuyState {
        case idle, walkingRight, walkingLeft, facingCamera, turningLeft, turningRight
    }

    // ── Sizes (everything derived from bodyR) ────────────────────────
    private let bodyR:  CGFloat = 18   // main circle radius
    private let legH:   CGFloat = 16   // leg length
    private let legW:   CGFloat = 2.6  // leg thickness
    private let footW:  CGFloat = 7    // horizontal foot line width
    private let stemH:  CGFloat = 22   // stem above head
    private let eyeR:   CGFloat = 4.2  // eye radius
    private let maxX:   CGFloat = 44   // walk boundary

    @SwiftUI.State private var guyState: GuyState = .idle
    @SwiftUI.State private var gen = 0

    // Position / transform
    @SwiftUI.State private var posX:   CGFloat = 0
    @SwiftUI.State private var bobY:   CGFloat = 0
    // 3D turn: 1 = full front, 0 = sideways (body squishes to slit)
    @SwiftUI.State private var turnT:  CGFloat = 1

    // Walk legs
    @SwiftUI.State private var legLAngle: Double = 0
    @SwiftUI.State private var legRAngle: Double = 0

    // Eyes
    @SwiftUI.State private var gazeX:   CGFloat = 0
    @SwiftUI.State private var gazeY:   CGFloat = 0
    @SwiftUI.State private var blinkT:  CGFloat = 1   // 1=open, 0=shut
    @SwiftUI.State private var pupilD:  CGFloat = 1   // dilation multiplier

    // Stem sway
    @SwiftUI.State private var stemSway: Double = 0

    var body: some View {
        // Total canvas: wide enough for walk range, tall enough for stem+eyes
        ZStack(alignment: .bottom) {
            characterStack
        }
        .frame(width: maxX * 2 + bodyR * 2 + 20,
               height: bodyR * 2 + stemH + eyeR * 2 + legH + 6)
        .offset(x: posX, y: bobY)
        .onAppear {
            startBob()
            startStemSway()
            scheduleNext(g: gen)
            scheduleGaze(g: gen)
            scheduleBlink(g: gen)
        }
    }

    // MARK: - Full stack

    var characterStack: some View {
        VStack(spacing: 0) {

            // ── Stem + flag (above head) ─────────────────────────────
            stemView
                .rotationEffect(.degrees(stemSway))
                .offset(x: bodyR * turnT * 0.4)   // stem shifts with turn
                .padding(.bottom, -2)

            // ── Eyes (sit ON TOP of circle, poke above it) ───────────
            eyeRow
                .padding(.bottom, -eyeR * 0.8)    // overlap down into circle
                .zIndex(3)

            // ── Body circle (squishes sideways for 3D turn) ──────────
            bodyView
                .zIndex(2)

            // ── Legs ─────────────────────────────────────────────────
            legsView
                .padding(.top, -2)
                .zIndex(1)
        }
    }

    // MARK: - Stem

    var stemView: some View {
        ZStack(alignment: .bottom) {
            // Flag curl (quarter note)
            flagCurl
                .frame(width: 10, height: 13)
                .offset(x: stemH * 0.22 * CGFloat(turnT))  // hides when sideways

            // Stem bar
            RoundedRectangle(cornerRadius: 1.3)
                .fill(LinearGradient(
                    colors: [Color(hex: "e9d5ff"), Color(hex: "9333ea")],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 2.6, height: stemH)
        }
        .frame(width: 14, height: stemH + 13)
    }

    var flagCurl: some View {
        Canvas { ctx, size in
            var p = Path()
            p.move(to: .init(x: 0, y: 0))
            p.addCurve(
                to:       .init(x: size.width,   y: size.height * 0.5),
                control1: .init(x: size.width,   y: -size.height * 0.1),
                control2: .init(x: size.width,   y: size.height * 0.15))
            p.addCurve(
                to:       .init(x: 0,            y: size.height),
                control1: .init(x: size.width * 0.55, y: size.height * 0.78),
                control2: .init(x: 0,            y: size.height * 0.9))
            ctx.fill(p, with: .color(Color(hex: "9333ea")))
        }
        .opacity(Double(turnT))
    }

    // MARK: - Eyes (above the circle)

    var eyeRow: some View {
        HStack(spacing: eyeR * 1.2 * turnT + eyeR * 0.2) {
            // Left eye disappears when fully sideways
            if turnT > 0.3 {
                singleEye
                    .opacity(Double((turnT - 0.3) / 0.7))
            }
            singleEye
        }
    }

    var singleEye: some View {
        ZStack {
            // White sclera
            Circle()
                .fill(Color.white)
                .frame(width: eyeR * 2, height: eyeR * 2)
                // Subtle drop shadow under eye
                .shadow(color: Color.black.opacity(0.25), radius: 2, y: 1)

            // Iris
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "9333ea"), Color(hex: "4c1d95")],
                    center: .topLeading, startRadius: 0, endRadius: eyeR * 1.5))
                .frame(width: eyeR * 1.4, height: eyeR * 1.4)
                .offset(x: gazeX * eyeR * 0.22, y: gazeY * eyeR * 0.22)

            // Pupil
            Circle()
                .fill(Color(hex: "0a0015"))
                .frame(width: eyeR * 0.7 * pupilD, height: eyeR * 0.7 * pupilD)
                .offset(x: gazeX * eyeR * 0.22, y: gazeY * eyeR * 0.22)

            // Main glint
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: eyeR * 0.28, height: eyeR * 0.28)
                .offset(x: gazeX * eyeR * 0.22 + eyeR * 0.22,
                        y: gazeY * eyeR * 0.22 - eyeR * 0.22)

            // Eyelid blink (fills from top)
            Rectangle()
                .fill(Color.white)
                .frame(width: eyeR * 2.2, height: eyeR * 2.2)
                .scaleEffect(y: 1 - blinkT, anchor: .top)
                .clipShape(Circle().scale(1.05))
        }
        .frame(width: eyeR * 2, height: eyeR * 2)
        .clipShape(Circle())
    }

    // MARK: - Body

    var bodyView: some View {
        ZStack {
            // Glow
            Ellipse()
                .fill(Color(hex: "a855f7").opacity(0.22))
                .frame(width: bodyR * 2 * turnT + 8,
                       height: bodyR * 2 + 6)
                .blur(radius: 8)

            // Main circle — squishes on X for 3D turn
            Ellipse()
                .fill(LinearGradient(
                    colors: [Color(hex: "d8b4fe"), Color(hex: "7c3aed"),
                             Color(hex: "4c1d95")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
                .frame(width: bodyR * 2 * turnT + legW,  // min width = legW so never disappears
                       height: bodyR * 2)

            // Rim highlight (left edge)
            Ellipse()
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.3), Color.clear],
                    startPoint: .topLeading, endPoint: .center))
                .frame(width: bodyR * 0.7 * turnT,
                       height: bodyR * 1.1)
                .offset(x: -bodyR * 0.55 * turnT)
                .blur(radius: 1)
        }
    }

    // MARK: - Legs + feet

    var legsView: some View {
        // The connecting hip bar
        ZStack(alignment: .top) {
            HStack(spacing: bodyR * 0.55 * turnT) {
                legAndFoot(angle: legLAngle, facingRight: guyState == .walkingRight)
                legAndFoot(angle: legRAngle, facingRight: guyState == .walkingRight)
            }
        }
    }

    func legAndFoot(angle: Double, facingRight: Bool) -> some View {
        VStack(spacing: 0) {
            // Leg
            RoundedRectangle(cornerRadius: legW / 2)
                .fill(Color(hex: "7c3aed"))
                .frame(width: legW, height: legH)
                .rotationEffect(.degrees(angle), anchor: .top)

            // Foot (horizontal capsule)
            Capsule()
                .fill(Color(hex: "6d28d9"))
                .frame(width: footW * CGFloat(cos(angle * .pi / 180)).magnitude + 2,
                       height: legW * 0.9)
                .offset(x: CGFloat(sin(angle * .pi / 180)) * legH * 0.5)
        }
    }

    // MARK: - Continuous animations

    func startBob() {
        withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
            bobY = -4
        }
    }

    func startStemSway() {
        withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) {
            stemSway = 5
        }
    }

    // MARK: - State machine

    func scheduleNext(g: Int) {
        let delay = Double.random(in: 1.8...5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            switch Int.random(in: 0...4) {
            case 0: beginWalk(right: true,  g: g)
            case 1: beginWalk(right: false, g: g)
            case 2: faceCamera(g: g)
            case 3: turnSideways(g: g)
            default: scheduleNext(g: g)
            }
        }
    }

    func beginWalk(right: Bool, g: Int) {
        let go = posX < -maxX * 0.8 ? true : posX > maxX * 0.8 ? false : right
        // Turn to face direction
        withAnimation(.easeInOut(duration: 0.18)) {
            guyState = go ? .walkingRight : .walkingLeft
        }
        let steps = Int.random(in: 4...9)
        walkStep(remaining: steps, dir: go ? 1 : -1, g: g)
    }

    func walkStep(remaining: Int, dir: CGFloat, g: Int) {
        guard g == gen else { return }
        if remaining == 0 { finishWalk(g: g); return }
        let even = remaining % 2 == 0
        let newX = min(maxX, max(-maxX, posX + dir * 4))
        withAnimation(.easeInOut(duration: 0.17)) {
            legLAngle = even ?  24 : -7
            legRAngle = even ? -24 :  7
            posX = newX
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.17) {
            walkStep(remaining: remaining - 1, dir: dir, g: g)
        }
    }

    func finishWalk(g: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            guyState  = .idle
            legLAngle = 0; legRAngle = 0
        }
        scheduleNext(g: g)
    }

    func faceCamera(g: Int) {
        withAnimation(.easeOut(duration: 0.2)) {
            guyState  = .facingCamera
            turnT     = 1
            gazeX     = 0; gazeY = 0
            pupilD    = 1.4
        }
        let hold = Double.random(in: 1.0...2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            guard g == gen else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                guyState = .idle; pupilD = 1
            }
            scheduleNext(g: g)
        }
    }

    func turnSideways(g: Int) {
        let goLeft = Bool.random()
        guyState = goLeft ? .turningLeft : .turningRight
        // Turn side
        withAnimation(.easeInOut(duration: 0.3)) { turnT = 0.08 }
        let hold = Double.random(in: 0.6...1.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            guard g == gen else { return }
            // Turn back
            withAnimation(.easeInOut(duration: 0.28)) { turnT = 1; guyState = .idle }
            scheduleNext(g: g)
        }
    }

    // MARK: - Eye wander

    func scheduleGaze(g: Int) {
        let delay = Double.random(in: 0.7...2.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            let snap = guyState == .facingCamera
            withAnimation(.easeInOut(duration: snap ? 0.08 : 0.3)) {
                gazeX = snap ? 0 : CGFloat.random(in: -1...1)
                gazeY = snap ? 0 : CGFloat.random(in: -0.8...0.8)
                if guyState != .facingCamera {
                    pupilD = CGFloat.random(in: 0.75...1.15)
                }
            }
            scheduleGaze(g: g)
        }
    }

    // MARK: - Blink

    func scheduleBlink(g: Int) {
        let delay = Double.random(in: 2.2...7.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            withAnimation(.easeIn(duration: 0.055)) { blinkT = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.085) {
                withAnimation(.easeOut(duration: 0.07)) { blinkT = 1 }
                // Double blink ~20% of the time
                if Double.random(in: 0...1) < 0.2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeIn(duration: 0.055)) { blinkT = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.085) {
                            withAnimation(.easeOut(duration: 0.07)) { blinkT = 1 }
                        }
                    }
                }
            }
            scheduleBlink(g: g)
        }
    }
}
