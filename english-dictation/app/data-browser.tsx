import React, { useState, useEffect, useMemo } from 'react';
import { View, ScrollView, TouchableOpacity, Modal } from 'react-native';
import { Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer, GlassCard, Typography, GlassButton } from '../components/theme';
import { useAccount } from '../lib/AccountContext';
import { getVocabTreeStats, getWordHistory, getFolderSessions } from '../lib/dbHelpers';

type WordStat = {
  id: number;
  word: string;
  meaning: string;
  pos: string;
  book: string;
  unit: string;
  total_tests: number;
  wrong_count: number;
};

export default function DataBrowser() {
  const { activeAccount } = useAccount();
  const [words, setWords] = useState<WordStat[]>([]);
  const [expandedBooks, setExpandedBooks] = useState<Record<string, boolean>>({});
  const [expandedUnits, setExpandedUnits] = useState<Record<string, boolean>>({});

  // Modals state
  const [folderModal, setFolderModal] = useState<{ visible: boolean; type: 'book' | 'unit'; book: string; unit?: string } | null>(null);
  const [wordModal, setWordModal] = useState<{ visible: boolean; word: WordStat } | null>(null);

  useEffect(() => {
    if (activeAccount) {
      const stats = getVocabTreeStats(activeAccount.id);
      setWords(stats);
    }
  }, [activeAccount]);

  const toggleBook = (book: string) => {
    setExpandedBooks(prev => ({ ...prev, [book]: !prev[book] }));
  };

  const toggleUnit = (unitKey: string) => {
    setExpandedUnits(prev => ({ ...prev, [unitKey]: !prev[unitKey] }));
  };

  // Group by book -> unit -> words
  const tree = useMemo(() => {
    const data: Record<string, Record<string, WordStat[]>> = {};
    words.forEach(w => {
      if (!data[w.book]) data[w.book] = {};
      if (!data[w.book][w.unit]) data[w.book][w.unit] = [];
      data[w.book][w.unit].push(w);
    });
    return data;
  }, [words]);

  return (
    <ScreenContainer>
      <Stack.Screen options={{ title: "数据浏览器" }} />
      <ScrollView className="w-full">
        {Object.keys(tree).map(book => (
          <View key={book} className="mb-4">
            <GlassCard className="!p-0 overflow-hidden">
              <TouchableOpacity 
                className="flex-row justify-between items-center p-4 bg-white/5"
                onPress={() => toggleBook(book)}
              >
                <View className="flex-row items-center gap-2">
                  <Ionicons name={expandedBooks[book] ? "folder-open" : "folder"} size={24} color="#60a5fa" />
                  <Typography variant="h2" className="mb-0">{book}</Typography>
                </View>
                <View className="flex-row items-center gap-3">
                  <TouchableOpacity onPress={() => setFolderModal({ visible: true, type: 'book', book })}>
                    <Ionicons name="stats-chart" size={20} color="#fbbf24" />
                  </TouchableOpacity>
                  <Ionicons name={expandedBooks[book] ? "chevron-down" : "chevron-forward"} size={20} color="white" />
                </View>
              </TouchableOpacity>

              {expandedBooks[book] && (
                <View className="pl-4 pb-2 pr-2">
                  {Object.keys(tree[book]).map(unit => {
                    const unitKey = `${book}-${unit}`;
                    const unitWords = tree[book][unit];
                    return (
                      <View key={unitKey} className="mt-2">
                        <TouchableOpacity 
                          className="flex-row justify-between items-center p-3 bg-white/5 rounded-lg"
                          onPress={() => toggleUnit(unitKey)}
                        >
                          <View className="flex-row items-center gap-2">
                            <Ionicons name={expandedUnits[unitKey] ? "folder-open-outline" : "folder-outline"} size={20} color="#9ca3af" />
                            <Typography variant="body" className="mb-0 font-bold">{unit}</Typography>
                          </View>
                          <View className="flex-row items-center gap-3">
                            <TouchableOpacity onPress={() => setFolderModal({ visible: true, type: 'unit', book, unit })}>
                              <Ionicons name="stats-chart" size={18} color="#fbbf24" />
                            </TouchableOpacity>
                            <Ionicons name={expandedUnits[unitKey] ? "chevron-down" : "chevron-forward"} size={18} color="white" />
                          </View>
                        </TouchableOpacity>

                        {expandedUnits[unitKey] && (
                          <View className="pl-4 mt-2 gap-2">
                            {unitWords.map(w => (
                              <TouchableOpacity 
                                key={w.id} 
                                className="flex-row justify-between items-center p-3 bg-white/5 rounded-lg"
                                onPress={() => setWordModal({ visible: true, word: w })}
                              >
                                <View className="flex-1">
                                  <Typography variant="body" className="mb-0 font-bold">{w.word}</Typography>
                                  <Typography variant="caption" className="text-gray-400">
                                    {w.pos ? `${w.pos} ` : ''}{w.meaning}
                                  </Typography>
                                </View>
                                <View className="items-end">
                                  <Typography variant="caption" className="text-gray-300">
                                    测{w.total_tests}次·错{w.wrong_count}次
                                  </Typography>
                                </View>
                              </TouchableOpacity>
                            ))}
                          </View>
                        )}
                      </View>
                    );
                  })}
                </View>
              )}
            </GlassCard>
          </View>
        ))}
      </ScrollView>

      {/* Folder Stats Modal */}
      {folderModal && folderModal.visible && (
        <FolderStatsModal 
          accountId={activeAccount?.id} 
          folder={folderModal} 
          words={words} 
          onClose={() => setFolderModal(null)} 
        />
      )}

      {/* Word Stats Modal */}
      {wordModal && wordModal.visible && (
        <WordStatsModal 
          accountId={activeAccount?.id} 
          word={wordModal.word} 
          onClose={() => setWordModal(null)} 
        />
      )}
    </ScreenContainer>
  );
}

