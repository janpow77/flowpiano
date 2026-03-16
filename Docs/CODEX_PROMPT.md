# CODEX_PROMPT.md — FlowPiano Implementation Prompt

Use `Docs/AGENTS.md`, `Docs/SPEC.md`, `Docs/ARCHITECTURE.md`, `Docs/TESTING.md`, `Docs/SETUP.md`, and `Docs/RELEASE.md` as binding instructions.

## Task

Implement FlowPiano as a production-oriented macOS application using Swift and SwiftUI.

## Mandatory outcomes

- keep Public Output and Studio Monitor strictly separated
- implement internal piano mode first
- implement persistent layout and calibration
- implement dual camera selection with fallback
- implement a movable / resizable MIDI overlay
- implement a local-only notation layer
- add tests for target visibility and persistence
- add diagnostics and setup flow
- prepare the architecture for virtual camera and virtual mic publication

## Implementation order

1. repository scaffolding
2. core models
3. settings persistence
4. MIDI engine
5. internal piano engine
6. single-camera preview
7. layout engine and target separation
8. notation engine
9. multicam support
10. diagnostics UI
11. virtual camera path
12. virtual mic path
13. tests and polish

## Rule

Never treat the Studio Monitor as just another overlay. It is a separate render target with its own visibility matrix.
