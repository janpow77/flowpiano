# AGENTS.md — FlowPiano
Version 2.1

This document is binding for Codex and any coding agent working on this repository.

The goal is a production-ready macOS application, not a prototype.

## Product Goal

Build **FlowPiano**, a production-ready macOS application for piano teaching and performance in video conferencing.

FlowPiano must provide:

- a **virtual camera** for conferencing software
- a **virtual microphone** for conferencing software
- two selectable camera inputs
- a movable and resizable MIDI keyboard overlay
- an internal classical piano sound engine
- optional external instrument routing
- clean speech microphone mixing
- a strict separation between:
  - **Public Output** (`Target A`) for the audience
  - **Studio Monitor** (`Target B`) for the local user only

The application must be suitable for real lessons, rehearsals, demonstrations, and live remote teaching sessions.

## Non-Negotiable Rule

No internal-only layer may leak into Target A.
This is the highest test priority.
