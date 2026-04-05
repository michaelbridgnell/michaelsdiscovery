import SwiftUI

/// A little purple 3D dude with legs. He idles, walks, and occasionally
/// turns to face the camera and looks directly at you.
struct WalkingGuy: View {
    private enum WalkState { case idle, walking, facingCamera }

    @State private var walkState: WalkState = .idle
    @State private var leftLegAngle: Double = 5
    @State private var rightLegAngle: Double = -5
    @State private var bobY: CGFloat = 0
    @State private var gazeX: CGFloat = 0
    @State private var gazeY: CGFloat = 0
    // Generation counter cancels stale callbacks
    @State private var generation = 0

    // Layout constants
    private let bW: CGFloat = 24   // body width
    private let bH: CGFloat = 30   // body height
    private let hR: CGFloat = 12   // head radius
    private let lH: CGFloat = 14   // leg height
    private let lW: CGFloat = 5.5  // leg width

    var body: some View {
        ZStack(alignment: .center) {
            // ── Legs (rendered behind body) ─────────────────────────────
            HStack(spacing: bW * 0.28) {
                legView(angle: leftLegAngle)
                legView(angle: rightLegAngle)
            }
            .offset(y: bH * 0.42 + lH * 0.38)
            .zIndex(0)

            // ── Body ─────────────────────────────────────────────────────
            RoundedRectangle(cornerRadius: 10)
                .fill(bodyGradient)
                .frame(
                    width: walkState == .facingCamera ? bW * 1.35 : bW,
                    height: bH
                )
                // Specular highlight (left edge for side, centre for front)
                .overlay(
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 5, height: bH * 0.52)
                        .offset(x: walkState == .facingCamera ? 0 : -bW * 0.28, y: -bH * 0.08)
                )
                .zIndex(1)

            // ── Head ─────────────────────────────────────────────────────
            headView
                .offset(y: -(bH * 0.5 + hR * 0.9))
                .zIndex(2)
        }
        .offset(y: bobY)
        .onAppear {
            startBob()
            scheduleNext(gen: generation)
            scheduleGaze(gen: generation)
        }
    }

    // MARK: - Head

    var headView: some View {
        ZStack {
            // Skull
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "d8b4fe"), Color(hex: "6d28d9")],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: hR * 2.2
                    )
                )
                .frame(width: hR * 2, height: hR * 2)
                .shadow(color: Color(hex: "a855f7").opacity(0.5), radius: 5, y: 2)

            // Eyes – front-facing shows two, side shows one
            if walkState == .facingCamera {
                HStack(spacing: hR * 0.52) {
                    eyeView(eyeR: hR * 0.33)
                    eyeView(eyeR: hR * 0.33)
                }
                .offset(y: hR * 0.04)
            } else {
                eyeView(eyeR: hR * 0.35)
                    .offset(x: hR * 0.22, y: hR * 0.0)
            }
        }
    }

    func eyeView(eyeR: CGFloat) -> some View {
        let pupilR = eyeR * 0.54
        let maxGaze = eyeR * 0.26
        return ZStack {
            Circle().fill(Color.white).frame(width: eyeR * 2, height: eyeR * 2)
            Circle()
                .fill(Color(hex: "1a0533"))
                .frame(width: pupilR * 2, height: pupilR * 2)
                .offset(x: gazeX * maxGaze, y: gazeY * maxGaze)
            // glint
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: pupilR * 0.4, height: pupilR * 0.4)
                .offset(x: gazeX * maxGaze + pupilR * 0.28,
                        y: gazeY * maxGaze - pupilR * 0.28)
        }
    }

    // MARK: - Leg

    func legView(angle: Double) -> some View {
        RoundedRectangle(cornerRadius: lW / 2)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "9333ea"), Color(hex: "3b0764")],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: lW, height: lH)
            .rotationEffect(.degrees(angle), anchor: .top)
            .animation(.easeInOut(duration: 0.2), value: angle)
    }

    // MARK: - Body gradient helper

    var bodyGradient: LinearGradient {
        if walkState == .facingCamera {
            return LinearGradient(
                colors: [Color(hex: "a855f7"), Color(hex: "4c1d95")],
                startPoint: .top, endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [Color(hex: "c084fc"), Color(hex: "581c87")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: - Bob

    func startBob() {
        withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
            bobY = -4
        }
    }

    // MARK: - State machine

    func scheduleNext(gen: Int) {
        let delay = Double.random(in: 1.8...4.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard gen == generation else { return }
            let roll = Int.random(in: 0...3)
            switch roll {
            case 0, 1: startWalking(gen: gen)
            case 2:    turnToCamera(gen: gen)
            default:   scheduleNext(gen: gen)   // stay idle longer
            }
        }
    }

    func startWalking(gen: Int) {
        walkState = .walking
        let steps = Int.random(in: 4...9)
        walkStep(remaining: steps, gen: gen)
    }

    func walkStep(remaining: Int, gen: Int) {
        guard gen == generation, walkState == .walking else {
            finishWalking(gen: gen); return
        }
        if remaining == 0 { finishWalking(gen: gen); return }
        let fwd: Double = 22
        let bwd: Double = -22
        let goLeft = (remaining % 2 == 0)
        withAnimation(.easeInOut(duration: 0.18)) {
            leftLegAngle  = goLeft ? fwd : bwd
            rightLegAngle = goLeft ? bwd : fwd
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            walkStep(remaining: remaining - 1, gen: gen)
        }
    }

    func finishWalking(gen: Int) {
        walkState = .idle
        withAnimation(.spring()) {
            leftLegAngle  = 5
            rightLegAngle = -5
        }
        scheduleNext(gen: gen)
    }

    func turnToCamera(gen: Int) {
        withAnimation(.easeInOut(duration: 0.22)) {
            walkState = .facingCamera
            gazeX = 0
            gazeY = 0
        }
        let hold = Double.random(in: 0.9...2.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            guard gen == generation else { return }
            withAnimation(.easeInOut(duration: 0.22)) { walkState = .idle }
            scheduleNext(gen: gen)
        }
    }

    // MARK: - Eye wander

    func scheduleGaze(gen: Int) {
        let delay = Double.random(in: 0.9...2.8)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard gen == generation else { return }
            if walkState == .facingCamera {
                // When facing camera, look slightly toward viewer centre
                withAnimation(.easeOut(duration: 0.15)) { gazeX = 0; gazeY = -0.2 }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    gazeX = CGFloat.random(in: -1...1)
                    gazeY = CGFloat.random(in: -0.7...0.7)
                }
            }
            scheduleGaze(gen: gen)
        }
    }
}
