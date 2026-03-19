import { useCallback, useRef, useState } from 'react';
import * as Tone from 'tone';

export type SoundPatch = 'piano' | 'epiano' | 'pad';

const SYNTH_CONFIGS: Record<SoundPatch, () => Tone.PolySynth> = {
  piano: () => new Tone.PolySynth(Tone.AMSynth, {
    harmonicity: 2,
    oscillator: { type: 'square' },
    envelope: { attack: 0.01, decay: 0.3, sustain: 0.4, release: 0.8 },
  }),
  epiano: () => new Tone.PolySynth(Tone.FMSynth, {
    harmonicity: 3.01,
    modulationIndex: 2,
    oscillator: { type: 'sine' },
    envelope: { attack: 0.01, decay: 0.2, sustain: 0.3, release: 1.0 },
    modulation: { type: 'square' },
    modulationEnvelope: { attack: 0.5, decay: 0.0, sustain: 1, release: 0.5 },
  }),
  pad: () => new Tone.PolySynth(Tone.Synth, {
    oscillator: { type: 'sawtooth' },
    envelope: { attack: 0.3, decay: 0.5, sustain: 0.7, release: 2.0 },
  }),
};

export function useAudio() {
  const synthRef = useRef<Tone.PolySynth | null>(null);
  const [patch, setPatchState] = useState<SoundPatch>('piano');
  const [volume, setVolumeState] = useState(0.7);

  const ensureSynth = useCallback(() => {
    if (!synthRef.current) {
      synthRef.current = SYNTH_CONFIGS[patch]();
      synthRef.current.volume.value = Tone.gainToDb(volume);
      synthRef.current.toDestination();
    }
    return synthRef.current;
  }, [patch, volume]);

  const playChord = useCallback(async (midiNotes: number[], duration: string = '2n') => {
    await Tone.start();
    const synth = ensureSynth();
    const freqs = midiNotes.map(n => Tone.Frequency(n, 'midi').toFrequency());
    synth.triggerAttackRelease(freqs, duration);
  }, [ensureSynth]);

  const playNote = useCallback(async (midiNote: number, duration: string = '8n') => {
    await Tone.start();
    const synth = ensureSynth();
    const freq = Tone.Frequency(midiNote, 'midi').toFrequency();
    synth.triggerAttackRelease(freq, duration);
  }, [ensureSynth]);

  const setPatch = useCallback((newPatch: SoundPatch) => {
    if (synthRef.current) {
      synthRef.current.dispose();
      synthRef.current = null;
    }
    setPatchState(newPatch);
  }, []);

  const setVolume = useCallback((vol: number) => {
    setVolumeState(vol);
    if (synthRef.current) {
      synthRef.current.volume.value = Tone.gainToDb(vol);
    }
  }, []);

  return { playChord, playNote, patch, setPatch, volume, setVolume };
}
