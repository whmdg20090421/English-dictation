import React, { useState } from 'react';
import { View, Text, TouchableOpacity, ScrollView, Modal, Alert } from 'react-native';
import { GlassCard } from '../ui/GlassCard';
import { Button } from '../ui/Button';
import { Input } from '../ui/Input';
import { useAppStore } from '../../store/useAppStore';
import { Word } from '../../types/models';

import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList } from '../../types';

export function VocabManager() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const {
    vocab,
    addBook, deleteBook, updateBookName,
    addUnit, deleteUnit, updateUnitName,
    addWord, deleteWord, updateWord
  } = useAppStore();

  const [currentBook, setCurrentBook] = useState<string | null>(null);
  const [currentUnit, setCurrentUnit] = useState<string | null>(null);

  // Modal states
  const [modalVisible, setModalVisible] = useState(false);
  const [modalType, setModalType] = useState<'book' | 'unit' | 'word'>('book');
  const [modalMode, setModalMode] = useState<'create' | 'edit'>('create');
  const [editingId, setEditingId] = useState<string | null>(null);

  // Form states
  const [formName, setFormName] = useState('');
  const [formWordMeaning, setFormWordMeaning] = useState(''); // Only for words (maybe use `单词` as the main field and others if needed)

  const openModal = (type: 'book' | 'unit' | 'word', mode: 'create' | 'edit', id?: string) => {
    setModalType(type);
    setModalMode(mode);
    setEditingId(id || null);
    
    if (mode === 'edit' && id) {
      if (type === 'word' && currentBook && currentUnit) {
        const word = vocab[currentBook][currentUnit][id];
        setFormName(word.单词);
        // We can add more fields if necessary
      } else {
        setFormName(id);
      }
    } else {
      setFormName('');
      setFormWordMeaning('');
    }
    setModalVisible(true);
  };

  const handleSave = () => {
    if (!formName.trim()) {
      Alert.alert('Error', 'Name cannot be empty');
      return;
    }

    if (modalType === 'book') {
      if (modalMode === 'create') {
        if (vocab[formName]) {
          Alert.alert('Error', 'Book already exists');
          return;
        }
        addBook(formName);
      } else if (modalMode === 'edit' && editingId) {
        if (vocab[formName] && formName !== editingId) {
          Alert.alert('Error', 'Book already exists');
          return;
        }
        updateBookName(editingId, formName);
        if (currentBook === editingId) setCurrentBook(formName);
      }
    } else if (modalType === 'unit' && currentBook) {
      if (modalMode === 'create') {
        if (vocab[currentBook][formName]) {
          Alert.alert('Error', 'Unit already exists');
          return;
        }
        addUnit(currentBook, formName);
      } else if (modalMode === 'edit' && editingId) {
        if (vocab[currentBook][formName] && formName !== editingId) {
          Alert.alert('Error', 'Unit already exists');
          return;
        }
        updateUnitName(currentBook, editingId, formName);
        if (currentUnit === editingId) setCurrentUnit(formName);
      }
    } else if (modalType === 'word' && currentBook && currentUnit) {
      if (modalMode === 'create') {
        const uid = Math.random().toString(36).substring(2, 15);
        addWord(currentBook, currentUnit, { 单词: formName, _uid: uid });
      } else if (modalMode === 'edit' && editingId) {
        const existingWord = vocab[currentBook][currentUnit][editingId];
        updateWord(currentBook, currentUnit, editingId, { ...existingWord, 单词: formName });
      }
    }

    setModalVisible(false);
  };

  const handleDelete = (type: 'book' | 'unit' | 'word', id: string) => {
    Alert.alert('Confirm Delete', `Are you sure you want to delete this ${type}?`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: () => {
          if (type === 'book') {
            deleteBook(id);
            if (currentBook === id) {
              setCurrentBook(null);
              setCurrentUnit(null);
            }
          } else if (type === 'unit' && currentBook) {
            deleteUnit(currentBook, id);
            if (currentUnit === id) {
              setCurrentUnit(null);
            }
          } else if (type === 'word' && currentBook && currentUnit) {
            deleteWord(currentBook, currentUnit, id);
          }
        }
      }
    ]);
  };

  const renderBreadcrumbs = () => {
    return (
      <View className="flex-row items-center mb-4 flex-wrap">
        <TouchableOpacity onPress={() => { setCurrentBook(null); setCurrentUnit(null); }}>
          <Text className="text-blue-400 font-bold text-base">Vocab</Text>
        </TouchableOpacity>
        {currentBook && (
          <>
            <Text className="text-white mx-2">{'>'}</Text>
            <TouchableOpacity onPress={() => setCurrentUnit(null)}>
              <Text className="text-blue-400 font-bold text-base">{currentBook}</Text>
            </TouchableOpacity>
          </>
        )}
        {currentUnit && (
          <>
            <Text className="text-white mx-2">{'>'}</Text>
            <Text className="text-gray-300 font-bold text-base">{currentUnit}</Text>
          </>
        )}
      </View>
    );
  };

  const renderContent = () => {
    if (!currentBook) {
      // Show Books
      const books = Object.keys(vocab);
      return (
        <View className="gap-y-3">
          <View className="flex-row justify-between items-center mb-2">
            <Text className="text-lg font-semibold text-white">Folders (Books)</Text>
            <Button title="Add Folder" variant="primary" onPress={() => openModal('book', 'create')} />
          </View>
          {books.length === 0 ? (
            <Text className="text-gray-400 text-center py-4">No folders yet.</Text>
          ) : (
            books.map(book => (
              <GlassCard key={book} intensity={20} className="p-4 flex-row justify-between items-center">
                <TouchableOpacity className="flex-1" onPress={() => setCurrentBook(book)}>
                  <Text className="text-white text-lg">{book}</Text>
                  <Text className="text-gray-400 text-sm">{Object.keys(vocab[book]).length} sets</Text>
                </TouchableOpacity>
                <View className="flex-row gap-x-2">
                  <Button title="Edit" variant="glass" onPress={() => openModal('book', 'edit', book)} />
                  <Button title="Delete" variant="danger" onPress={() => handleDelete('book', book)} />
                </View>
              </GlassCard>
            ))
          )}
        </View>
      );
    }

    if (!currentUnit) {
      // Show Units for currentBook
      const units = Object.keys(vocab[currentBook] || {});
      return (
        <View className="gap-y-3">
          <View className="flex-row justify-between items-center mb-2">
            <Text className="text-lg font-semibold text-white">Word Sets (Units)</Text>
            <Button title="Add Set" variant="primary" onPress={() => openModal('unit', 'create')} />
          </View>
          {units.length === 0 ? (
            <Text className="text-gray-400 text-center py-4">No sets yet.</Text>
          ) : (
            units.map(unit => (
              <GlassCard key={unit} intensity={20} className="p-4 flex-row justify-between items-center">
                <TouchableOpacity className="flex-1" onPress={() => setCurrentUnit(unit)}>
                  <Text className="text-white text-lg">{unit}</Text>
                  <Text className="text-gray-400 text-sm">{Object.keys(vocab[currentBook][unit]).length} words</Text>
                </TouchableOpacity>
                <View className="flex-row gap-x-2">
                  <Button title="Test" variant="primary" onPress={() => navigation.navigate('TestConfig', { bookName: currentBook, unitName: unit })} />
                  <Button title="Edit" variant="glass" onPress={() => openModal('unit', 'edit', unit)} />
                  <Button title="Delete" variant="danger" onPress={() => handleDelete('unit', unit)} />
                </View>
              </GlassCard>
            ))
          )}
        </View>
      );
    }

    // Show Words for currentUnit
    const wordsObj = vocab[currentBook][currentUnit] || {};
    const words = Object.values(wordsObj);
    return (
      <View className="gap-y-3">
        <View className="flex-row justify-between items-center mb-2">
          <Text className="text-lg font-semibold text-white">Words</Text>
          <Button title="Add Word" variant="primary" onPress={() => openModal('word', 'create')} />
        </View>
        {words.length === 0 ? (
          <Text className="text-gray-400 text-center py-4">No words yet.</Text>
        ) : (
          words.map(word => (
            <GlassCard key={word._uid} intensity={20} className="p-4 flex-row justify-between items-center">
              <View className="flex-1">
                <Text className="text-white text-lg">{word.单词}</Text>
              </View>
              <View className="flex-row gap-x-2">
                <Button title="Edit" variant="glass" onPress={() => openModal('word', 'edit', word._uid)} />
                <Button title="Delete" variant="danger" onPress={() => handleDelete('word', word._uid)} />
              </View>
            </GlassCard>
          ))
        )}
      </View>
    );
  };

  return (
    <View className="flex-1">
      <GlassCard intensity={30} className="p-6 min-h-[400px]">
        {renderBreadcrumbs()}
        {renderContent()}
      </GlassCard>

      <Modal
        visible={modalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setModalVisible(false)}
      >
        <View className="flex-1 justify-center items-center bg-black/50 p-4">
          <GlassCard intensity={40} className="w-full max-w-sm p-6 gap-y-4">
            <Text className="text-xl font-bold text-white">
              {modalMode === 'create' ? 'Create' : 'Edit'} {modalType === 'book' ? 'Folder' : modalType === 'unit' ? 'Set' : 'Word'}
            </Text>
            
            <Input
              label={modalType === 'word' ? "Word" : "Name"}
              value={formName}
              onChangeText={setFormName}
              placeholder={`Enter ${modalType} name`}
            />

            <View className="flex-row gap-x-4 mt-4">
              <Button 
                title="Cancel" 
                variant="glass" 
                className="flex-1" 
                onPress={() => setModalVisible(false)} 
              />
              <Button 
                title="Save" 
                variant="primary" 
                className="flex-1" 
                onPress={handleSave} 
              />
            </View>
          </GlassCard>
        </View>
      </Modal>
    </View>
  );
}