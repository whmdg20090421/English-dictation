import React from 'react';
import { Text, View, ScrollView } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../types';
import { Button } from '../components/ui/Button';
import { AppLayout } from '../components/layout/AppLayout';
import { useAuthStore } from '../store/authStore';
import { VocabManager } from '../components/vocab/VocabManager';

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

export function HomeScreen({ navigation }: Props) {
  const { role, logout } = useAuthStore();

  return (
    <AppLayout>
      <ScrollView contentContainerStyle={{ flexGrow: 1, padding: 24, gap: 24 }}>
        <View className="items-center mb-4 mt-8">
          <Text className="text-3xl font-bold text-white mb-2 text-center">RN Dictation</Text>
          <Text className="text-slate-300 text-base text-center">
            Welcome, {role === 'admin' ? 'Admin' : 'Guest'}
          </Text>
        </View>

        <View className="flex-row gap-x-4 mb-4">
          <Button
            title="历史记录"
            variant="primary"
            className="flex-1"
            onPress={() => navigation.navigate('HistoryList')}
          />
          <Button
            title="错题本"
            variant="primary"
            className="flex-1"
            onPress={() => navigation.navigate('MistakeBook')}
          />
        </View>

        <VocabManager />

        <Button
          title="Logout"
          variant="glass"
          onPress={logout}
          className="mt-4 mb-8"
        />
      </ScrollView>
    </AppLayout>
  );
}
