import React, { useState, useEffect } from 'react';
import { View, ScrollView, Alert, TouchableOpacity } from 'react-native';
import { GlassCard, Typography, GlassButton } from './theme';
import { useAccount } from '../lib/AccountContext';
import { db } from '../lib/db';
import { Ionicons } from '@expo/vector-icons';

type Log = {
  id: number;
  created_at: string;
  status: string;
  total_words: number;
  correct_words: number;
};

export default function AdminLogsTab() {
  const { activeAccount } = useAccount();
  const [logs, setLogs] = useState<Log[]>([]);

  const loadLogs = () => {
    if (!activeAccount) return;
    const sessions = db.getAllSync<{id: number, created_at: string, status: string}>(
      `SELECT id, created_at, status FROM DictationSessions WHERE account_id = ? ORDER BY created_at DESC LIMIT 100`,
      activeAccount.id
    );

    const loadedLogs = sessions.map(s => {
      const words = db.getAllSync<{is_correct: number}>(`SELECT is_correct FROM DictationWords WHERE session_id = ?`, s.id);
      return {
        id: s.id,
        created_at: s.created_at,
        status: s.status,
        total_words: words.length,
        correct_words: words.filter(w => w.is_correct === 1).length
      };
    });

    setLogs(loadedLogs);
  };

  useEffect(() => {
    loadLogs();
  }, [activeAccount]);

  const handleClearLogs = () => {
    if (!activeAccount) return;
    Alert.alert("清空记录", "确定要清空您所有的听写记录吗？此操作不可恢复。", [
      { text: "取消", style: "cancel" },
      { text: "清空", style: "destructive", onPress: () => {
        db.runSync(`DELETE FROM DictationSessions WHERE account_id = ?`, activeAccount.id);
        Alert.alert("成功", "已清空所有听写记录");
        loadLogs();
      }}
    ]);
  };

  return (
    <ScrollView>
      <GlassCard className="mb-4">
        <View className="flex-row justify-between items-center mb-4">
          <Typography variant="h2" className="mb-0">个人听写记录</Typography>
          <TouchableOpacity onPress={handleClearLogs} className="bg-red-500/80 p-2 rounded-lg">
            <Typography variant="body" className="text-white font-bold">清空记录</Typography>
          </TouchableOpacity>
        </View>

        {logs.map(log => (
          <View key={log.id} className="bg-white/5 p-4 rounded-xl mb-3 border border-white/10 flex-row justify-between items-center">
            <View>
              <Typography variant="body" className="font-bold">
                {new Date(log.created_at).toLocaleString()}
              </Typography>
              <Typography variant="caption" className="text-gray-400 mt-1">
                状态: {log.status === 'completed' ? '已完成' : '进行中'}
              </Typography>
            </View>
            <View className="items-end">
              <Typography variant="h2" className="text-blue-400 mb-0">
                {log.correct_words}/{log.total_words}
              </Typography>
              <Typography variant="caption" className="text-gray-400">正确率</Typography>
            </View>
          </View>
        ))}

        {logs.length === 0 && (
          <Typography variant="body" className="text-center text-gray-400 py-6">暂无听写记录</Typography>
        )}
      </GlassCard>
    </ScrollView>
  );
}