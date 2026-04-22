import React, { useState } from "react";
import { View, ScrollView, TouchableOpacity } from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import { ScreenContainer, GlassCard, Typography, GlassButton } from "../components/theme";
import { useAccount } from "../lib/AccountContext";
import { createSessionWithWords } from "../lib/dbHelpers";

export default function SelectModeScreen() {
  const { activeAccount } = useAccount();
  const router = useRouter();
  const { vocabIds } = useLocalSearchParams<{ vocabIds: string }>();
  
  const [mode, setMode] = useState<string>("spelling"); // 'spelling', 'meaning', 'mixed'

  const handleStart = () => {
    if (!activeAccount || !vocabIds) return;
    
    const ids = vocabIds.split(",").map(id => parseInt(id, 10)).filter(id => !isNaN(id));
    if (ids.length === 0) return;

    // Create a new session with the chosen words and mode
    const sessionId = createSessionWithWords(activeAccount.id, mode, ids);
    
    // Navigate to testing engine
    router.replace(`/testing?sessionId=${sessionId}`);
  };

  return (
    <ScreenContainer>
      <ScrollView contentContainerStyle={{ padding: 16, flexGrow: 1, justifyContent: 'center' }}>
        <Typography variant="h1" className="mb-8 text-center">选择测试模式</Typography>
        
        <GlassCard className="mb-8">
          <TouchableOpacity 
            onPress={() => setMode("spelling")}
            className={`p-4 rounded-xl mb-4 border ${mode === 'spelling' ? 'border-blue-500 bg-blue-900/30' : 'border-transparent bg-white/5'}`}
          >
            <Typography variant="h2" className="mb-1">听写单词 (Spelling)</Typography>
            <Typography variant="body" className="text-gray-400">听发音和看释义，拼写出正确的英文单词。</Typography>
          </TouchableOpacity>

          <TouchableOpacity 
            onPress={() => setMode("meaning")}
            className={`p-4 rounded-xl mb-4 border ${mode === 'meaning' ? 'border-green-500 bg-green-900/30' : 'border-transparent bg-white/5'}`}
          >
            <Typography variant="h2" className="mb-1">默写释义 (Meaning)</Typography>
            <Typography variant="body" className="text-gray-400">看英文单词，写出对应的中文释义。</Typography>
          </TouchableOpacity>

          <TouchableOpacity 
            onPress={() => setMode("mixed")}
            className={`p-4 rounded-xl border ${mode === 'mixed' ? 'border-purple-500 bg-purple-900/30' : 'border-transparent bg-white/5'}`}
          >
            <Typography variant="h2" className="mb-1">混合模式 (Mixed)</Typography>
            <Typography variant="body" className="text-gray-400">随机出现拼写和释义的测试，全面检验。</Typography>
          </TouchableOpacity>
        </GlassCard>
        
        <GlassButton className="bg-blue-600 mb-4" onPress={handleStart}>
          <Typography variant="h2" className="mb-0 text-center">开始测试</Typography>
        </GlassButton>
        <GlassButton className="bg-gray-600" onPress={() => router.back()}>
          <Typography variant="h2" className="mb-0 text-center">返回上一步</Typography>
        </GlassButton>
      </ScrollView>
    </ScreenContainer>
  );
}