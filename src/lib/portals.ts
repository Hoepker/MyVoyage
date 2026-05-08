import type { BookingPortal, TransportType, Travelers } from '@/types';

/**
 * Encode date for Skyscanner path: expects YYMMDD, not YYYYMMDD.
 * Returns empty string if no valid date.
 */
function skyscannerDate(iso: string): string {
  if (!iso || !/^\d{4}-\d{2}-\d{2}$/.test(iso)) return '';
  return iso.slice(2).replace(/-/g, '');
}

/**
 * Skyscanner distinguishes infants (<2y) from children (2–11).
 * The prototype lumped both into `children`, which makes deeplinks fail.
 */
function splitInfantsAndChildren(travelers: Travelers): {
  infants: number[];
  children: number[];
} {
  const infants: number[] = [];
  const children: number[] = [];
  for (const age of travelers.children) {
    if (age < 2) infants.push(age);
    else children.push(age);
  }
  return { infants, children };
}

export const BOOKING_PORTALS: Record<TransportType, BookingPortal[]> = {
  flight: [
    {
      name: 'Skyscanner',
      url: (f, t, d, tr) => {
        const { infants, children } = splitInfantsAndChildren(tr);
        const base = `https://www.skyscanner.de/transport/flights/${encodeURIComponent(
          f,
        )}/${encodeURIComponent(t)}/${skyscannerDate(d)}/`;
        const params = new URLSearchParams({
          adults: String(tr.adults),
          children: String(children.length),
          infants: String(infants.length),
        });
        if (children.length) params.set('childrenAges', children.join(','));
        return `${base}?${params.toString()}`;
      },
    },
    {
      name: 'Google Flights',
      url: (f, t, d, tr) =>
        `https://www.google.de/travel/flights?q=${encodeURIComponent(
          `Flights from ${f} to ${t} on ${d}`,
        )}&adults=${tr.adults}&children=${tr.children.length}`,
    },
    {
      name: 'Expedia',
      url: (f, t, d, tr) => {
        const passengers = `adults:${tr.adults}${tr.children
          .map((a) => `,child:${a}`)
          .join('')}`;
        const params = new URLSearchParams({
          trip: 'oneway',
          passengers,
          leg1: `from:${f},to:${t},departure:${d}`,
        });
        return `https://www.expedia.de/Flights-Search?${params.toString()}`;
      },
    },
  ],

  train: [
    {
      name: 'DB Bahn',
      url: (f, t, d, tr) => {
        // The newer bahn.de search uses query params, much more reliable
        // than the legacy hash-based deeplink in the prototype.
        const params = new URLSearchParams({
          soid: `A=1@L=${f}`,
          zoid: `A=1@L=${t}`,
          hd: d ? `${d}T08:00:00` : '',
          adults: String(tr.adults),
          children: String(tr.children.length),
        });
        return `https://www.bahn.de/buchung/fahrplan/suche#${params.toString()}`;
      },
    },
    {
      name: 'Omio',
      url: (f, t, d, tr) => {
        const params = new URLSearchParams({
          date: d,
          adults: String(tr.adults),
          children: String(tr.children.length),
        });
        return `https://www.omio.de/trains/${encodeURIComponent(
          f,
        )}-${encodeURIComponent(t)}?${params.toString()}`;
      },
    },
  ],

  car: [
    {
      name: 'Rentalcars',
      url: (f, _t, d) => {
        const params = new URLSearchParams({
          pickUpPlace: f,
          puDay: d,
          driverAge: '30',
        });
        return `https://www.rentalcars.com/de/search/?${params.toString()}`;
      },
    },
    {
      name: 'Booking.com',
      url: (f, _t, d) => {
        const params = new URLSearchParams({
          pickup_location: f,
          pickup_date: d,
        });
        return `https://www.booking.com/cars/search.de.html?${params.toString()}`;
      },
    },
  ],

  bus: [
    {
      name: 'FlixBus',
      url: (f, t, d, tr) => {
        const params = new URLSearchParams({
          departureDate: d,
          adult: String(tr.adults),
          children: String(tr.children.length),
        });
        return `https://global.flixbus.com/bus-tickets/${encodeURIComponent(
          f,
        )}-${encodeURIComponent(t)}?${params.toString()}`;
      },
    },
    {
      name: 'Omio',
      url: (f, t, d, tr) => {
        const params = new URLSearchParams({
          date: d,
          adults: String(tr.adults),
          children: String(tr.children.length),
        });
        return `https://www.omio.de/buses/${encodeURIComponent(
          f,
        )}-${encodeURIComponent(t)}?${params.toString()}`;
      },
    },
  ],

  hotel: [
    {
      name: 'Booking.com',
      url: (_f, t, d, tr) => {
        const params = new URLSearchParams({
          ss: t,
          checkin: d,
          group_adults: String(tr.adults),
          group_children: String(tr.children.length),
        });
        tr.children.forEach((age, i) => params.set(`age[${i}]`, String(age)));
        return `https://www.booking.com/searchresults.de.html?${params.toString()}`;
      },
    },
    {
      name: 'Expedia',
      url: (_f, t, d, tr) => {
        const params = new URLSearchParams({
          destination: t,
          startDate: d,
          adults: String(tr.adults),
          children: String(tr.children.length),
        });
        return `https://www.expedia.de/Hotel-Search?${params.toString()}`;
      },
    },
    {
      name: 'Hotels.com',
      url: (_f, t, d, tr) => {
        const params = new URLSearchParams({
          'q-destination': t,
          'q-check-in': d,
          'q-rooms': '1',
          'q-room-0-adults': String(tr.adults),
          'q-room-0-children': String(tr.children.length),
        });
        return `https://de.hotels.com/search.do?${params.toString()}`;
      },
    },
  ],
};
