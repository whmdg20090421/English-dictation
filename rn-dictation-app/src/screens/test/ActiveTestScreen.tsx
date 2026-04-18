import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, TextInput, TouchableOpacity, Alert } from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import * as Speech from 'expo-speech';
import { AppLayout } from '../../components/layout/AppLayout';
import { GlassCard } from '../../components/ui/GlassCard';
import { Button } from '../../components/ui/Button';
import { RootStackParamList } from '../../types';
import { useDictationStore } from '../../store/useDictationStore';
import { useAppStore } from '../../store/useAppStore';

type Props = NativeStackScreenProps<RootStackParamList, 'ActiveTest'>;

export function ActiveTestScreen({ navigation }: Props) {
  const {
    testQueue,
    currentQIndex,
    perQTime,
    allowHint,
    submitAnswer,
    nextQuestion,
    resetTest,
  } = useDictationStore();

  const { currentAccountId, updateWordStats, addHistory, getCurrentAccount } = useAppStore();

  const currentWord = testQueue[currentQIndex];
  const totalQuestions = testQueue.length;

  const [input, setInput] = useState('');
  const [timeLeft, setTimeLeft] = useState(perQTime);
  const [hint, setHint] = useState<string | null>(null);
  
  const account = getCurrentAccount();
  const hintDelay = account?.settings.hint_delay || 5;

  const playWord = useCallback(() => {
    if (currentWord?.单词) {
      Speech.speak(currentWord.单词, { language: 'en-US', rate: 0.8 });
    }
  }, [currentWord]);

  useEffect(() => {
    if (currentWord) {
      playWord();
      setInput('');
      setTimeLeft(perQTime);
      setHint(null);
    }
  }, [currentQIndex, currentWord, playWord, perQTime]);

  // Timer logic
  useEffect(() => {
    if (timeLeft <= 0) {
      handleSkip();
      return;
    }

    const timerId = setInterval(() => {
      setTimeLeft((prev) => prev - 1);
    }, 1000);

    return () => clearInterval(timerId);
  }, [timeLeft]);

  // Hint logic
  useEffect(() => {
    if (allowHint && perQTime - timeLeft >= hintDelay && currentWord?.单词) {
      // Generate hint: e.g. a _ p _ e for apple
      const word = currentWord.单词;
      const hintStr = word.split('').map((char, idx) => (idx % 2 === 0 ? char : '_')).join(' ');
      setHint(hintStr);
    }
  }, [timeLeft, allowHint, hintDelay, currentWord, perQTime]);

  const handleNext = (isCorrect: boolean, userInput: string) => {
    const timeSpent = perQTime - timeLeft;

    submitAnswer(currentQIndex, {
      q_index: currentQIndex,
      word: currentWord.单词,
      correct: isCorrect,
      score_val: isCorrect ? 100 : 0, // Simplified score
      time_spent: timeSpent,
      user_input: userInput,
    });

    // Update Word Stats
    updateWordStats(currentAccountId, currentWord.单词, isCorrect, timeSpent);

    if (currentQIndex < totalQuestions - 1) {
      nextQuestion();
    } else {
      finishTest();
    }
  };

  const handleSubmit = () => {
    if (!input.trim()) return;
    const isCorrect = input.trim().toLowerCase() === currentWord.单词.toLowerCase();
    
    if (isCorrect) {
      handleNext(true, input.trim());
    } else {
      Alert.alert('Incorrect', 'Try again!', [{ text: 'OK' }]);
    }
  };

  const handleSkip = () => {
    handleNext(false, input.trim());
  };

  const finishTest = () => {
    // Collect all answers and save history
    const state = useDictationStore.getState();
    const answers = Object.values(state.userAnswers);
    
    const correctCount = answers.filter(a => a.correct).length;
    const totalScore = answers.reduce((sum, a) => sum + (a.score_val || 0), 0);

    addHistory(currentAccountId, {
      timestamp: new Date().toISOString(),
      mode: state.testMode,
      score: totalScore,
      total: totalQuestions,
      correct: correctCount,
      score_val: totalScore,
      used_hints: state.usedHints.length,
      status: 'completed',
      details: answers,
    });

    Alert.alert('Test Completed', `You got ${correctCount} out of ${totalQuestions} correct!`, [
      {
        text: 'OK',
        onPress: () => {
          navigation.replace('PostTestSummary');
        }
      }
    ]);
  };

  if (!currentWord) return null;

  return (
    <AppLayout>
      <View className="flex-1 p-6 justify-center">
        <View className="flex-row justify-between items-center mb-8">
          <Text className="text-white text-lg font-semibold">
            Word {currentQIndex + 1} of {totalQuestions}
          </Text>
          <View className={`px-4 py-2 rounded-full ${timeLeft <= 5 ? 'bg-red-500' : 'bg-slate-700'}`}>
            <Text className="text-white font-bold">{timeLeft}s</Text>
          </View>
        </View>

        <GlassCard intensity={30} className="p-8 items-center gap-y-8">
          <TouchableOpacity onPress={playWord} className="bg-blue-500/20 p-6 rounded-full">
            <Text className="text-6xl">🔊</Text>
          </TouchableOpacity>

          {hint && (
            <Text className="text-yellow-400 text-2xl font-mono tracking-widest">
              {hint}
            </Text>
          )}

          <TextInput
            className="w-full bg-slate-900/50 text-white text-2xl p-4 rounded-xl text-center border border-slate-700"
            value={input}
            onChangeText={setInput}
            placeholder="Type word here..."
            placeholderTextColor="#64748b"
            autoCapitalize="none"
            autoCorrect={false}
            autoFocus
            onSubmitEditing={handleSubmit}
          />

          <View className="w-full flex-row gap-x-4 mt-4">
            <Button
              title="Skip"
              variant="glass"
              className="flex-1"
              onPress={handleSkip}
            />
            <Button
              title="Submit"
              variant="primary"
              className="flex-1"
              onPress={handleSubmit}
            />
          </View>
        </GlassCard>
      </View>
    </AppLayout>
  );
}