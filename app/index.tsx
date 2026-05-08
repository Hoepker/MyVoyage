import {
  ActivityIndicator,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { SummaryBar } from '@/components/SummaryBar';
import { Timeline } from '@/components/Timeline';
import { TravelersSelector } from '@/components/TravelersSelector';
import { theme } from '@/constants';
import { useTrip } from '@/state/useTrip';

export default function HomeScreen() {
  const {
    trip,
    loaded,
    setName,
    setTravelers,
    addSegment,
    removeSegment,
    updateSegment,
  } = useTrip();

  if (!loaded || !trip) {
    return (
      <SafeAreaView style={styles.loading}>
        <ActivityIndicator color={theme.accent} />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerTop}>
          <View>
            <Text style={styles.logo}>
              My<Text style={styles.logoAccent}>Voyage</Text>
            </Text>
            <Text style={styles.tagline}>Individuelle Reiseplanung</Text>
          </View>
          <TravelersSelector
            travelers={trip.travelers}
            onChange={setTravelers}
          />
        </View>
        <TextInput
          style={styles.tripName}
          value={trip.name}
          onChangeText={setName}
          placeholder="Name deiner Reise..."
          placeholderTextColor="rgba(232,228,217,0.2)"
        />
      </View>

      <ScrollView
        contentContainerStyle={styles.scroll}
        keyboardShouldPersistTaps="handled"
      >
        <SummaryBar segments={trip.segments} travelers={trip.travelers} />

        <Text style={styles.sectionTitle}>REISEPLAN</Text>

        <Timeline
          segments={trip.segments}
          travelers={trip.travelers}
          onUpdate={updateSegment}
          onRemove={removeSegment}
        />

        <TouchableOpacity style={styles.addBtn} onPress={addSegment}>
          <Text style={styles.addBtnText}>+ Etappe hinzufügen</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: theme.bg,
  },
  loading: {
    flex: 1,
    backgroundColor: theme.bg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  header: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: 'rgba(255,255,255,0.06)',
    gap: 12,
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  logo: {
    color: theme.text,
    fontSize: 26,
    fontWeight: '700',
    letterSpacing: -0.5,
  },
  logoAccent: { color: theme.accent },
  tagline: {
    color: theme.textSubtle,
    fontSize: 11,
    letterSpacing: 1.5,
    textTransform: 'uppercase',
    marginTop: 2,
  },
  tripName: {
    backgroundColor: 'rgba(255,255,255,0.05)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.1)',
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 10,
    color: theme.text,
    fontSize: 15,
  },
  scroll: {
    padding: 20,
    paddingBottom: 60,
  },
  sectionTitle: {
    color: theme.textSubtle,
    fontSize: 11,
    letterSpacing: 2,
    marginBottom: 12,
  },
  addBtn: {
    marginTop: 16,
    paddingVertical: 14,
    borderRadius: 10,
    borderWidth: 1,
    borderStyle: 'dashed',
    borderColor: 'rgba(255,255,255,0.12)',
    alignItems: 'center',
  },
  addBtnText: {
    color: 'rgba(232,228,217,0.4)',
    fontSize: 14,
  },
});
