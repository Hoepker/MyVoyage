import type { TransportTypeMeta } from '@/types';

export const TRANSPORT_TYPES: readonly TransportTypeMeta[] = [
  { id: 'flight', label: 'Flug', icon: '✈️', color: '#3B82F6' },
  { id: 'train', label: 'Zug', icon: '🚂', color: '#10B981' },
  { id: 'car', label: 'Mietwagen', icon: '🚗', color: '#F59E0B' },
  { id: 'bus', label: 'Bus', icon: '🚌', color: '#8B5CF6' },
  { id: 'hotel', label: 'Hotel', icon: '🏨', color: '#EC4899' },
] as const;

/**
 * Dark-mode theme tokens. Mirrors the original prototype's color palette
 * so the visual identity carries over cleanly.
 */
export const theme = {
  bg: '#0a0a0f',
  surface: 'rgba(255,255,255,0.03)',
  surfaceElevated: '#13131e',
  border: 'rgba(255,255,255,0.07)',
  borderStrong: 'rgba(255,255,255,0.12)',
  text: '#e8e4d9',
  textMuted: 'rgba(232,228,217,0.5)',
  textSubtle: 'rgba(232,228,217,0.3)',
  accent: '#3B82F6',
  accentSoft: 'rgba(59,130,246,0.1)',
  danger: '#ef4444',
} as const;

export const fonts = {
  serif: 'PlayfairDisplay_700Bold',
  sans: 'DMSans_400Regular',
  sansMedium: 'DMSans_500Medium',
} as const;
