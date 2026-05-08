import { StyleSheet, Text, View } from 'react-native';
import { TRANSPORT_TYPES, theme } from '@/constants';
import { SegmentCard } from './SegmentCard';
import type { Segment, Travelers } from '@/types';

interface Props {
  segments: Segment[];
  travelers: Travelers;
  onUpdate: (id: string, patch: Partial<Segment>) => void;
  onRemove: (id: string) => void;
}

export function Timeline({ segments, travelers, onUpdate, onRemove }: Props) {
  if (segments.length === 0) {
    return (
      <View style={styles.empty}>
        <Text style={styles.emptyIcon}>🗺️</Text>
        <Text style={styles.emptyText}>
          Noch keine Etappen – füge deine erste hinzu!
        </Text>
      </View>
    );
  }

  return (
    <View>
      {segments.map((seg, i) => {
        const meta = TRANSPORT_TYPES.find((t) => t.id === seg.type);
        return (
          <View key={seg.id} style={styles.row}>
            <View style={styles.gutter}>
              <View
                style={[
                  styles.dot,
                  {
                    backgroundColor: (meta?.color ?? '#888') + '22',
                    borderColor: (meta?.color ?? '#888') + '55',
                  },
                ]}
              >
                <Text style={styles.dotIcon}>{meta?.icon}</Text>
              </View>
              {i < segments.length - 1 && <View style={styles.line} />}
            </View>
            <SegmentCard
              segment={seg}
              travelers={travelers}
              onChange={(patch) => onUpdate(seg.id, patch)}
              onRemove={() => onRemove(seg.id)}
            />
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
  },
  gutter: {
    width: 44,
    alignItems: 'center',
    paddingTop: 16,
  },
  dot: {
    width: 36,
    height: 36,
    borderRadius: 18,
    borderWidth: 2,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dotIcon: { fontSize: 14 },
  line: {
    flex: 1,
    width: 2,
    backgroundColor: 'rgba(255,255,255,0.06)',
    marginVertical: 4,
    minHeight: 20,
  },
  empty: {
    alignItems: 'center',
    paddingVertical: 48,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 12,
  },
  emptyText: {
    color: 'rgba(232,228,217,0.4)',
    fontSize: 14,
  },
});
