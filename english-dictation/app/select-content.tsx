import React, { useState, useEffect } from "react";
import { View, ScrollView, TouchableOpacity, Alert } from "react-native";
import { useRouter, useLocalSearchParams } from "expo-router";
import { ScreenContainer, GlassCard, Typography, GlassButton } from "../components/theme";
import { useAccount } from "../lib/AccountContext";
import { getFolders, getUnits, getWordsForUnit } from "../lib/dbHelpers";

export default function SelectContentScreen() {
  const { activeAccount } = useAccount();
  const router = useRouter();
  
  const [folders, setFolders] = useState<{ book: string }[]>([]);
  const [selectedFolder, setSelectedFolder] = useState<string | null>(null);
  
  const [units, setUnits] = useState<{ unit: string }[]>([]);
  const [selectedUnit, setSelectedUnit] = useState<string | null>(null);
  
  const [words, setWords] = useState<{ id: number, word: string, meaning: string }[]>([]);
  const [selectedWords, setSelectedWords] = useState<Set<number>>(new Set());

  useEffect(() => {
    if (!activeAccount) {
      router.replace("/");
      return;
    }
    setFolders(getFolders());
  }, [activeAccount]);

  const handleFolderSelect = (book: string) => {
    setSelectedFolder(book);
    setSelectedUnit(null);
    setWords([]);
    setSelectedWords(new Set());
    setUnits(getUnits(book));
  };

  const handleUnitSelect = (unit: string) => {
    setSelectedUnit(unit);
    if (selectedFolder) {
      const unitWords = getWordsForUnit(selectedFolder, unit);
      setWords(unitWords);
      // default select all
      setSelectedWords(new Set(unitWords.map(w => w.id)));
    }
  };

  const toggleWord = (id: number) => {
    const next = new Set(selectedWords);
    if (next.has(id)) {
      next.delete(id);
    } else {
      next.add(id);
    }
    setSelectedWords(next);
  };

  const handleNext = () => {
    if (selectedWords.size === 0) {
      Alert.alert("提示", "请至少选择一个单词");
      return;
    }
    const ids = Array.from(selectedWords).join(",");
    router.push(`/select-mode?vocabIds=${ids}`);
  };

  return (
    <ScreenContainer>
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <Typography variant="h1" className="mb-4 text-center">选择听写内容</Typography>
        
        {/* Folders */}
        <Typography variant="h2" className="mb-2">1. 选择书本/分类</Typography>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} className="mb-4">
          {folders.map(f => (
            <TouchableOpacity 
              key={f.book} 
              onPress={() => handleFolderSelect(f.book)}
              className={`mr-2 px-4 py-2 rounded-xl ${selectedFolder === f.book ? 'bg-blue-600' : 'bg-gray-700/50'}`}
            >
              <Typography variant="body" className={selectedFolder === f.book ? 'text-white' : 'text-gray-300'}>{f.book}</Typography>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* Units */}
        {selectedFolder && (
          <>
            <Typography variant="h2" className="mb-2">2. 选择单元</Typography>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} className="mb-4">
              {units.map(u => (
                <TouchableOpacity 
                  key={u.unit} 
                  onPress={() => handleUnitSelect(u.unit)}
                  className={`mr-2 px-4 py-2 rounded-xl ${selectedUnit === u.unit ? 'bg-green-600' : 'bg-gray-700/50'}`}
                >
                  <Typography variant="body" className={selectedUnit === u.unit ? 'text-white' : 'text-gray-300'}>{u.unit}</Typography>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </>
        )}

        {/* Words */}
        {selectedUnit && words.length > 0 && (
          <>
            <View className="flex-row justify-between items-center mb-2">
              <Typography variant="h2" className="mb-0">3. 选择单词 ({selectedWords.size}/{words.length})</Typography>
              <TouchableOpacity onPress={() => {
                if (selectedWords.size === words.length) setSelectedWords(new Set());
                else setSelectedWords(new Set(words.map(w => w.id)));
              }}>
                <Typography variant="caption" className="text-blue-400">全选/全不选</Typography>
              </TouchableOpacity>
            </View>
            <GlassCard className="mb-4">
              {words.map(w => (
                <TouchableOpacity 
                  key={w.id} 
                  onPress={() => toggleWord(w.id)}
                  className="flex-row items-center py-2 border-b border-white/10"
                >
                  <View className={`w-5 h-5 rounded-sm border mr-3 items-center justify-center ${selectedWords.has(w.id) ? 'bg-blue-500 border-blue-500' : 'border-gray-400'}`}>
                    {selectedWords.has(w.id) && <View className="w-2.5 h-2.5 bg-white rounded-sm" />}
                  </View>
                  <View className="flex-1">
                    <Typography variant="body">{w.word}</Typography>
                    <Typography variant="caption" className="text-gray-400">{w.meaning}</Typography>
                  </View>
                </TouchableOpacity>
              ))}
            </GlassCard>
            
            <GlassButton className="bg-blue-600 mb-8" onPress={handleNext}>
              <Typography variant="h2" className="mb-0">下一步：选择模式</Typography>
            </GlassButton>
          </>
        )}
      </ScrollView>
    </ScreenContainer>
  );
}