import uuid from 'react-native-uuid';
import type { Segment, Travelers } from '@/types';

export function newSegment(partial: Partial<Segment> = {}): Segment {
  return {
    id: String(uuid.v4()),
    type: 'flight',
    from: '',
    to: '',
    date: '',
    note: '',
    ...partial,
  };
}

export function travelerSummary(t: Travelers): string {
  let s = `${t.adults} Erwachsene${t.adults === 1 ? 'r' : ''}`;
  if (t.children.length > 0) {
    s += ` + ${t.children.length} Kind${t.children.length > 1 ? 'er' : ''}`;
    s += ` (${t.children.map((a) => (a === 0 ? '<1' : a)).join(', ')} J.)`;
  }
  return s;
}

export function formatDateDE(iso: string): string {
  if (!iso) return 'Datum nicht gesetzt';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return 'Datum nicht gesetzt';
  return d.toLocaleDateString('de-DE', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  });
}

export function totalTravelers(t: Travelers): number {
  return t.adults + t.children.length;
}
