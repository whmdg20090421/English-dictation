import React, { useState } from 'react';
import { View, ScrollView, TextInput, Alert, TouchableOpacity, Share } from 'react-native';
import { GlassCard, Typography, GlassButton } from './theme';
import { db } from '../lib/db';
import { useAccount } from '../lib/AccountContext';

export default function AdminImportExportTab() {
  const { activeAccount } = useAccount();
  const [importText, setImportText] = useState('');
  const [importBook, setImportBook] = useState('默认书本');
  const [importUnit, setImportUnit] = useState('默认单元');
  const [exportJson, setExportJson] = useState('');

  const handleImport = () => {
    if (!importText.trim()) return;

    try {
      const lines = importText.split('\n').filter(l => l.trim() !== '');
      let count = 0;
      
      db.execSync('BEGIN TRANSACTION;');
      lines.forEach(line => {
        // Simple parse: word [meaning]
        const parts = line.split(/[\t]+| {2,}/);
        const word = parts[0]?.trim();
        const meaning = parts[1]?.trim() || '';
        
        if (word) {
          db.runSync(
            `INSERT INTO Vocab (book, unit, word, meaning, pos, account_id) VALUES (?, ?, ?, ?, NULL, ?)`,
            importBook, importUnit, word, meaning, activeAccount?.id || null
          );
          count++;
        }
      });
      db.execSync('COMMIT;');
      Alert.alert("成功", `导入了 ${count} 个单词`);
      setImportText('');
    } catch (e) {
      db.execSync('ROLLBACK;');
      Alert.alert("错误", "导入失败: " + String(e));
    }
  };

  const handleExport = () => {
    try {
      const tables = ['Accounts', 'Vocab', 'DictationSessions', 'DictationWords', 'Settings'];
      const result: any = {};
      
      tables.forEach(t => {
        result[t] = db.getAllSync(`SELECT * FROM ${t}`);
      });
      
      setExportJson(JSON.stringify(result, null, 2));
    } catch (e) {
      Alert.alert("错误", "导出失败: " + String(e));
    }
  };

  return (
    <ScrollView>
      <GlassCard className="mb-4">
        <Typography variant="h2">批量导入词汇</Typography>
        
        <View className="flex-row gap-4 mt-4">
          <View className="flex-1">
            <Typography variant="body" className="mb-2">书本名称</Typography>
            <TextInput 
              value={importBook} 
              onChangeText={setImportBook} 
              className="bg-white/10 p-3 rounded-lg text-white" 
            />
          </View>
          <View className="flex-1">
            <Typography variant="body" className="mb-2">单元名称</Typography>
            <TextInput 
              value={importUnit} 
              onChangeText={setImportUnit} 
              className="bg-white/10 p-3 rounded-lg text-white" 
            />
          </View>
        </View>

        <Typography variant="body" className="mt-4 mb-2">文本内容 (格式: 单词 [Tab或空格] 释义)</Typography>
        <TextInput 
          value={importText} 
          onChangeText={setImportText} 
          multiline
          numberOfLines={10}
          className="bg-white/10 p-3 rounded-lg text-white h-48" 
          textAlignVertical="top"
        />

        <GlassButton className="mt-4 bg-green-600/80" onPress={handleImport}>
          <Typography variant="body" className="font-bold">执行导入</Typography>
        </GlassButton>
      </GlassCard>

      <GlassCard className="mb-4">
        <Typography variant="h2">导出全部数据</Typography>
        
        <GlassButton className="mt-4 bg-blue-600/80" onPress={handleExport}>
          <Typography variant="body" className="font-bold">生成 JSON</Typography>
        </GlassButton>

        {exportJson !== '' && (
          <View className="mt-4">
            <TextInput 
              value={exportJson} 
              multiline
              editable={false}
              className="bg-white/10 p-3 rounded-lg text-gray-300 h-64" 
              textAlignVertical="top"
            />
            <Typography variant="caption" className="text-gray-400 mt-2">
              请全选并复制以上内容进行备份
            </Typography>
          </View>
        )}
      </GlassCard>
    </ScrollView>
  );
}