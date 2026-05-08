/**
 * Domain types for MyVoyage.
 * Keep in sync with the booking portal builders in src/lib/portals.ts.
 */

export type TransportType = 'flight' | 'train' | 'car' | 'bus' | 'hotel';

export interface Travelers {
  /** Adults (12+) — at least 1 */
  adults: number;
  /** Children (0–11) with their age at travel start. 0 = infant under 1 year */
  children: number[];
}

export interface Segment {
  id: string;
  type: TransportType;
  from: string;
  to: string;
  /** ISO date string `YYYY-MM-DD`, empty if not yet set */
  date: string;
  note: string;
}

export interface Trip {
  id: string;
  name: string;
  travelers: Travelers;
  segments: Segment[];
  createdAt: string;
  updatedAt: string;
}

export interface TransportTypeMeta {
  id: TransportType;
  label: string;
  icon: string;
  color: string;
}

export interface BookingPortal {
  name: string;
  /** Builds a deeplink URL to the portal's search page */
  url: (
    from: string,
    to: string,
    date: string,
    travelers: Travelers,
  ) => string;
}
