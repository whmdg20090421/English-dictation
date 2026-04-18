import React, { useMemo } from 'react';
import { View, Text, ScrollView, Alert } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useAppStore } from '../../store/useAppStore';
import { useDictationStore } from '../../store/useDictationStore';
import { AppLayout } from '../../components/layout/AppLayout';
import { GlassCard } from '../../components/ui/GlassCard';
import { Button } from '../../components/ui/Button';
import { Word } from '../../types/models';
import { RootStackParamList } from '../../types';

type Props = NativeStackScreenProps<RootStackParamList, 'MistakeBook'>;

export function MistakeBookScreen({ navigation }: Props) {
  const { currentAccountId, accounts, vocab } = useAppStore();
  const { startTest } = useDictationStore();
  
  const stats = accounts[currentAccountId]?.stats || {};

  const mistakeWords = useMemo(() => {
    const wrongWords = Object.keys(stats).filter(w => stats[w].wrong > 0);
    const result: Word[] = [];

    wrongWords.forEach(wStr => {
      let found = false;
      for (const bookName in vocab) {
        for (const unitName in vocab[bookName]) {
          const unit = vocab[bookName][unitName];
          const match = Object.values(unit).find(w => w.单词 === wStr);
          if (match) {
            result.push({ ...match, source_book: bookName, _ask_pos: unitName });
            found = true;
            break;
          }
        }
        if (found) break;
      }
      if (!found) {
        result.push({ 单词: wStr, _uid: `mock_${wStr}` });
      }
    });

    return result;
  }, [stats, vocab]);

  const handleReviewTest = () => {
    if (mistakeWords.length === 0) {
      Alert.alert('提示', '当前没有错词');
      return;
    }
    
    startTest(mistakeWords, 'review', {
      perQTime: accounts[currentAccountId]?.settings?.per_q_time || 20,
      totalTime: mistakeWords.length * (accounts[currentAccountId]?.settings?.per_q_time || 20),
      qTimeLeft: accounts[currentAccountId]?.settings?.per_q_time || 20,
      totLeft: mistakeWords.length * (accounts[currentAccountId]?.settings?.per_q_time || 20),
      allowBackward: accounts[currentAccountId]?.settings?.allow_backward ?? true,
      allowHint: accounts[currentAccountId]?.settings?.allow_hint ?? false,
    });

    navigation.navigate('ActiveTest');
  };

  return (
    <AppLayout>
      <View className="flex-1 p-6 mt-8">
        <View className="flex-row justify-between items-center mb-6">
          <Text className="text-2xl font-bold text-white">错题本</Text>
          <Button title="返回" variant="glass" onPress={() => navigation.goBack()} />
        </View>

        <GlassCard intensity={30} className="p-6 mb-4 flex-row justify-between items-center">
          <View>
            <Text className="text-gray-300">总错词数</Text>
            <Text className="text-3xl font-extrabold text-red-400">{mistakeWords.length}</Text>
          </View>
          <Button 
            title="生成复习测验" 
            variant="primary" 
            onPress={handleReviewTest} 
            disabled={mistakeWords.length === 0}
          />
        </GlassCard>

        <ScrollView className="flex-1" showsVerticalScrollIndicator={false}>
          {mistakeWords.length === 0 ? (
            <Text className="text-gray-400 text-center py-8">太棒了，没有错题！</Text>
          ) : (
            mistakeWords.map((word, index) => {
              const stat = stats[word.单词];
              return (
                <GlassCard key={index} intensity={20} className="p-4 mb-3 flex-row justify-between items-center">
                  <View className="flex-1">
                    <Text className="text-white text-lg font-bold">{word.单词}</Text>
                    {word.source_book && (
                      <Text className="text-gray-400 text-xs mt-1">来源: {word.source_book} &gt; {word._ask_pos}</Text>
                    )}
                  </View>
                  <View className="items-end">
                    <Text className="text-red-400 text-sm">错误次数: {stat.wrong}</Text>
                    <Text className="text-green-400 text-sm">正确次数: {stat.correct}</Text>
                  </View>
                </GlassCard>
              );
            })
          )}
        </ScrollView>
      </View>
    </AppLayout>
  );
}