import AsyncStorage from '@react-native-async-storage/async-storage';
import { useCallback, useEffect, useState } from 'react';
import { newSegment } from '@/lib/helpers';
import type { Segment, Travelers, Trip } from '@/types';

const STORAGE_KEY = '@myvoyage/current-trip/v1';

const defaultTrip = (): Trip => ({
  id: 'current',
  name: 'Meine Traumreise',
  travelers: { adults: 2, children: [] },
  segments: [
    newSegment({ type: 'flight', from: 'Berlin', to: 'Barcelona', date: '2026-06-01' }),
    newSegment({ type: 'hotel', from: '', to: 'Barcelona', date: '2026-06-01' }),
    newSegment({ type: 'car', from: 'Barcelona', to: 'Valencia', date: '2026-06-04' }),
    newSegment({ type: 'train', from: 'Valencia', to: 'Madrid', date: '2026-06-07' }),
  ],
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
});

/**
 * Single-trip store. Persists to AsyncStorage on every mutation.
 *
 * For a multi-trip future, swap the storage key for an indexed structure
 * (`@myvoyage/trips/{id}`) and add list/select operations.
 */
export function useTrip() {
  const [trip, setTrip] = useState<Trip | null>(null);
  const [loaded, setLoaded] = useState(false);

  // Hydrate from storage on mount
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const raw = await AsyncStorage.getItem(STORAGE_KEY);
        if (cancelled) return;
        if (raw) {
          setTrip(JSON.parse(raw) as Trip);
        } else {
          setTrip(defaultTrip());
        }
      } catch (err) {
        console.warn('[MyVoyage] failed to load trip', err);
        if (!cancelled) setTrip(defaultTrip());
      } finally {
        if (!cancelled) setLoaded(true);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  // Persist on every change
  useEffect(() => {
    if (!loaded || !trip) return;
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(trip)).catch((err) =>
      console.warn('[MyVoyage] failed to persist trip', err),
    );
  }, [trip, loaded]);

  const update = useCallback((patch: Partial<Trip>) => {
    setTrip((prev) =>
      prev ? { ...prev, ...patch, updatedAt: new Date().toISOString() } : prev,
    );
  }, []);

  const setName = useCallback(
    (name: string) => update({ name }),
    [update],
  );

  const setTravelers = useCallback(
    (travelers: Travelers) => update({ travelers }),
    [update],
  );

  const addSegment = useCallback(() => {
    setTrip((prev) =>
      prev
        ? {
            ...prev,
            segments: [...prev.segments, newSegment()],
            updatedAt: new Date().toISOString(),
          }
        : prev,
    );
  }, []);

  const removeSegment = useCallback((id: string) => {
    setTrip((prev) =>
      prev
        ? {
            ...prev,
            segments: prev.segments.filter((s) => s.id !== id),
            updatedAt: new Date().toISOString(),
          }
        : prev,
    );
  }, []);

  const updateSegment = useCallback((id: string, patch: Partial<Segment>) => {
    setTrip((prev) =>
      prev
        ? {
            ...prev,
            segments: prev.segments.map((s) =>
              s.id === id ? { ...s, ...patch } : s,
            ),
            updatedAt: new Date().toISOString(),
          }
        : prev,
    );
  }, []);

  const reset = useCallback(() => {
    setTrip(defaultTrip());
  }, []);

  return {
    trip,
    loaded,
    setName,
    setTravelers,
    addSegment,
    removeSegment,
    updateSegment,
    reset,
  };
}
