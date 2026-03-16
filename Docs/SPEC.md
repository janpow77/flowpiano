# SPEC.md — FlowPiano
Version 2.1

## Goal

FlowPiano is a macOS application for piano teaching and performance in videoconferencing.

It combines:

- two configurable camera feeds
- an animated MIDI keyboard overlay
- an internal piano sound engine
- optional external instrument routing
- a virtual camera
- a virtual microphone
- a local-only studio monitor with notation and diagnostics

## Dual Output

### Target A — Public Output
Contains:
- face camera
- keyboard camera
- MIDI keyboard overlay

### Target B — Studio Monitor
Contains:
- everything from Target A
- notation / music staff
- audio meters
- MIDI event log
- latency indicators
- local diagnostics
