import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, Switch } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { AppLayout } from '../../components/layout/AppLayout';
import { GlassCard } from '../../components/ui/GlassCard';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { RootStackParamList } from '../../types';
import { useAppStore } from '../../store/useAppStore';
import { useAuthStore } from '../../store/authStore';
import { useDictationStore } from '../../store/useDictationStore';

type Props = NativeStackScreenProps<RootStackParamList, 'TestConfig'>;

export function TestConfigScreen({ route, navigation }: Props) {
  const { bookName, unitName } = route.params;
  const { vocab, accounts, currentAccountId, setCurrentAccountId, updateAccountSettings } = useAppStore();
  const { role } = useAuthStore();
  const { startTest } = useDictationStore();

  const [selectedAccount, setSelectedAccount] = useState(currentAccountId);
  
  // Local settings state based on selected account
  const account = accounts[selectedAccount];
  const [perQTime, setPerQTime] = useState(account?.settings.per_q_time.toString() || '20');
  const [allowHint, setAllowHint] = useState(account?.settings.allow_hint || false);
  const [hintDelay, setHintDelay] = useState(account?.settings.hint_delay.toString() || '5');

  useEffect(() => {
    const acc = accounts[selectedAccount];
    if (acc) {
      setPerQTime(acc.settings.per_q_time.toString());
      setAllowHint(acc.settings.allow_hint);
      setHintDelay(acc.settings.hint_delay.toString());
    }
  }, [selectedAccount, accounts]);

  const handleStartTest = () => {
    const time = parseFloat(perQTime) || 20;
    const delay = parseInt(hintDelay, 10) || 5;

    // Update account settings before starting
    updateAccountSettings(selectedAccount, {
      per_q_time: time,
      allow_hint: allowHint,
      hint_delay: delay
    });

    const wordsObj = vocab[bookName]?.[unitName] || {};
    const wordsList = Object.values(wordsObj);

    if (wordsList.length === 0) {
      alert('This set has no words.');
      return;
    }

    // Set current account ID to the selected one
    setCurrentAccountId(selectedAccount);

    startTest(wordsList, 'dictation', {
      perQTime: time,
      allowHint: allowHint,
      qTimeLeft: time,
      totalTime: time * wordsList.length,
      totLeft: time * wordsList.length
    });

    navigation.replace('ActiveTest');
  };

  return (
    <AppLayout>
      <ScrollView contentContainerStyle={{ flexGrow: 1, padding: 24, gap: 24 }}>
        <View className="mt-8 mb-4">
          <Text className="text-3xl font-bold text-white mb-2">Test Configuration</Text>
          <Text className="text-slate-300 text-base">
            {bookName} {'>'} {unitName}
          </Text>
        </View>

        <GlassCard intensity={30} className="p-6 gap-y-6">
          {role === 'admin' && (
            <View>
              <Text className="text-white font-semibold mb-2 text-lg">Select Account</Text>
              <View className="flex-row flex-wrap gap-2">
                {Object.keys(accounts).map((accId) => (
                  <Button
                    key={accId}
                    title={accounts[accId].name || accId}
                    variant={selectedAccount === accId ? 'primary' : 'glass'}
                    onPress={() => setSelectedAccount(accId)}
                  />
                ))}
              </View>
            </View>
          )}

          <View>
            <Text className="text-white font-semibold mb-2 text-lg">Timer Settings</Text>
            <Input
              label="Time per question (seconds)"
              value={perQTime}
              onChangeText={setPerQTime}
              keyboardType="numeric"
            />
          </View>

          <View>
            <Text className="text-white font-semibold mb-2 text-lg">Hint Settings</Text>
            <View className="flex-row justify-between items-center mb-4 bg-slate-800/50 p-4 rounded-xl">
              <Text className="text-white">Allow Hints</Text>
              <Switch
                value={allowHint}
                onValueChange={setAllowHint}
                trackColor={{ false: '#334155', true: '#3b82f6' }}
                thumbColor={allowHint ? '#ffffff' : '#94a3b8'}
              />
            </View>
            {allowHint && (
              <Input
                label="Hint delay (seconds)"
                value={hintDelay}
                onChangeText={setHintDelay}
                keyboardType="numeric"
              />
            )}
          </View>

          <View className="flex-row gap-x-4 mt-4">
            <Button
              title="Cancel"
              variant="glass"
              className="flex-1"
              onPress={() => navigation.goBack()}
            />
            <Button
              title="Start Test"
              variant="primary"
              className="flex-1"
              onPress={handleStartTest}
            />
          </View>
        </GlassCard>
      </ScrollView>
    </AppLayout>
  );
}
