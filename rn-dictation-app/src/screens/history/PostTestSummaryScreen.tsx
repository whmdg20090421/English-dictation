import React from 'react';
import { View, Text, ScrollView } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useDictationStore } from '../../store/useDictationStore';
import { useAppStore } from '../../store/useAppStore';
import { AppLayout } from '../../components/layout/AppLayout';
import { GlassCard } from '../../components/ui/GlassCard';
import { Button } from '../../components/ui/Button';
import { RootStackParamList } from '../../types';

type Props = NativeStackScreenProps<RootStackParamList, 'PostTestSummary'>;

export function PostTestSummaryScreen({ navigation }: Props) {
  const { testQueue, userAnswers, resetTest } = useDictationStore();
  const { currentAccountId, accounts } = useAppStore();

  const historyList = accounts[currentAccountId]?.history || [];
  const latestHistory = historyList[historyList.length - 1]; // The one just added in ActiveTestScreen

  const total = testQueue.length;
  const score = latestHistory ? latestHistory.score : 0;
  const correctCount = latestHistory ? latestHistory.correct : 0;

  const handleGoHome = () => {
    resetTest();
    navigation.replace('Home');
  };

  return (
    <AppLayout>
      <View className="flex-1 p-6 mt-8">
        <GlassCard intensity={30} className="p-6 mb-4 items-center">
          <Text className="text-2xl font-bold text-white mb-2">测试结果总结</Text>
          <Text className="text-4xl font-extrabold text-blue-400 my-4">{score} 分</Text>
          <View className="flex-row gap-x-6">
            <Text className="text-gray-300">总题数: {total}</Text>
            <Text className="text-green-400">正确: {correctCount}</Text>
            <Text className="text-red-400">错误: {total - correctCount}</Text>
          </View>
        </GlassCard>

        <ScrollView className="flex-1 mb-4" showsVerticalScrollIndicator={false}>
          <Text className="text-lg font-bold text-white mb-3">答题详情</Text>
          {testQueue.map((q, index) => {
            const answer = userAnswers[index];
            const isCorrect = answer?.correct ?? false;
            return (
              <GlassCard key={index} intensity={20} className="p-4 mb-3 flex-row items-center justify-between">
                <View className="flex-1">
                  <Text className="text-white text-lg font-bold">{q.单词}</Text>
                  {answer?.user_input && (
                    <Text className={`text-sm mt-1 ${isCorrect ? 'text-green-300' : 'text-red-300'}`}>
                      你的答案: {answer.user_input}
                    </Text>
                  )}
                  <Text className="text-gray-400 text-xs mt-1">用时: {answer?.time_spent || 0}s</Text>
                </View>
                <View className="items-end">
                  <Text className={`font-bold text-lg ${isCorrect ? 'text-green-400' : 'text-red-400'}`}>
                    {isCorrect ? '✔ 正确' : '✘ 错误'}
                  </Text>
                  <Text className="text-blue-300 text-xs mt-1">得分: {answer?.score_val || 0}</Text>
                </View>
              </GlassCard>
            );
          })}
        </ScrollView>

        <Button title="返回首页" variant="primary" onPress={handleGoHome} className="mb-4" />
      </View>
    </AppLayout>
  );
}