function FolderStatsModal({ accountId, folder, words, onClose }: { accountId?: number, folder: any, words: WordStat[], onClose: () => void }) {
  const [sessions, setSessions] = useState<{id: number, created_at: string}[]>([]);

  const folderWords = useMemo(() => {
    if (folder.type === 'book') return words.filter(w => w.book === folder.book);
    return words.filter(w => w.book === folder.book && w.unit === folder.unit);
  }, [folder, words]);

  const stats = useMemo(() => {
    let totalTests = 0;
    let totalWrong = 0;
    folderWords.forEach(w => {
      totalTests += w.total_tests;
      totalWrong += w.wrong_count;
    });
    return {
      totalWords: folderWords.length,
      totalTests,
      totalWrong,
      totalCorrect: totalTests - totalWrong
    };
  }, [folderWords]);

  useEffect(() => {
    if (accountId) {
      const s = getFolderSessions(accountId, folder.book, folder.type === 'unit' ? folder.unit : undefined);
      setSessions(s);
    }
  }, [accountId, folder]);

  return (
    <Modal visible animationType="slide" transparent>
      <View className="flex-1 justify-center items-center bg-black/60 p-4">
        <GlassCard className="w-full max-h-[80%]">
          <Typography variant="h2">
            {folder.type === 'book' ? `书籍: ${folder.book}` : `单元: ${folder.unit}`}
          </Typography>
          
          <View className="flex-row justify-around my-4">
            <View className="items-center">
              <Typography variant="h1" className="text-blue-400 mb-1">{stats.totalWords}</Typography>
              <Typography variant="caption">总词汇</Typography>
            </View>
            <View className="items-center">
              <Typography variant="h1" className="text-green-400 mb-1">{stats.totalTests}</Typography>
              <Typography variant="caption">总测验</Typography>
            </View>
            <View className="items-center">
              <Typography variant="h1" className="text-red-400 mb-1">{stats.totalWrong}</Typography>
              <Typography variant="caption">总错误</Typography>
            </View>
          </View>

          <Typography variant="h2" className="mt-4 mb-2">相关听写历史 ({sessions.length})</Typography>
          <ScrollView className="max-h-48 mb-4">
            {sessions.map(s => (
              <View key={s.id} className="p-2 border-b border-white/10">
                <Typography variant="body">{new Date(s.created_at).toLocaleString()}</Typography>
              </View>
            ))}
          </ScrollView>

          <GlassButton onPress={onClose} className="mt-2 bg-blue-600">
            <Typography variant="body" className="font-bold">关闭</Typography>
          </GlassButton>
        </GlassCard>
      </View>
    </Modal>
  );
}

function WordStatsModal({ accountId, word, onClose }: { accountId?: number, word: WordStat, onClose: () => void }) {
  const [history, setHistory] = useState<{is_correct: number, created_at: string}[]>([]);

  useEffect(() => {
    if (accountId) {
      const h = getWordHistory(accountId, word.id);
      setHistory(h);
    }
  }, [accountId, word.id]);

  return (
    <Modal visible animationType="fade" transparent>
      <View className="flex-1 justify-center items-center bg-black/60 p-4">
        <GlassCard className="w-full max-h-[80%]">
          <Typography variant="h2" className="text-blue-300">{word.word}</Typography>
          <Typography variant="body" className="mb-4">
            {word.pos ? `${word.pos} ` : ''}{word.meaning}
          </Typography>

          <View className="flex-row justify-around mb-4 bg-white/5 p-4 rounded-xl">
            <View className="items-center">
              <Typography variant="h2" className="text-blue-400 mb-1">{word.total_tests}</Typography>
              <Typography variant="caption">测试次数</Typography>
            </View>
            <View className="items-center">
              <Typography variant="h2" className="text-red-400 mb-1">{word.wrong_count}</Typography>
              <Typography variant="caption">错误次数</Typography>
            </View>
          </View>

          <Typography variant="body" className="mb-2 font-bold">最近50次记录</Typography>
          <ScrollView className="max-h-64 mb-4">
            {history.map((h, i) => (
              <View key={i} className="flex-row justify-between p-2 border-b border-white/10">
                <Typography variant="caption">{new Date(h.created_at).toLocaleString()}</Typography>
                <Typography variant="caption" className={h.is_correct ? "text-green-400" : "text-red-400"}>
                  {h.is_correct ? "正确" : "错误"}
                </Typography>
              </View>
            ))}
            {history.length === 0 && (
              <Typography variant="caption" className="text-center text-gray-400 mt-4">暂无记录</Typography>
            )}
          </ScrollView>

          <GlassButton onPress={onClose} className="mt-2 bg-blue-600">
            <Typography variant="body" className="font-bold">关闭</Typography>
          </GlassButton>
        </GlassCard>
      </View>
    </Modal>
  );
}