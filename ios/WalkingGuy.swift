import SwiftUI

/// A quarter-note character: oval note-head face with two eyes,
/// a stem, a thin flat foot-plate, and two thin legs.
/// He idles, walks left/right, and occasionally turns to face the camera.
struct WalkingGuy: View {

    private enum State { case idle, walkingRight, walkingLeft, facingCamera }

    // Layout
    private let headW: CGFloat = 22
    private let headH: CGFloat = 17
    private let stemW: CGFloat = 2.5
    private let stemH: CGFloat = 28
    private let legW:  CGFloat = 2.5
    private let legH:  CGFloat = 13
    private let plateW: CGFloat = 20
    private let plateH: CGFloat = 3

    @SwiftUI.State private var state: State = .idle
    @SwiftUI.State private var leftLeg:  Double = 8
    @SwiftUI.State private var rightLeg: Double = -8
    @SwiftUI.State private var bodyX:  CGFloat = 0
    @SwiftUI.State private var bodyY:  CGFloat = 0
    @SwiftUI.State private var gazeX:  CGFloat = 0.3
    @SwiftUI.State private var gazeY:  CGFloat = 0
    @SwiftUI.State private var gen = 0   // cancels stale callbacks

    var body: some View {
        ZStack(alignment: .bottom) {

            // ── Stem (behind head) ─────────────────────────────────────
            stemView
                .offset(x: headW * 0.38, y: -(legH + plateH + headH * 0.5 + stemH * 0.5 - 2))
                .zIndex(0)

            // ── Note head / face ──────────────────────────────────────
            headView
                .offset(y: -(legH + plateH + headH * 0.5))
                .zIndex(2)

            // ── Legs ──────────────────────────────────────────────────
            HStack(spacing: headW * 0.3) {
                legView(angle: leftLeg)
                legView(angle: rightLeg)
            }
            .offset(y: -(plateH + legH * 0.5))
            .zIndex(1)

            // ── Foot plate ────────────────────────────────────────────
            Capsule()
                .fill(Color(hex: "7c3aed"))
                .frame(width: plateW, height: plateH)
                .zIndex(1)
        }
        .offset(x: bodyX, y: bodyY)
        .onAppear {
            startBob()
            scheduleNext(g: gen)
            scheduleGaze(g: gen)
        }
    }

    // MARK: - Sub-views

    var headView: some View {
        ZStack {
            // Outer shadow/glow
            Ellipse()
                .fill(Color(hex: "a855f7").opacity(0.35))
                .frame(width: headW + 6, height: headH + 5)
                .blur(radius: 4)

            // Head oval
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "c084fc"), Color(hex: "6d28d9")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: headW, height: headH)

            // Specular highlight
            Ellipse()
                .fill(Color.white.opacity(0.18))
                .frame(width: headW * 0.45, height: headH * 0.35)
                .offset(x: -headW * 0.18, y: -headH * 0.18)

            // Eyes — two when facing camera, one offset when side-on
            if state == .facingCamera {
                HStack(spacing: headW * 0.28) {
                    eyeView(r: headH * 0.22)
                    eyeView(r: headH * 0.22)
                }
                .offset(y: headH * 0.04)
            } else {
                // Side-on: single eye slightly toward the "front"
                let xOff: CGFloat = state == .walkingLeft ? -headW * 0.12 : headW * 0.12
                HStack(spacing: headW * 0.22) {
                    eyeView(r: headH * 0.20)
                    eyeView(r: headH * 0.20)
                }
                .offset(x: xOff, y: headH * 0.04)
            }
        }
    }

    func eyeView(r: CGFloat) -> some View {
        let pupilR = r * 0.56
        let maxG   = r * 0.24
        return ZStack {
            Circle().fill(Color.white).frame(width: r * 2, height: r * 2)
            Circle()
                .fill(Color(hex: "1a0533"))
                .frame(width: pupilR * 2, height: pupilR * 2)
                .offset(x: gazeX * maxG, y: gazeY * maxG)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: pupilR * 0.38, height: pupilR * 0.38)
                .offset(x: gazeX * maxG + pupilR * 0.3,
                        y: gazeY * maxG - pupilR * 0.3)
        }
    }

    var stemView: some View {
        RoundedRectangle(cornerRadius: stemW / 2)
            .fill(Color(hex: "9333ea"))
            .frame(width: stemW, height: stemH)
    }

    func legView(angle: Double) -> some View {
        RoundedRectangle(cornerRadius: legW / 2)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "9333ea"), Color(hex: "3b0764")],
                    startPoint: .top, endPoint: .bottom)
            )
            .frame(width: legW, height: legH)
            .rotationEffect(.degrees(angle), anchor: .top)
    }

    // MARK: - Bob

    func startBob() {
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            bodyY = -3
        }
    }

    // MARK: - State machine

    func scheduleNext(g: Int) {
        let delay = Double.random(in: 1.5...4.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            switch Int.random(in: 0...3) {
            case 0: startWalk(right: true,  g: g)
            case 1: startWalk(right: false, g: g)
            case 2: faceCamera(g: g)
            default: scheduleNext(g: g)   // stay idle
            }
        }
    }

    func startWalk(right: Bool, g: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            state = right ? .walkingRight : .walkingLeft
        }
        let steps = Int.random(in: 5...10)
        let dir: CGFloat = right ? 1 : -1
        walkStep(remaining: steps, dir: dir, g: g)
    }

    func walkStep(remaining: Int, dir: CGFloat, g: Int) {
        guard g == gen, state == .walkingRight || state == .walkingLeft else {
            finishWalk(g: g); return
        }
        if remaining == 0 { finishWalk(g: g); return }
        let even = remaining % 2 == 0
        withAnimation(.easeInOut(duration: 0.16)) {
            leftLeg  = even ?  22 : -8
            rightLeg = even ? -22 :  8
            bodyX   += dir * 3.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            walkStep(remaining: remaining - 1, dir: dir, g: g)
        }
    }

    func finishWalk(g: Int) {
        withAnimation(.spring(response: 0.3)) {
            state    = .idle
            leftLeg  = 8
            rightLeg = -8
        }
        scheduleNext(g: g)
    }

    func faceCamera(g: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            state = .facingCamera
            gazeX = 0; gazeY = 0
        }
        let hold = Double.random(in: 1.0...2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            guard g == gen else { return }
            withAnimation(.easeInOut(duration: 0.2)) { state = .idle }
            scheduleNext(g: g)
        }
    }

    // MARK: - Eye wander

    func scheduleGaze(g: Int) {
        let delay = Double.random(in: 0.8...2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard g == gen else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                if state == .facingCamera {
                    gazeX = CGFloat.random(in: -0.4...0.4)
                    gazeY = CGFloat.random(in: -0.3...0.3)
                } else {
                    gazeX = state == .walkingRight
                        ? CGFloat.random(in: 0...1)
                        : CGFloat.random(in: -1...0)
                    gazeY = CGFloat.random(in: -0.6...0.6)
                }
            }
            scheduleGaze(g: g)
        }
    }
}
