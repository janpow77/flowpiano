import { useCallback, useEffect, useRef, useState } from 'react';

export type SessionDuration = 3 | 5 | 10 | 20;

interface SessionSummary {
  duration: SessionDuration;
  attempted: number;
  correct: number;
  accuracy: number;
}

export function useSessionTimer() {
  const [isActive, setIsActive] = useState(false);
  const [remaining, setRemaining] = useState(0);
  const [duration, setDuration] = useState<SessionDuration>(5);
  const [summary, setSummary] = useState<SessionSummary | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const startStatsRef = useRef({ attempted: 0, correct: 0 });

  const start = useCallback((mins: SessionDuration, currentAttempted: number, currentCorrect: number) => {
    setDuration(mins);
    setRemaining(mins * 60);
    setIsActive(true);
    setSummary(null);
    startStatsRef.current = { attempted: currentAttempted, correct: currentCorrect };
  }, []);

  const stop = useCallback((currentAttempted: number, currentCorrect: number) => {
    setIsActive(false);
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
    const attempted = currentAttempted - startStatsRef.current.attempted;
    const correct = currentCorrect - startStatsRef.current.correct;
    setSummary({
      duration,
      attempted,
      correct,
      accuracy: attempted > 0 ? correct / attempted : 0,
    });
  }, [duration]);

  useEffect(() => {
    if (!isActive) return;

    intervalRef.current = setInterval(() => {
      setRemaining(prev => {
        if (prev <= 1) {
          setIsActive(false);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [isActive]);

  const formatTime = useCallback((seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, '0')}`;
  }, []);

  return { isActive, remaining, duration, summary, start, stop, formatTime, setSummary };
}
