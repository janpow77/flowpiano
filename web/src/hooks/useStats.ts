import { useCallback, useEffect, useState } from 'react';

interface Stats {
  totalExercises: number;
  totalCorrect: number;
  longestStreak: number;
  dailyStreak: number;
  lastPlayedDate: string;
  progressionProgress: Record<string, boolean>;
}

const STORAGE_KEY = 'flowpiano-harmony-stats';

function loadStats(): Stats {
  try {
    const data = localStorage.getItem(STORAGE_KEY);
    if (data) return JSON.parse(data);
  } catch { /* ignore */ }
  return {
    totalExercises: 0,
    totalCorrect: 0,
    longestStreak: 0,
    dailyStreak: 0,
    lastPlayedDate: '',
    progressionProgress: {},
  };
}

function saveStats(stats: Stats): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(stats));
}

export function useStats() {
  const [stats, setStats] = useState<Stats>(loadStats);

  useEffect(() => {
    saveStats(stats);
  }, [stats]);

  const recordExercise = useCallback((correct: boolean) => {
    setStats(prev => {
      const today = new Date().toISOString().slice(0, 10);
      const isConsecutiveDay = prev.lastPlayedDate === new Date(Date.now() - 86400000).toISOString().slice(0, 10);
      const isSameDay = prev.lastPlayedDate === today;

      return {
        ...prev,
        totalExercises: prev.totalExercises + 1,
        totalCorrect: prev.totalCorrect + (correct ? 1 : 0),
        dailyStreak: isSameDay ? prev.dailyStreak : (isConsecutiveDay ? prev.dailyStreak + 1 : 1),
        lastPlayedDate: today,
      };
    });
  }, []);

  const updateStreak = useCallback((streak: number) => {
    setStats(prev => ({
      ...prev,
      longestStreak: Math.max(prev.longestStreak, streak),
    }));
  }, []);

  const markProgressionComplete = useCallback((progressionId: string) => {
    setStats(prev => ({
      ...prev,
      progressionProgress: { ...prev.progressionProgress, [progressionId]: true },
    }));
  }, []);

  const accuracy = stats.totalExercises > 0 ? stats.totalCorrect / stats.totalExercises : 0;

  return { stats, accuracy, recordExercise, updateStreak, markProgressionComplete };
}
