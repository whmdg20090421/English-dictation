import React, { useEffect, useState } from "react";
import { FlatList, View, TouchableOpacity } from "react-native";
import { useRouter } from "expo-router";
import { ScreenContainer, GlassCard, Typography, GlassButton } from "../components/theme";
import { useAccount } from "../lib/AccountContext";
import { getMistakeWords } from "../lib/dbHelpers";
import { Ionicons } from "@expo/vector-icons";

interface MistakeWord {
  vocab_id: number;
  word: string;
  meaning: string;
  wrong_count: number;
}

export default function MistakesScreen() {
  const { activeAccount } = useAccount();
  const router = useRouter();
  const [mistakes, setMistakes] = useState<MistakeWord[]>([]);
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set());

  useEffect(() => {
    if (activeAccount) {
      const data = getMistakeWords(activeAccount.id);
      setMistakes(data);
    }
  }, [activeAccount]);

  const toggleSelect = (id: number) => {
    const newSet = new Set(selectedIds);
    if (newSet.has(id)) {
      newSet.delete(id);
    } else {
      newSet.add(id);
    }
    setSelectedIds(newSet);
  };

  const selectAll = () => {
    if (selectedIds.size === mistakes.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(mistakes.map(m => m.vocab_id)));
    }
  };

  const handleStart = () => {
    if (selectedIds.size === 0) return;
    const ids = Array.from(selectedIds).join(",");
    router.replace(`/dictation?vocabIds=${ids}`);
  };

  if (mistakes.length === 0) {
    return (
      <ScreenContainer className="items-center justify-center">
        <Typography variant="h2" className="text-gray-400">没有错题记录！</Typography>
        <GlassButton className="mt-4" onPress={() => router.back()}>
          <Typography>返回</Typography>
        </GlassButton>
      </ScreenContainer>
    );
  }

  return (
    <ScreenContainer>
      <View className="flex-row justify-between items-center mb-4">
        <Typography variant="h2" className="mb-0">选择要重练的单词</Typography>
        <TouchableOpacity onPress={selectAll}>
          <Typography className="text-blue-400">
            {selectedIds.size === mistakes.length ? "取消全选" : "全选"}
          </Typography>
        </TouchableOpacity>
      </View>

      <FlatList
        data={mistakes}
        keyExtractor={item => item.vocab_id.toString()}
        renderItem={({ item }) => {
          const isSelected = selectedIds.has(item.vocab_id);
          return (
            <TouchableOpacity onPress={() => toggleSelect(item.vocab_id)}>
              <GlassCard className={`mb-3 flex-row items-center p-4 ${isSelected ? 'border-blue-400/50 bg-blue-900/30' : ''}`}>
                <View className="mr-3">
                  <Ionicons 
                    name={isSelected ? "checkmark-circle" : "ellipse-outline"} 
                    size={24} 
                    color={isSelected ? "#60a5fa" : "#8ba1b5"} 
                  />
                </View>
                <View className="flex-1">
                  <Typography variant="h2" className="mb-1">{item.word}</Typography>
                  <Typography variant="caption">{item.meaning}</Typography>
                </View>
                <View className="items-center justify-center bg-red-500/20 px-2 py-1 rounded">
                  <Typography variant="caption" className="text-red-400">错 {item.wrong_count} 次</Typography>
                </View>
              </GlassCard>
            </TouchableOpacity>
          );
        }}
      />

      <View className="mt-4 pt-4 border-t border-darkblue-300/30">
        <GlassButton 
          className={selectedIds.size === 0 ? 'opacity-50' : 'bg-blue-600/80'} 
          onPress={handleStart}
          disabled={selectedIds.size === 0}
        >
          <Typography variant="h2" className="mb-0">
            开始练习 ({selectedIds.size})
          </Typography>
        </GlassButton>
      </View>
    </ScreenContainer>
  );
}
