import { useState } from 'react';
import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { theme } from '@/constants';
import type { Travelers } from '@/types';

interface Props {
  travelers: Travelers;
  onChange: (t: Travelers) => void;
}

export function TravelersSelector({ travelers, onChange }: Props) {
  const [open, setOpen] = useState(false);

  const total = travelers.adults + travelers.children.length;
  const label =
    travelers.children.length === 0
      ? `${travelers.adults} Erwachsene${travelers.adults === 1 ? 'r' : ''}`
      : `${travelers.adults} Erw. · ${travelers.children.length} Kind${
          travelers.children.length > 1 ? 'er' : ''
        }`;

  const setAdults = (n: number) =>
    onChange({ ...travelers, adults: Math.max(1, Math.min(9, n)) });

  const addChild = () => {
    if (travelers.children.length < 8) {
      onChange({ ...travelers, children: [...travelers.children, 5] });
    }
  };

  const removeChild = () => {
    if (travelers.children.length > 0) {
      onChange({
        ...travelers,
        children: travelers.children.slice(0, -1),
      });
    }
  };

  const cycleChildAge = (i: number) => {
    const c = [...travelers.children];
    const current = c[i] ?? 0;
    c[i] = (current + 1) % 18;
    onChange({ ...travelers, children: c });
  };

  return (
    <>
      <TouchableOpacity
        style={[styles.btn, open && styles.btnOpen]}
        onPress={() => setOpen(true)}
        activeOpacity={0.7}
      >
        <Text style={styles.btnIcon}>👥</Text>
        <Text style={styles.btnLabel}>{label}</Text>
        <View style={styles.badge}>
          <Text style={styles.badgeText}>{total}</Text>
        </View>
      </TouchableOpacity>

      <Modal
        visible={open}
        transparent
        animationType="fade"
        onRequestClose={() => setOpen(false)}
      >
        <Pressable style={styles.backdrop} onPress={() => setOpen(false)}>
          <Pressable style={styles.sheet} onPress={(e) => e.stopPropagation()}>
            <View style={styles.sheetHeader}>
              <Text style={styles.sheetTitle}>Reisende</Text>
              <TouchableOpacity onPress={() => setOpen(false)}>
                <Text style={styles.closeBtn}>✕</Text>
              </TouchableOpacity>
            </View>

            <ScrollView>
              <View style={styles.row}>
                <View>
                  <Text style={styles.rowLabel}>Erwachsene</Text>
                  <Text style={styles.rowSub}>Ab 12 Jahren</Text>
                </View>
                <View style={styles.controls}>
                  <CounterBtn
                    onPress={() => setAdults(travelers.adults - 1)}
                    disabled={travelers.adults <= 1}
                    label="−"
                  />
                  <Text style={styles.value}>{travelers.adults}</Text>
                  <CounterBtn
                    onPress={() => setAdults(travelers.adults + 1)}
                    disabled={travelers.adults >= 9}
                    label="+"
                  />
                </View>
              </View>

              <View style={styles.row}>
                <View>
                  <Text style={styles.rowLabel}>Kinder</Text>
                  <Text style={styles.rowSub}>Bis 11 Jahre</Text>
                </View>
                <View style={styles.controls}>
                  <CounterBtn
                    onPress={removeChild}
                    disabled={travelers.children.length === 0}
                    label="−"
                  />
                  <Text style={styles.value}>{travelers.children.length}</Text>
                  <CounterBtn
                    onPress={addChild}
                    disabled={travelers.children.length >= 8}
                    label="+"
                  />
                </View>
              </View>

              {travelers.children.length > 0 && (
                <View style={styles.agesSection}>
                  <Text style={styles.agesTitle}>
                    Alter der Kinder bei Reiseantritt
                  </Text>
                  <View style={styles.chips}>
                    {travelers.children.map((age, i) => (
                      <TouchableOpacity
                        // eslint-disable-next-line react/no-array-index-key
                        key={i}
                        style={styles.chip}
                        onPress={() => cycleChildAge(i)}
                      >
                        <Text style={styles.chipLabel}>Kind {i + 1}</Text>
                        <Text style={styles.chipValue}>
                          {age === 0 ? '< 1 J.' : `${age} J.`}
                        </Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                  <Text style={styles.hint}>
                    ℹ️ Tippen zum Ändern. Das Alter beeinflusst Tickets,
                    Kindertarife und Zimmertypen.
                  </Text>
                </View>
              )}
            </ScrollView>
          </Pressable>
        </Pressable>
      </Modal>
    </>
  );
}

function CounterBtn({
  onPress,
  disabled,
  label,
}: {
  onPress: () => void;
  disabled: boolean;
  label: string;
}) {
  return (
    <TouchableOpacity
      onPress={onPress}
      disabled={disabled}
      style={[styles.counterBtn, disabled && styles.counterBtnDisabled]}
    >
      <Text style={styles.counterBtnText}>{label}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  btn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14,
    paddingVertical: 8,
    backgroundColor: 'rgba(255,255,255,0.04)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    borderRadius: 8,
  },
  btnOpen: {
    backgroundColor: theme.accentSoft,
    borderColor: 'rgba(59,130,246,0.4)',
  },
  btnIcon: { fontSize: 14 },
  btnLabel: { color: theme.text, fontSize: 13 },
  badge: {
    backgroundColor: theme.accent,
    borderRadius: 9,
    width: 18,
    height: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '600',
  },
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: theme.surfaceElevated,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 20,
    paddingBottom: 40,
    maxHeight: '80%',
  },
  sheetHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  sheetTitle: {
    color: theme.text,
    fontSize: 18,
    fontWeight: '600',
  },
  closeBtn: {
    color: theme.textMuted,
    fontSize: 18,
    paddingHorizontal: 8,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.05)',
  },
  rowLabel: { color: theme.text, fontSize: 15 },
  rowSub: {
    color: theme.textSubtle,
    fontSize: 12,
    marginTop: 2,
  },
  controls: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  counterBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.12)',
    backgroundColor: 'rgba(255,255,255,0.05)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  counterBtnDisabled: { opacity: 0.2 },
  counterBtnText: {
    color: theme.text,
    fontSize: 18,
    lineHeight: 20,
  },
  value: {
    color: theme.text,
    fontSize: 16,
    fontWeight: '500',
    minWidth: 24,
    textAlign: 'center',
  },
  agesSection: {
    marginTop: 16,
    paddingTop: 16,
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.05)',
  },
  agesTitle: {
    color: theme.textSubtle,
    fontSize: 11,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: 10,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: 'rgba(255,255,255,0.04)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  chipLabel: {
    color: theme.textMuted,
    fontSize: 12,
  },
  chipValue: {
    color: theme.text,
    fontSize: 13,
    fontWeight: '500',
  },
  hint: {
    color: 'rgba(232,228,217,0.35)',
    fontSize: 11,
    marginTop: 12,
    lineHeight: 16,
  },
});
