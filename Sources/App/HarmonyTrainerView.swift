import HarmonyTrainer
import SwiftUI

// MARK: - Degree Colors (Hookpad-style per scale degree)

enum DegreeColor {
    static func color(for degree: Int) -> Color {
        switch degree {
        case 1: return Color(red: 0.91, green: 0.30, blue: 0.24)  // Coral/Red - I
        case 2: return Color(red: 0.83, green: 0.69, blue: 0.22)  // Gold - ii
        case 3: return Color(red: 0.66, green: 0.84, blue: 0.36)  // Yellow-green - iii
        case 4: return Color(red: 0.15, green: 0.68, blue: 0.38)  // Green - IV
        case 5: return Color(red: 0.00, green: 0.74, blue: 0.83)  // Cyan - V
        case 6: return Color(red: 0.20, green: 0.60, blue: 0.86)  // Blue - vi
        case 7: return Color(red: 0.61, green: 0.35, blue: 0.71)  // Purple - vii
        default: return .gray
        }
    }

    static func functionColor(for function: HarmonicFunction) -> Color {
        switch function {
        case .tonic: return .blue
        case .subdominant: return .green
        case .dominant: return .orange
        }
    }
}

// MARK: - Main HarmonyTrainerView

struct HarmonyTrainerView: View {
    let state: HarmonyTrainerState
    let onSetKey: (PitchClass) -> Void
    let onSetScaleType: (ScaleType) -> Void
    let onSetMode: (ExerciseMode) -> Void
    let onSelectProgression: (ProgressionTemplate) -> Void
    let onAdvance: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider().background(Color.white.opacity(0.1))
            progressionTimeline
            Divider().background(Color.white.opacity(0.1))
            chordFeedback
            Divider().background(Color.white.opacity(0.1))
            degreeBar
        }
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 16) {
            // Key selector
            HStack(spacing: 6) {
                Text("Tonart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: Binding(
                    get: { state.selectedKey },
                    set: { onSetKey($0) }
                )) {
                    ForEach(PitchClass.allCases, id: \.self) { pc in
                        Text(pc.germanName).tag(pc)
                    }
                }
                .labelsHidden()
                .frame(width: 70)
            }

            // Mode selector
            HStack(spacing: 6) {
                Text("Modus")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: Binding(
                    get: { state.selectedScaleType == .major },
                    set: { onSetScaleType($0 ? .major : .naturalMinor) }
                )) {
                    Text("Dur").tag(true)
                    Text("Moll").tag(false)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            Divider().frame(height: 20)

            // Exercise mode
            exerciseModePicker

            Spacer()

            // Stats
            if state.exercise.mode != .freePlay {
                statsDisplay
            }

            // Reset button
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(white: 0.12))
    }

    private var exerciseModePicker: some View {
        HStack(spacing: 8) {
            modeButton("Frei", mode: .freePlay, icon: "music.note")
            modeButton("Akkord", mode: .chordPrompt, icon: "questionmark.circle")

            Menu {
                ForEach(state.selectedScaleType == .major
                        ? ProgressionTemplate.allMajor
                        : ProgressionTemplate.allMinor) { prog in
                    Button("\(prog.name) (\(prog.composer))") {
                        onSelectProgression(prog)
                    }
                }
            } label: {
                Label("Progression", systemImage: "list.number")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        state.exercise.mode == .progressionGuide
                        ? Color.accentColor.opacity(0.2)
                        : Color.white.opacity(0.06)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            modeButton("Tonleiter", mode: .scalePractice, icon: "music.note.list")
        }
    }

    private func modeButton(_ title: String, mode: ExerciseMode, icon: String) -> some View {
        Button {
            onSetMode(mode)
        } label: {
            Label(title, systemImage: icon)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .background(state.exercise.mode == mode ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var statsDisplay: some View {
        HStack(spacing: 12) {
            statPill(icon: "flame.fill", value: "\(state.exercise.streak)", color: .orange)
            statPill(icon: "checkmark.circle", value: "\(state.exercise.completedCount)", color: .green)
            if state.exercise.totalSteps > 0 {
                statPill(
                    icon: "chart.bar.fill",
                    value: "\(state.exercise.progressionIndex + 1)/\(state.exercise.totalSteps)",
                    color: .cyan
                )
            }
        }
    }

    private func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Progression Timeline

    private var progressionTimeline: some View {
        Group {
            if state.exercise.mode == .progressionGuide,
               let template = state.exercise.progressionTemplate {
                ProgressionTimelineView(
                    template: template,
                    diatonicChords: state.diatonicChords,
                    currentIndex: state.exercise.progressionIndex,
                    result: state.exercise.result
                )
            } else {
                // Show all 7 diatonic chords as reference
                DiatonicOverviewView(
                    diatonicChords: state.diatonicChords,
                    highlightedDegree: state.diatonicAnalysis?.degree
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 80)
    }

    // MARK: - Chord Feedback

    private var chordFeedback: some View {
        ChordFeedbackView(
            detectedChord: state.detectedChord,
            diatonicAnalysis: state.diatonicAnalysis,
            exercise: state.exercise,
            onAdvance: onAdvance
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Degree Bar

    private var degreeBar: some View {
        DegreeBarView(
            diatonicChords: state.diatonicChords,
            highlightedDegree: state.diatonicAnalysis?.degree,
            exerciseTargetDegree: state.exercise.currentPrompt?.degree
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(white: 0.10))
    }
}

// MARK: - Progression Timeline View

struct ProgressionTimelineView: View {
    let template: ProgressionTemplate
    let diatonicChords: [DiatonicChord]
    let currentIndex: Int
    let result: ExerciseResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Progression header with name, composer, description
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(template.composer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(template.era)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()

                // Harmonic analysis of current step
                if let dc = currentDiatonicChord {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(dc.harmonicFunction.germanName)
                            .font(.caption.bold())
                            .foregroundStyle(DegreeColor.functionColor(for: dc.harmonicFunction))
                        Text(dc.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Chord blocks
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(template.steps.enumerated()), id: \.offset) { index, step in
                        progressionBlock(step: step, index: index)
                    }
                }
            }
        }
    }

    private var currentDiatonicChord: DiatonicChord? {
        guard currentIndex < template.steps.count else { return nil }
        let degree = template.steps[currentIndex].degree
        return diatonicChords[safe: degree - 1]
    }

    private func progressionBlock(step: ProgressionStep, index: Int) -> some View {
        let isCurrent = index == currentIndex
        let isCompleted = index < currentIndex
        let degree = step.degree

        return VStack(spacing: 4) {
            Text(step.label)
                .font(isCurrent ? .title2.bold() : .body)
                .foregroundStyle(.white)

            if let dc = diatonicChords[safe: degree - 1] {
                Text(dc.root.germanName + dc.chordType.quality.symbol)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: isCurrent ? 72 : 56, height: isCurrent ? 64 : 52)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DegreeColor.color(for: degree).opacity(
                    isCompleted ? 0.3 : (isCurrent ? 0.9 : 0.5)
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isCurrent ? feedbackBorderColor : .clear,
                    lineWidth: isCurrent ? 2.5 : 0
                )
        )
        .overlay(alignment: .topTrailing) {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .padding(4)
            }
        }
        .scaleEffect(isCurrent ? 1.0 : 0.92)
        .animation(.easeInOut(duration: 0.2), value: currentIndex)
    }

    private var feedbackBorderColor: Color {
        switch result {
        case .correct: return .green
        case .partial: return .yellow
        case .incorrect: return .red
        case .waiting: return .white.opacity(0.6)
        }
    }
}

// MARK: - Diatonic Overview View

struct DiatonicOverviewView: View {
    let diatonicChords: [DiatonicChord]
    let highlightedDegree: Int?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(diatonicChords, id: \.degree) { dc in
                let isHighlighted = dc.degree == highlightedDegree

                VStack(spacing: 4) {
                    Text(dc.romanNumeral)
                        .font(isHighlighted ? .title2.bold() : .body)
                        .foregroundStyle(.white)
                    Text(dc.root.germanName + dc.chordType.quality.symbol)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(dc.functionLabel)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .frame(height: isHighlighted ? 68 : 56)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DegreeColor.color(for: dc.degree).opacity(isHighlighted ? 0.9 : 0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isHighlighted ? .white : .clear, lineWidth: isHighlighted ? 2 : 0)
                )
                .scaleEffect(isHighlighted ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: highlightedDegree)
            }
        }
    }
}

// MARK: - Chord Feedback View

struct ChordFeedbackView: View {
    let detectedChord: Chord?
    let diatonicAnalysis: DiatonicChord?
    let exercise: ExerciseState
    let onAdvance: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // Left: detected chord display
            detectedChordDisplay

            Divider().frame(height: 50)

            // Center: exercise prompt + result
            if let prompt = exercise.currentPrompt {
                exercisePromptDisplay(prompt: prompt)
            } else if exercise.mode == .freePlay {
                freePlayInfo
            }

            Spacer()

            // Right: advance button (for progression/scale modes)
            if exercise.result == .correct && exercise.mode != .freePlay {
                Button(action: onAdvance) {
                    Label("Weiter", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
    }

    private var detectedChordDisplay: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let chord = detectedChord {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(chord.germanDisplayName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    if chord.inversion != .root {
                        Text(inversionLabel(chord.inversion))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                if let analysis = diatonicAnalysis {
                    HStack(spacing: 8) {
                        Text(analysis.romanNumeral)
                            .font(.title3.bold())
                            .foregroundStyle(DegreeColor.color(for: analysis.degree))

                        Text(analysis.harmonicFunction.germanName)
                            .font(.caption)
                            .foregroundStyle(DegreeColor.functionColor(for: analysis.harmonicFunction))

                        Text("(\(analysis.functionLabel))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if detectedChord != nil {
                    Text("Nicht-diatonisch")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                Text("--")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("Spiele einen Akkord")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 180, alignment: .leading)
    }

    private func exercisePromptDisplay(prompt: ExercisePrompt) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(prompt.instruction)
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                resultBadge
                resultText
            }
        }
        .frame(minWidth: 240, alignment: .leading)
    }

    private var freePlayInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Freies Spielen")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            Text("Akkorde werden automatisch erkannt")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var resultBadge: some View {
        Group {
            switch exercise.result {
            case .correct:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            case .partial:
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(.yellow)
                    .font(.title2)
            case .incorrect:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title2)
            case .waiting:
                Image(systemName: "hourglass")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
        }
    }

    private var resultText: some View {
        Group {
            switch exercise.result {
            case .correct:
                Text("Korrekt!")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            case .partial:
                Text("Teilweise richtig...")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
            case .incorrect:
                Text("Falsch - versuche es nochmal")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            case .waiting:
                Text("Warte auf Eingabe...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func inversionLabel(_ inversion: Inversion) -> String {
        switch inversion {
        case .root: return ""
        case .first: return "1. Umk."
        case .second: return "2. Umk."
        case .third: return "3. Umk."
        }
    }
}

// MARK: - Degree Bar View

struct DegreeBarView: View {
    let diatonicChords: [DiatonicChord]
    let highlightedDegree: Int?
    let exerciseTargetDegree: Int?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(diatonicChords, id: \.degree) { dc in
                let isPlaying = dc.degree == highlightedDegree
                let isTarget = dc.degree == exerciseTargetDegree

                VStack(spacing: 2) {
                    Text(dc.functionLabel)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(DegreeColor.functionColor(for: dc.harmonicFunction).opacity(0.8))

                    Text(dc.romanNumeral)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(dc.root.germanName)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DegreeColor.color(for: dc.degree).opacity(isPlaying ? 0.7 : 0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isTarget ? .white.opacity(0.8) : (isPlaying ? DegreeColor.color(for: dc.degree) : .clear),
                            lineWidth: isTarget ? 2 : (isPlaying ? 1.5 : 0),
                            antialiased: true
                        )
                )
            }
        }
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
