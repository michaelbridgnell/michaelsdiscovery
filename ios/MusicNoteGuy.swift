import SwiftUI

/// A tiny animated music-note character with two eyes.
/// He bobs gently, and every few seconds his pupils dart to look
/// at the user (centre of his face) before wandering back.
struct MusicNoteGuy: View {
    // Bobbing
    @State private var bobOffset: CGFloat = 0
    // Pupil gaze — (0,0) = neutral, positive x = right, positive y = down
    @State private var gazeX: CGFloat = 0
    @State private var gazeY: CGFloat = 0
    // Occasional "look at you" moment
    @State private var lookingAtUser = false

    // Size of the whole character
    private let size: CGFloat = 52
    // Head is the note-head circle at the bottom-left of the note
    private var headR: CGFloat { size * 0.26 }
    // Stem
    private var stemH: CGFloat { size * 0.66 }
    private var stemW: CGFloat { size * 0.055 }
    // Flag top-right
    private var flagW: CGFloat { size * 0.28 }
    private var flagH: CGFloat { size * 0.22 }

    var body: some View {
        ZStack {
            // ── Stem ─────────────────────────────────────────
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "c084fc"))
                .frame(width: stemW, height: stemH)
                .offset(x: headR - stemW / 2, y: -stemH / 2 + headR * 0.4)

            // ── Flag (top-right curl) ─────────────────────────
            FlagShape()
                .fill(Color(hex: "c084fc"))
                .frame(width: flagW, height: flagH)
                .offset(x: headR - stemW / 2 + stemW / 2 + flagW / 2 - 2,
                        y: -stemH + headR * 0.4 + flagH / 2)

            // ── Note head / body ─────────────────────────────
            Ellipse()
                .fill(
                    LinearGradient(colors: [Color(hex: "a855f7"), Color(hex: "7c3aed")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: headR * 2.1, height: headR * 1.7)
                .rotationEffect(.degrees(-18))

            // ── Eyes ─────────────────────────────────────────
            HStack(spacing: headR * 0.45) {
                eye(gazeX: gazeX, gazeY: gazeY)
                eye(gazeX: gazeX, gazeY: gazeY)
            }
            .offset(x: -headR * 0.05, y: -headR * 0.15)
        }
        .frame(width: size, height: size + stemH * 0.5)
        .offset(y: bobOffset)
        .onAppear { startAnimations() }
    }

    // MARK: - Eye

    func eye(gazeX: CGFloat, gazeY: CGFloat) -> some View {
        let eyeR: CGFloat = headR * 0.33
        let pupilR: CGFloat = eyeR * 0.52
        let maxGaze: CGFloat = eyeR * 0.28

        return ZStack {
            // White sclera
            Circle()
                .fill(Color.white)
                .frame(width: eyeR * 2, height: eyeR * 2)
            // Pupil
            Circle()
                .fill(Color(hex: "1a0533"))
                .frame(width: pupilR * 2, height: pupilR * 2)
                .offset(x: gazeX * maxGaze, y: gazeY * maxGaze)
            // Glint
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: pupilR * 0.5, height: pupilR * 0.5)
                .offset(x: gazeX * maxGaze + pupilR * 0.25,
                        y: gazeY * maxGaze - pupilR * 0.25)
        }
    }

    // MARK: - Animations

    func startAnimations() {
        // Gentle bob up and down
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            bobOffset = -5
        }

        // Eye wander loop
        scheduleNextGaze()
    }

    func scheduleNextGaze() {
        let delay = Double.random(in: 1.8...4.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let lookAtUser = Bool.random() && Bool.random() // ~25% chance

            if lookAtUser {
                // Snap to look straight at the "user" (centre, slightly up)
                withAnimation(.easeOut(duration: 0.12)) {
                    gazeX = 0
                    gazeY = -0.4
                    lookingAtUser = true
                }
                // Hold gaze, then wander away
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        gazeX = CGFloat.random(in: -1...1)
                        gazeY = CGFloat.random(in: -0.5...0.5)
                        lookingAtUser = false
                    }
                    scheduleNextGaze()
                }
            } else {
                // Random wander
                withAnimation(.easeInOut(duration: 0.4)) {
                    gazeX = CGFloat.random(in: -1...1)
                    gazeY = CGFloat.random(in: -0.6...0.6)
                }
                scheduleNextGaze()
            }
        }
    }
}

// MARK: - Flag Shape

/// The little curved flag at the top of the stem
private struct FlagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY * 0.4),
            control1: CGPoint(x: rect.maxX * 0.6, y: -rect.maxY * 0.3),
            control2: CGPoint(x: rect.maxX, y: 0)
        )
        p.addCurve(
            to: CGPoint(x: 0, y: rect.maxY),
            control1: CGPoint(x: rect.maxX * 0.5, y: rect.maxY * 0.7),
            control2: CGPoint(x: rect.maxX * 0.1, y: rect.maxY * 0.9)
        )
        p.closeSubpath()
        return p
    }
}
