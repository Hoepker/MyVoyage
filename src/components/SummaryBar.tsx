import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { theme } from '@/constants';
import { totalTravelers } from '@/lib/helpers';
import type { Segment, Travelers } from '@/types';

interface Props {
  segments: Segment[];
  travelers: Travelers;
}

export function SummaryBar({ segments, travelers }: Props) {
  const uniquePlaces = new Set(
    segments.flatMap((s) => [s.from, s.to]).filter(Boolean),
  ).size;
  const flights = segments.filter((s) => s.type === 'flight').length;
  const hotels = segments.filter((s) => s.type === 'hotel').length;

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.container}
    >
      <Item value={totalTravelers(travelers)} label="Reisende" highlight />
      <Item value={travelers.adults} label="Erwachsene" />
      <Item value={travelers.children.length} label="Kinder" />
      <View style={styles.divider} />
      <Item value={segments.length} label="Etappen" />
      <Item value={uniquePlaces} label="Orte" />
      <Item value={flights} label="Flüge" />
      <Item value={hotels} label="Hotels" />
    </ScrollView>
  );
}

function Item({
  value,
  label,
  highlight,
}: {
  value: number;
  label: string;
  highlight?: boolean;
}) {
  return (
    <View style={styles.item}>
      <Text style={[styles.value, highlight && styles.valueHighlight]}>
        {value}
      </Text>
      <Text style={styles.label}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 24,
    paddingHorizontal: 16,
    paddingVertical: 14,
    backgroundColor: 'rgba(255,255,255,0.02)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
    borderRadius: 12,
    marginBottom: 16,
  },
  item: {
    gap: 2,
  },
  value: {
    color: theme.text,
    fontSize: 22,
    fontWeight: '300',
  },
  valueHighlight: {
    color: '#60a5fa',
  },
  label: {
    color: theme.textSubtle,
    fontSize: 10,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  divider: {
    width: 1,
    height: 32,
    backgroundColor: 'rgba(255,255,255,0.06)',
  },
});
