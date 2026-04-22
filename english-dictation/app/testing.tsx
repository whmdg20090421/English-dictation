import React, { useState, useEffect, useRef } from "react";
import { View, TextInput, Alert, TouchableOpacity } from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import * as Speech from "expo-speech";
import { Ionicons } from "@expo/vector-icons";
import { ScreenContainer, GlassCard, Typography, GlassButton } from "../components/theme";
import { useAccount } from "../lib/AccountContext";
import { getSession, getSessionWords, updateDictationWord, getSetting, completeSession } from "../lib/dbHelpers";

interface TestWord {
  id: number;
  vocab_id: number;
  is_correct: number | null;
  user_input: string | null;
  word: string;
  meaning: string;
  pos: string;
  test_type: 'spelling' | 'meaning';
}

export default function TestingScreen() {
  const { activeAccount } = useAccount();
  const router = useRouter();
  const { sessionId } = useLocalSearchParams<{ sessionId: string }>();

  const [words, setWords] = useState<TestWord[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [userInput, setUserInput] = useState("");
  const [hintsUsed, setHintsUsed] = useState(0);

  const [qTimeLeft, setQTimeLeft] = useState(15);
  const [totTimeLeft, setTotTimeLeft] = useState(300);
  
  const [settings, setSettings] = useState({ qTimeLimit: 15, totTimeLimit: 300, hintLimit: 3 });

  const timerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (!activeAccount || !sessionId) {
      router.replace("/");
      return;
    }

    const sid = parseInt(sessionId as string, 10);
    const session = getSession(sid);
    if (!session) {
      router.replace("/");
      return;
    }

    const sessionWords = getSessionWords(sid);
    const mode = session.mode || 'spelling';
    
    const mappedWords = sessionWords.map((w, i) => {
      let type: 'spelling' | 'meaning' = 'spelling';
      if (mode === 'meaning') type = 'meaning';
      else if (mode === 'mixed') type = i % 2 === 0 ? 'spelling' : 'meaning';
      
      return { ...w, test_type: type };
    });
    
    setWords(mappedWords);

    // Find the first unanswered word
    const firstUnanswered = mappedWords.findIndex(w => w.is_correct === null);
    if (firstUnanswered === -1) {
      // all words answered, maybe they already completed it or they just opened a finished session
      router.replace(`/results?sessionId=${sid}`);
      return;
    }
    const startIndex = firstUnanswered;
    setCurrentIndex(startIndex);

    const qTime = parseInt(getSetting("q_time_limit") || "15", 10);
    const totTime = parseInt(getSetting("tot_time_limit") || "300", 10);
    const hintLim = parseInt(getSetting("hint_limit") || "3", 10);
    
    setSettings({ qTimeLimit: qTime, totTimeLimit: totTime, hintLimit: hintLim });
    setQTimeLeft(qTime);
    setTotTimeLeft(totTime); // In a real app we might subtract time already spent

    if (mappedWords.length > 0) {
      playTTS(mappedWords[startIndex]);
    }
  }, [activeAccount, sessionId]);

  useEffect(() => {
    if (words.length === 0) return;

    timerRef.current = setInterval(() => {
      setQTimeLeft((prev) => {
        if (prev <= 1) {
          handleNext(false); 
          return settings.qTimeLimit;
        }
        return prev - 1;
      });

      setTotTimeLeft((prev) => {
        if (prev <= 1) {
          if (timerRef.current) clearInterval(timerRef.current);
          handleFinish();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [currentIndex, words, settings]);

  const playTTS = (w: TestWord) => {
    if (w.test_type === 'spelling') {
      Speech.speak(w.word, { language: 'en' });
    }
  };

  const checkAnswer = (input: string, wordObj: TestWord) => {
    const cleanInput = input.trim().toLowerCase();
    if (!cleanInput) return 0;

    if (wordObj.test_type === 'spelling') {
      return cleanInput === wordObj.word.trim().toLowerCase() ? 1 : 0;
    } else {
      // Meaning matching: check if input is in the meaning string
      // Removing punctuation and pos from meaning could help, but simple includes is a start
      const meaningStr = wordObj.meaning.toLowerCase();
      // Remove common POS like "n.", "v." from meaning for matching
      const cleanMeaning = meaningStr.replace(/^[a-z]+\.\s*/, '').trim();
      return cleanMeaning.includes(cleanInput) || meaningStr.includes(cleanInput) ? 1 : 0;
    }
  };

  const handleNext = (answered: boolean) => {
    if (words.length === 0) return;

    const currentWord = words[currentIndex];
    const isCorrect = checkAnswer(userInput, currentWord);
    
    updateDictationWord(currentWord.id, userInput.trim(), isCorrect);

    if (currentIndex < words.length - 1) {
      setCurrentIndex(prev => prev + 1);
      setUserInput("");
      setHintsUsed(0);
      setQTimeLeft(settings.qTimeLimit);
      playTTS(words[currentIndex + 1]);
    } else {
      handleFinish();
    }
  };

  const handleFinish = () => {
    if (timerRef.current) clearInterval(timerRef.current);
    completeSession(parseInt(sessionId as string, 10));
    router.replace(`/results?sessionId=${sessionId}`);
  };

  const handleExit = () => {
    Alert.alert("退出听写", "你想暂存进度还是放弃本次听写？", [
      { text: "取消", style: "cancel" },
      { text: "暂存并返回", onPress: () => {
        if (timerRef.current) clearInterval(timerRef.current);
        router.replace("/");
      }}
    ]);
  };

  const handleHint = () => {
    if (hintsUsed >= settings.hintLimit) return;
    
    const currentWord = words[currentIndex];
    const target = currentWord.test_type === 'spelling' ? currentWord.word : currentWord.meaning;
    
    // Prefix based LCP
    let prefix = "";
    const minLen = Math.min(userInput.length, target.length);
    for (let i = 0; i < minLen; i++) {
      if (userInput[i].toLowerCase() === target[i].toLowerCase()) {
        prefix += target[i];
      } else {
        break;
      }
    }
    
    const nextChar = target[prefix.length] || "";
    setUserInput(prefix + nextChar);
    setHintsUsed(prev => prev + 1);
  };

  if (words.length === 0) return <ScreenContainer><Typography variant="h1" className="text-center mt-10">加载中...</Typography></ScreenContainer>;

  const currentWord = words[currentIndex];

  return (
    <ScreenContainer>
      <View className="flex-row justify-between items-center p-4">
        <TouchableOpacity onPress={handleExit}>
          <Ionicons name="close" size={32} color="white" />
        </TouchableOpacity>
        <Typography variant="body" className="font-bold text-lg">
          {currentIndex + 1} / {words.length}
        </Typography>
        <View className="items-end">
          <Typography variant="caption" className={qTimeLeft <= 5 ? "text-red-400" : "text-gray-300"}>单题: {qTimeLeft}s</Typography>
          <Typography variant="caption" className="text-gray-300">总计: {Math.floor(totTimeLeft / 60)}:{(totTimeLeft % 60).toString().padStart(2, '0')}</Typography>
        </View>
      </View>

      <View className="flex-1 justify-center px-4">
        <GlassCard className="items-center py-8">
          {currentWord.test_type === 'spelling' ? (
            <>
              <TouchableOpacity onPress={() => playTTS(currentWord)} className="mb-4 bg-blue-500/30 p-4 rounded-full">
                <Ionicons name="volume-high" size={48} color="white" />
              </TouchableOpacity>
              <Typography variant="h2" className="text-center text-gray-300 mb-6">
                {currentWord.pos ? `[${currentWord.pos}] ` : ''}{currentWord.meaning}
              </Typography>
            </>
          ) : (
            <>
              <Typography variant="h1" className="text-center text-white mb-6">
                {currentWord.word}
              </Typography>
              <Typography variant="caption" className="text-center text-gray-400 mb-6">
                请输入对应的中文释义
              </Typography>
            </>
          )}

          <TextInput
            className="w-full bg-white/10 text-white text-2xl p-4 rounded-xl border border-white/20 text-center mb-4"
            placeholder={currentWord.test_type === 'spelling' ? "输入英文拼写" : "输入中文释义"}
            placeholderTextColor="#9ca3af"
            value={userInput}
            onChangeText={setUserInput}
            autoCapitalize="none"
            autoFocus
            onSubmitEditing={() => handleNext(true)}
          />

          <View className="flex-row justify-between w-full">
            <TouchableOpacity 
              className={`flex-1 mr-2 p-3 rounded-xl items-center justify-center ${hintsUsed >= settings.hintLimit ? 'bg-gray-600' : 'bg-yellow-600/80'}`} 
              onPress={handleHint}
              disabled={hintsUsed >= settings.hintLimit}
            >
              <Typography variant="body" className="mb-0">提示 ({settings.hintLimit - hintsUsed})</Typography>
            </TouchableOpacity>
            
            <TouchableOpacity className="flex-1 ml-2 bg-blue-600/80 p-3 rounded-xl items-center justify-center" onPress={() => handleNext(true)}>
              <Typography variant="body" className="mb-0">下一个</Typography>
            </TouchableOpacity>
          </View>
        </GlassCard>
      </View>
    </ScreenContainer>
  );
}