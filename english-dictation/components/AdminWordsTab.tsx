import React, { useState, useEffect, useMemo } from 'react';
import { View, ScrollView, TouchableOpacity, Alert, Modal, TextInput } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { GlassCard, Typography, GlassButton } from './theme';
import { db } from '../lib/db';
import { useAccount } from '../lib/AccountContext';

type Vocab = { id: number; word: string; meaning: string; pos: string; book: string; unit: string; sort_order: number };

export default function AdminWordsTab() {
  const { activeAccount } = useAccount();
  const [vocabs, setVocabs] = useState<Vocab[]>([]);
  const [expandedBooks, setExpandedBooks] = useState<Record<string, boolean>>({});
  const [expandedUnits, setExpandedUnits] = useState<Record<string, boolean>>({});

  // Modals
  const [editFolderModal, setEditFolderModal] = useState<{ visible: boolean; type: 'book' | 'unit'; oldBook: string; oldUnit?: string; newName: string } | null>(null);
  const [editWordModal, setEditWordModal] = useState<{ visible: boolean; isNew: boolean; word: Partial<Vocab> } | null>(null);

  const loadVocabs = () => {
    const list = db.getAllSync<Vocab>(`SELECT * FROM Vocab ORDER BY book, unit, sort_order, id`);
    setVocabs(list.map(v => ({...v, book: v.book || '未分类', unit: v.unit || '未分类'})));
  };

  useEffect(() => { loadVocabs(); }, []);

  const toggleBook = (book: string) => setExpandedBooks(prev => ({ ...prev, [book]: !prev[book] }));
  const toggleUnit = (unitKey: string) => setExpandedUnits(prev => ({ ...prev, [unitKey]: !prev[unitKey] }));

  const tree = useMemo(() => {
    const data: Record<string, Record<string, Vocab[]>> = {};
    vocabs.forEach(w => {
      if (!data[w.book]) data[w.book] = {};
      if (!data[w.book][w.unit]) data[w.book][w.unit] = [];
      data[w.book][w.unit].push(w);
    });
    return data;
  }, [vocabs]);

  const handleRenameFolder = () => {
    if (!editFolderModal || !editFolderModal.newName.trim()) return;
    try {
      if (editFolderModal.type === 'book') {
        db.runSync(`UPDATE Vocab SET book = ? WHERE book = ?`, editFolderModal.newName, editFolderModal.oldBook);
      } else {
        db.runSync(`UPDATE Vocab SET unit = ? WHERE book = ? AND unit = ?`, editFolderModal.newName, editFolderModal.oldBook, editFolderModal.oldUnit!);
      }
      setEditFolderModal(null);
      loadVocabs();
    } catch (e) {
      Alert.alert("错误", "重命名失败");
    }
  };

  const handleDeleteFolder = (type: 'book' | 'unit', book: string, unit?: string) => {
    Alert.alert("确认删除", `确定要删除此${type === 'book' ? '书本' : '单元'}及其中所有单词吗？`, [
      { text: "取消", style: "cancel" },
      { text: "删除", style: "destructive", onPress: () => {
        if (type === 'book') db.runSync(`DELETE FROM Vocab WHERE book = ?`, book);
        else db.runSync(`DELETE FROM Vocab WHERE book = ? AND unit = ?`, book, unit!);
        loadVocabs();
      }}
    ]);
  };

  const handleSaveWord = () => {
    if (!editWordModal || !editWordModal.word.word) return;
    const { id, word, meaning, pos, book, unit, sort_order } = editWordModal.word;
    try {
      if (editWordModal.isNew) {
        db.runSync(
          `INSERT INTO Vocab (word, meaning, pos, book, unit, sort_order, account_id) VALUES (?, ?, ?, ?, ?, ?, ?)`,
          word, meaning || '', pos || '', book || '默认书本', unit || '默认单元', sort_order || 0, activeAccount?.id || null
        );
      } else {
        db.runSync(
          `UPDATE Vocab SET word = ?, meaning = ?, pos = ?, book = ?, unit = ?, sort_order = ? WHERE id = ?`,
          word, meaning || '', pos || '', book || '默认书本', unit || '默认单元', sort_order || 0, id!
        );
      }
      setEditWordModal(null);
      loadVocabs();
    } catch (e) {
      Alert.alert("错误", "保存单词失败");
    }
  };

  const handleDeleteWord = (id: number) => {
    Alert.alert("确认删除", "确定要删除这个单词吗？", [
      { text: "取消", style: "cancel" },
      { text: "删除", style: "destructive", onPress: () => {
        db.runSync(`DELETE FROM Vocab WHERE id = ?`, id);
        loadVocabs();
      }}
    ]);
  };

  const handleMoveWord = (currentIndex: number, direction: 'up' | 'down', unitWords: Vocab[]) => {
    if ((direction === 'up' && currentIndex === 0) || (direction === 'down' && currentIndex === unitWords.length - 1)) return;
    const targetIndex = direction === 'up' ? currentIndex - 1 : currentIndex + 1;
    const w1 = unitWords[currentIndex];
    const w2 = unitWords[targetIndex];
    
    db.runSync(`UPDATE Vocab SET sort_order = ? WHERE id = ?`, w2.sort_order || targetIndex, w1.id);
    db.runSync(`UPDATE Vocab SET sort_order = ? WHERE id = ?`, w1.sort_order || currentIndex, w2.id);
    loadVocabs();
  };

  return (
    <ScrollView className="w-full">
      <GlassButton 
        className="mb-4 bg-green-600/80" 
        onPress={() => setEditWordModal({ visible: true, isNew: true, word: { book: '默认书本', unit: '默认单元', sort_order: 0 } })}
      >
        <Typography variant="body" className="font-bold">+ 添加新单词</Typography>
      </GlassButton>

      {Object.keys(tree).map(book => (
        <View key={book} className="mb-4">
          <GlassCard className="!p-0 overflow-hidden">
            <View className="flex-row justify-between items-center p-4 bg-white/10">
              <TouchableOpacity className="flex-row items-center gap-2 flex-1" onPress={() => toggleBook(book)}>
                <Ionicons name={expandedBooks[book] ? "folder-open" : "folder"} size={24} color="#60a5fa" />
                <Typography variant="h2" className="mb-0">{book}</Typography>
              </TouchableOpacity>
              <View className="flex-row gap-3">
                <TouchableOpacity onPress={() => setEditFolderModal({ visible: true, type: 'book', oldBook: book, newName: book })}>
                  <Ionicons name="pencil" size={20} color="#fbbf24" />
                </TouchableOpacity>
                <TouchableOpacity onPress={() => handleDeleteFolder('book', book)}>
                  <Ionicons name="trash" size={20} color="#ef4444" />
                </TouchableOpacity>
              </View>
            </View>

            {expandedBooks[book] && (
              <View className="pl-4 pb-2 pr-2">
                {Object.keys(tree[book]).map(unit => {
                  const unitKey = `${book}-${unit}`;
                  const unitWords = tree[book][unit];
                  return (
                    <View key={unitKey} className="mt-2">
                      <View className="flex-row justify-between items-center p-3 bg-white/5 rounded-lg">
                        <TouchableOpacity className="flex-row items-center gap-2 flex-1" onPress={() => toggleUnit(unitKey)}>
                          <Ionicons name={expandedUnits[unitKey] ? "folder-open-outline" : "folder-outline"} size={20} color="#9ca3af" />
                          <Typography variant="body" className="mb-0 font-bold">{unit}</Typography>
                        </TouchableOpacity>
                        <View className="flex-row gap-3">
                          <TouchableOpacity onPress={() => setEditFolderModal({ visible: true, type: 'unit', oldBook: book, oldUnit: unit, newName: unit })}>
                            <Ionicons name="pencil" size={18} color="#fbbf24" />
                          </TouchableOpacity>
                          <TouchableOpacity onPress={() => handleDeleteFolder('unit', book, unit)}>
                            <Ionicons name="trash" size={18} color="#ef4444" />
                          </TouchableOpacity>
                        </View>
                      </View>

                      {expandedUnits[unitKey] && (
                        <View className="pl-4 mt-2 gap-2">
                          {unitWords.map((w, idx) => (
                            <View key={w.id} className="flex-row justify-between items-center p-3 bg-white/5 rounded-lg">
                              <View className="flex-1 pr-2">
                                <Typography variant="body" className="mb-0 font-bold">{w.word}</Typography>
                                <Typography variant="caption" className="text-gray-400">
                                  {w.pos ? `${w.pos} ` : ''}{w.meaning}
                                </Typography>
                              </View>
                              <View className="flex-row gap-2 items-center">
                                <TouchableOpacity onPress={() => handleMoveWord(idx, 'up', unitWords)} disabled={idx === 0} className={idx === 0 ? "opacity-30" : ""}>
                                  <Ionicons name="arrow-up" size={18} color="#60a5fa" />
                                </TouchableOpacity>
                                <TouchableOpacity onPress={() => handleMoveWord(idx, 'down', unitWords)} disabled={idx === unitWords.length - 1} className={idx === unitWords.length - 1 ? "opacity-30" : ""}>
                                  <Ionicons name="arrow-down" size={18} color="#60a5fa" />
                                </TouchableOpacity>
                                <TouchableOpacity onPress={() => setEditWordModal({ visible: true, isNew: false, word: w })}>
                                  <Ionicons name="pencil" size={18} color="#fbbf24" />
                                </TouchableOpacity>
                                <TouchableOpacity onPress={() => handleDeleteWord(w.id)}>
                                  <Ionicons name="trash" size={18} color="#ef4444" />
                                </TouchableOpacity>
                              </View>
                            </View>
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

      {/* Edit Folder Modal */}
      {editFolderModal && editFolderModal.visible && (
        <Modal visible animationType="fade" transparent>
          <View className="flex-1 justify-center items-center bg-black/60 p-4">
            <GlassCard className="w-full">
              <Typography variant="h2">重命名{editFolderModal.type === 'book' ? '书本' : '单元'}</Typography>
              <TextInput 
                value={editFolderModal.newName} 
                onChangeText={n => setEditFolderModal({ ...editFolderModal, newName: n })}
                className="bg-white/10 p-3 rounded-lg text-white mt-4 mb-6" 
              />
              <View className="flex-row gap-4">
                <GlassButton className="flex-1 bg-gray-600" onPress={() => setEditFolderModal(null)}>
                  <Typography variant="body" className="font-bold">取消</Typography>
                </GlassButton>
                <GlassButton className="flex-1 bg-blue-600" onPress={handleRenameFolder}>
                  <Typography variant="body" className="font-bold">保存</Typography>
                </GlassButton>
              </View>
            </GlassCard>
          </View>
        </Modal>
      )}

      {/* Edit Word Modal */}
      {editWordModal && editWordModal.visible && (
        <Modal visible animationType="slide" transparent>
          <View className="flex-1 justify-end bg-black/60 pt-10">
            <GlassCard className="w-full rounded-b-none h-4/5 pb-10">
              <ScrollView>
                <Typography variant="h2">{editWordModal.isNew ? '添加单词' : '编辑单词'}</Typography>
                
                <Typography variant="caption" className="mt-4 mb-1">书本</Typography>
                <TextInput 
                  value={editWordModal.word.book} 
                  onChangeText={v => setEditWordModal({ ...editWordModal, word: { ...editWordModal.word, book: v } })}
                  className="bg-white/10 p-3 rounded-lg text-white" 
                />

                <Typography variant="caption" className="mt-4 mb-1">单元</Typography>
                <TextInput 
                  value={editWordModal.word.unit} 
                  onChangeText={v => setEditWordModal({ ...editWordModal, word: { ...editWordModal.word, unit: v } })}
                  className="bg-white/10 p-3 rounded-lg text-white" 
                />

                <Typography variant="caption" className="mt-4 mb-1">单词</Typography>
                <TextInput 
                  value={editWordModal.word.word} 
                  onChangeText={v => setEditWordModal({ ...editWordModal, word: { ...editWordModal.word, word: v } })}
                  className="bg-white/10 p-3 rounded-lg text-white" 
                />

                <Typography variant="caption" className="mt-4 mb-1">词性 (如: n., v., adj.)</Typography>
                <TextInput 
                  value={editWordModal.word.pos} 
                  onChangeText={v => setEditWordModal({ ...editWordModal, word: { ...editWordModal.word, pos: v } })}
                  className="bg-white/10 p-3 rounded-lg text-white" 
                />

                <Typography variant="caption" className="mt-4 mb-1">释义</Typography>
                <TextInput 
                  value={editWordModal.word.meaning} 
                  onChangeText={v => setEditWordModal({ ...editWordModal, word: { ...editWordModal.word, meaning: v } })}
                  className="bg-white/10 p-3 rounded-lg text-white" 
                />

                <Typography variant="caption" className="mt-4 mb-1">排序 (数字越大越靠后)</Typography>
                <TextInput 
                  value={String(editWordModal.word.sort_order || 0)} 
                  onChangeText={v => setEditWordModal({ ...editWordModal, word: { ...editWordModal.word, sort_order: parseInt(v) || 0 } })}
                  keyboardType="numeric"
                  className="bg-white/10 p-3 rounded-lg text-white" 
                />

                <View className="flex-row gap-4 mt-6">
                  <GlassButton className="flex-1 bg-gray-600" onPress={() => setEditWordModal(null)}>
                    <Typography variant="body" className="font-bold">取消</Typography>
                  </GlassButton>
                  <GlassButton className="flex-1 bg-blue-600" onPress={handleSaveWord}>
                    <Typography variant="body" className="font-bold">保存</Typography>
                  </GlassButton>
                </View>
              </ScrollView>
            </GlassCard>
          </View>
        </Modal>
      )}
    </ScrollView>
  );
}