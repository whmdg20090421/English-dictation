import React, { useState, useEffect } from "react";
import { View, ScrollView, TouchableOpacity, Alert, Modal } from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { ScreenContainer, GlassCard, Typography, GlassButton } from "../components/theme";
import { useAccount } from "../lib/AccountContext";
import { getSession, getSessionWords, updateDictationWord } from "../lib/dbHelpers";

interface ResultWord {
  id: number;
  vocab_id: number;
  is_correct: number | null;
  user_input: string | null;
  word: string;
  meaning: string;
  pos: string;
  test_type: 'spelling' | 'meaning';
}

export default function ResultsScreen() {
  const { activeAccount } = useAccount();
  const router = useRouter();
  const { sessionId } = useLocalSearchParams<{ sessionId: string }>();

  const [words, setWords] = useState<ResultWord[]>([]);
  const [sessionInfo, setSessionInfo] = useState<{ mode: string, created_at: string } | null>(null);
  const [selectedWord, setSelectedWord] = useState<ResultWord | null>(null);
  const [modalVisible, setModalVisible] = useState(false);

  useEffect(() => {
    if (!activeAccount || !sessionId) {
      router.replace("/");
      return;
    }
    loadResults();
  }, [activeAccount, sessionId]);

  const loadResults = () => {
    const sid = parseInt(sessionId as string, 10);
    const session = getSession(sid);
    if (session) {
      setSessionInfo({ mode: session.mode, created_at: session.created_at });
    }

    const sessionWords = getSessionWords(sid);
    const mode = session?.mode || 'spelling';
    
    const mappedWords = sessionWords.map((w, i) => {
      let type: 'spelling' | 'meaning' = 'spelling';
      if (mode === 'meaning') type = 'meaning';
      else if (mode === 'mixed') type = i % 2 === 0 ? 'spelling' : 'meaning';
      return { ...w, test_type: type };
    });
    setWords(mappedWords);
  };

  const handleOverride = (isCorrect: number) => {
    if (selectedWord) {
      updateDictationWord(selectedWord.id, selectedWord.user_input || "", isCorrect);
      setModalVisible(false);
      setSelectedWord(null);
      loadResults(); // Reload to update UI
    }
  };

  const openOverrideModal = (word: ResultWord) => {
    setSelectedWord(word);
    setModalVisible(true);
  };

  if (words.length === 0) return <ScreenContainer><Typography variant="h1" className="text-center mt-10">加载中...</Typography></ScreenContainer>;

  const correctCount = words.filter(w => w.is_correct === 1).length;
  const totalCount = words.length;
  const accuracy = Math.round((correctCount / totalCount) * 100);

  return (
    <ScreenContainer>
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <View className="items-center mb-8 mt-4">
          <Ionicons name="trophy" size={64} color="#fbbf24" />
          <Typography variant="h1" className="mt-4 text-center">听写结果</Typography>
          <Typography variant="body" className="text-gray-300">
            模式: {sessionInfo?.mode === 'spelling' ? '听写单词' : sessionInfo?.mode === 'meaning' ? '默写释义' : '混合模式'}
          </Typography>
        </View>

        <View className="flex-row justify-around mb-8">
          <GlassCard className="items-center w-2/5">
            <Typography variant="h1" className="text-green-400">{correctCount}/{totalCount}</Typography>
            <Typography variant="caption">正确数量</Typography>
          </GlassCard>
          <GlassCard className="items-center w-2/5">
            <Typography variant="h1" className={accuracy >= 80 ? "text-green-400" : accuracy >= 60 ? "text-yellow-400" : "text-red-400"}>
              {accuracy}%
            </Typography>
            <Typography variant="caption">准确率</Typography>
          </GlassCard>
        </View>

        <Typography variant="h2" className="mb-4">详细结果 (点击可修改判定)</Typography>
        <GlassCard className="mb-8">
          {words.map((w, index) => (
            <TouchableOpacity 
              key={w.id} 
              onPress={() => openOverrideModal(w)}
              className={`py-3 border-b border-white/10 ${index === words.length - 1 ? 'border-b-0' : ''}`}
            >
              <View className="flex-row justify-between items-center">
                <View className="flex-1">
                  <Typography variant="body" className="font-bold">
                    {w.test_type === 'spelling' ? w.meaning : w.word}
                  </Typography>
                  <View className="flex-row items-center mt-1">
                    <Typography variant="caption" className="text-gray-400 mr-2">你的答案:</Typography>
                    <Typography variant="caption" className={w.is_correct === 1 ? "text-green-400" : "text-red-400"}>
                      {w.user_input || "(未作答)"}
                    </Typography>
                  </View>
                  {w.is_correct === 0 && (
                    <View className="flex-row items-center mt-1">
                      <Typography variant="caption" className="text-gray-400 mr-2">正确答案:</Typography>
                      <Typography variant="caption" className="text-green-400">
                        {w.test_type === 'spelling' ? w.word : w.meaning}
                      </Typography>
                    </View>
                  )}
                </View>
                <View className="ml-4">
                  {w.is_correct === 1 ? (
                    <Ionicons name="checkmark-circle" size={28} color="#4ade80" />
                  ) : (
                    <Ionicons name="close-circle" size={28} color="#f87171" />
                  )}
                </View>
              </View>
            </TouchableOpacity>
          ))}
        </GlassCard>

        <GlassButton className="bg-blue-600 mb-8" onPress={() => router.replace("/")}>
          <Typography variant="h2" className="mb-0 text-center">返回首页</Typography>
        </GlassButton>
      </ScrollView>

      {/* Manual Override Modal */}
      <Modal visible={modalVisible} transparent animationType="fade">
        <View className="flex-1 justify-center items-center bg-black/60 px-4">
          <GlassCard className="w-full">
            <Typography variant="h2" className="text-center mb-4">手动改判</Typography>
            <Typography variant="body" className="mb-2">目标: {selectedWord?.test_type === 'spelling' ? selectedWord?.word : selectedWord?.meaning}</Typography>
            <Typography variant="body" className="mb-6">你的答案: {selectedWord?.user_input || "(无)"}</Typography>
            
            <View className="flex-row justify-between mb-4">
              <TouchableOpacity 
                className="flex-1 mr-2 bg-green-600/80 p-4 rounded-xl items-center"
                onPress={() => handleOverride(1)}
              >
                <Typography variant="body" className="mb-0 font-bold">判为正确</Typography>
              </TouchableOpacity>
              <TouchableOpacity 
                className="flex-1 ml-2 bg-red-600/80 p-4 rounded-xl items-center"
                onPress={() => handleOverride(0)}
              >
                <Typography variant="body" className="mb-0 font-bold">判为错误</Typography>
              </TouchableOpacity>
            </View>
            <TouchableOpacity 
              className="bg-gray-600 p-4 rounded-xl items-center"
              onPress={() => setModalVisible(false)}
            >
              <Typography variant="body" className="mb-0">取消</Typography>
            </TouchableOpacity>
          </GlassCard>
        </View>
      </Modal>
    </ScreenContainer>
  );
}