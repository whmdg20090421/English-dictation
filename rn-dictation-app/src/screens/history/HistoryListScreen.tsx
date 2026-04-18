import React from 'react';
import { View, Text, ScrollView } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useAppStore } from '../../store/useAppStore';
import { AppLayout } from '../../components/layout/AppLayout';
import { GlassCard } from '../../components/ui/GlassCard';
import { Button } from '../../components/ui/Button';
import { RootStackParamList } from '../../types';

type Props = NativeStackScreenProps<RootStackParamList, 'HistoryList'>;

export function HistoryListScreen({ navigation }: Props) {
  const { currentAccountId, accounts } = useAppStore();
  
  const history = accounts[currentAccountId]?.history || [];

  return (
    <AppLayout>
      <View className="flex-1 p-6 mt-8">
        <View className="flex-row justify-between items-center mb-6">
          <Text className="text-2xl font-bold text-white">历史记录</Text>
          <Button title="返回" variant="glass" onPress={() => navigation.goBack()} />
        </View>

        <ScrollView className="flex-1" showsVerticalScrollIndicator={false}>
          {history.length === 0 ? (
            <Text className="text-gray-400 text-center py-8">暂无测验记录</Text>
          ) : (
            history.slice().reverse().map((item, index) => (
              <GlassCard key={index} intensity={20} className="p-4 mb-3">
                <View className="flex-row justify-between items-center mb-2">
                  <Text className="text-white font-bold text-lg">模式: {item.mode}</Text>
                  <Text className="text-blue-400 font-extrabold text-xl">{item.score} 分</Text>
                </View>
                <View className="flex-row justify-between">
                  <Text className="text-gray-300 text-sm">时间: {new Date(item.timestamp).toLocaleString()}</Text>
                  <Text className="text-gray-300 text-sm">
                    正确率: {item.correct}/{item.total}
                  </Text>
                </View>
              </GlassCard>
            ))
          )}
        </ScrollView>
      </View>
    </AppLayout>
  );
}