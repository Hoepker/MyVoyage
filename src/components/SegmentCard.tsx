import DateTimePicker from '@react-native-community/datetimepicker';
import { useState } from 'react';
import {
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import * as WebBrowser from 'expo-web-browser';
import { TRANSPORT_TYPES, theme } from '@/constants';
import { BOOKING_PORTALS } from '@/lib/portals';
import { formatDateDE } from '@/lib/helpers';
import type { Segment, Travelers, TransportType } from '@/types';

interface Props {
  segment: Segment;
  travelers: Travelers;
  onChange: (patch: Partial<Segment>) => void;
  onRemove: () => void;
}

export function SegmentCard({ segment, travelers, onChange, onRemove }: Props) {
  const [showNote, setShowNote] = useState(false);
  const [showPortals, setShowPortals] = useState(false);
  const [showDatePicker, setShowDatePicker] = useState(false);

  const portals = BOOKING_PORTALS[segment.type] ?? [];

  const onDateChange = (
    _e: unknown,
    selected?: Date,
  ) => {
    if (Platform.OS === 'android') setShowDatePicker(false);
    if (selected) {
      const iso = selected.toISOString().slice(0, 10);
      onChange({ date: iso });
    }
  };

  const openPortal = async (url: string) => {
    setShowPortals(false);
    try {
      await WebBrowser.openBrowserAsync(url);
    } catch (err) {
      console.warn('[MyVoyage] failed to open portal', err);
    }
  };

  return (
    <View style={styles.card}>
      {/* Type tabs */}
      <View style={styles.typeTabs}>
        {TRANSPORT_TYPES.map((t) => {
          const active = segment.type === t.id;
          return (
            <TouchableOpacity
              key={t.id}
              style={[
                styles.tab,
                active && { backgroundColor: t.color, borderColor: t.color },
              ]}
              onPress={() => onChange({ type: t.id as TransportType })}
            >
              <Text
                style={[styles.tabText, active && styles.tabTextActive]}
              >
                {t.icon} {t.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {/* Actions */}
      <View style={styles.actions}>
        <TouchableOpacity
          style={styles.bookBtn}
          onPress={() => setShowPortals(true)}
        >
          <Text style={styles.bookBtnText}>Buchen ↗</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.iconBtn} onPress={onRemove}>
          <Text style={styles.iconBtnText}>✕</Text>
        </TouchableOpacity>
      </View>

      {/* Fields */}
      <View style={styles.fields}>
        {segment.type !== 'hotel' && (
          <Field label="Von">
            <TextInput
              style={styles.input}
              placeholder="z.B. Berlin"
              placeholderTextColor="rgba(232,228,217,0.18)"
              value={segment.from}
              onChangeText={(v) => onChange({ from: v })}
            />
          </Field>
        )}
        <Field label={segment.type === 'hotel' ? 'Ort' : 'Nach'}>
          <TextInput
            style={styles.input}
            placeholder="z.B. Paris"
            placeholderTextColor="rgba(232,228,217,0.18)"
            value={segment.to}
            onChangeText={(v) => onChange({ to: v })}
          />
        </Field>
        <Field label="Datum">
          <TouchableOpacity
            style={styles.input}
            onPress={() => setShowDatePicker(true)}
          >
            <Text
              style={[
                styles.inputText,
                !segment.date && styles.inputPlaceholder,
              ]}
            >
              {segment.date ? formatDateDE(segment.date) : 'Datum wählen'}
            </Text>
          </TouchableOpacity>
        </Field>
      </View>

      {showDatePicker && (
        <DateTimePicker
          value={segment.date ? new Date(segment.date) : new Date()}
          mode="date"
          display={Platform.OS === 'ios' ? 'inline' : 'default'}
          themeVariant="dark"
          onChange={onDateChange}
        />
      )}

      {/* Notes toggle */}
      <TouchableOpacity onPress={() => setShowNote(!showNote)}>
        <Text style={styles.noteToggle}>
          {showNote ? '▾ Notiz ausblenden' : '＋ Notiz hinzufügen'}
        </Text>
      </TouchableOpacity>

      {showNote && (
        <TextInput
          style={styles.noteInput}
          multiline
          numberOfLines={3}
          placeholder="Hinweise, Präferenzen, Buchungsnummern..."
          placeholderTextColor="rgba(232,228,217,0.15)"
          value={segment.note}
          onChangeText={(v) => onChange({ note: v })}
        />
      )}

      {/* Portal modal */}
      <Modal
        visible={showPortals}
        transparent
        animationType="fade"
        onRequestClose={() => setShowPortals(false)}
      >
        <Pressable
          style={styles.modalBackdrop}
          onPress={() => setShowPortals(false)}
        >
          <Pressable
            style={styles.modalSheet}
            onPress={(e) => e.stopPropagation()}
          >
            <Text style={styles.modalTitle}>Wo möchtest du buchen?</Text>
            {portals.map((p) => (
              <TouchableOpacity
                key={p.name}
                style={styles.portalItem}
                onPress={() =>
                  openPortal(p.url(segment.from, segment.to, segment.date, travelers))
                }
              >
                <Text style={styles.portalName}>{p.name}</Text>
                <Text style={styles.portalArrow}>→</Text>
              </TouchableOpacity>
            ))}
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{label}</Text>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    backgroundColor: theme.surface,
    borderWidth: 1,
    borderColor: theme.border,
    borderRadius: 12,
    padding: 16,
    marginVertical: 6,
    marginLeft: 12,
  },
  typeTabs: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginBottom: 12,
  },
  tab: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    backgroundColor: 'transparent',
  },
  tabText: {
    color: theme.textMuted,
    fontSize: 12,
  },
  tabTextActive: {
    color: '#0a0a0f',
    fontWeight: '600',
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 8,
    marginBottom: 12,
  },
  bookBtn: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.12)',
    backgroundColor: 'rgba(255,255,255,0.05)',
  },
  bookBtnText: {
    color: 'rgba(232,228,217,0.7)',
    fontSize: 12,
  },
  iconBtn: {
    width: 30,
    height: 30,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconBtnText: {
    color: 'rgba(232,228,217,0.4)',
    fontSize: 13,
  },
  fields: {
    gap: 10,
  },
  field: {
    gap: 4,
  },
  fieldLabel: {
    color: theme.textSubtle,
    fontSize: 11,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  input: {
    backgroundColor: 'rgba(255,255,255,0.04)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    color: theme.text,
    fontSize: 14,
  },
  inputText: { color: theme.text, fontSize: 14 },
  inputPlaceholder: { color: 'rgba(232,228,217,0.18)' },
  noteToggle: {
    color: theme.textSubtle,
    fontSize: 12,
    marginTop: 12,
  },
  noteInput: {
    marginTop: 8,
    backgroundColor: 'rgba(255,255,255,0.03)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.06)',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    color: 'rgba(232,228,217,0.7)',
    fontSize: 13,
    minHeight: 60,
    textAlignVertical: 'top',
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalSheet: {
    backgroundColor: theme.surfaceElevated,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 20,
    paddingBottom: 40,
  },
  modalTitle: {
    color: theme.text,
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 16,
  },
  portalItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 14,
    paddingHorizontal: 12,
    borderRadius: 8,
    backgroundColor: 'rgba(255,255,255,0.03)',
    marginBottom: 8,
  },
  portalName: { color: theme.text, fontSize: 15 },
  portalArrow: { color: theme.accent, fontSize: 16 },
});
