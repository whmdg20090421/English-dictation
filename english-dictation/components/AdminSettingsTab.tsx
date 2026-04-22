import React, { useState, useEffect } from 'react';
import { View, TextInput, Alert, ScrollView } from 'react-native';
import { GlassCard, Typography, GlassButton } from './theme';
import { getSetting, setSetting } from '../lib/dbHelpers';
import { useAccount } from '../lib/AccountContext';

export default function AdminSettingsTab() {
  const { activeAccount } = useAccount();
  const [timeLimit, setTimeLimit] = useState('10');
  const [allowHint, setAllowHint] = useState('1');
  const [allowBackward, setAllowBackward] = useState('1');
  const [hintLimit, setHintLimit] = useState('3');
  const [adminPassword, setAdminPassword] = useState('');

  useEffect(() => {
    setTimeLimit(getSetting('question_time_limit') || '10');
    setAllowHint(getSetting('allow_hint') || '1');
    setAllowBackward(getSetting('allow_backward') || '1');
    setHintLimit(getSetting('hint_limit') || '3');
    setAdminPassword(getSetting('admin_password') || '');
  }, []);

  const handleSave = () => {
    if (!activeAccount || (activeAccount.role !== 'Admin' && activeAccount.role !== 'Super Admin')) {
      Alert.alert("错误", "没有权限");
      return;
    }
    
    setSetting('question_time_limit', timeLimit);
    setSetting('allow_hint', allowHint);
    setSetting('allow_backward', allowBackward);
    setSetting('hint_limit', hintLimit);
    setSetting('admin_password', adminPassword);
    Alert.alert("成功", "设置已保存");
  };

  return (
    <ScrollView>
      <GlassCard className="mb-4">
        <Typography variant="h2">应用设置</Typography>
        
        <Typography variant="body" className="mt-4 mb-2">每题限时 (秒)</Typography>
        <TextInput 
          value={timeLimit} 
          onChangeText={setTimeLimit} 
          keyboardType="numeric"
          className="bg-white/10 p-3 rounded-lg text-white" 
        />

        <Typography variant="body" className="mt-4 mb-2">允许提示 (1=是, 0=否)</Typography>
        <TextInput 
          value={allowHint} 
          onChangeText={setAllowHint} 
          keyboardType="numeric"
          className="bg-white/10 p-3 rounded-lg text-white" 
        />

        <Typography variant="body" className="mt-4 mb-2">提示次数限制 (次)</Typography>
        <TextInput 
          value={hintLimit} 
          onChangeText={setHintLimit} 
          keyboardType="numeric"
          className="bg-white/10 p-3 rounded-lg text-white" 
        />

        <Typography variant="body" className="mt-4 mb-2">允许后退 (1=是, 0=否)</Typography>
        <TextInput 
          value={allowBackward} 
          onChangeText={setAllowBackward} 
          keyboardType="numeric"
          className="bg-white/10 p-3 rounded-lg text-white" 
        />

        <Typography variant="body" className="mt-4 mb-2">管理员密码 (进入后台时使用，暂未启用)</Typography>
        <TextInput 
          value={adminPassword} 
          onChangeText={setAdminPassword} 
          secureTextEntry
          className="bg-white/10 p-3 rounded-lg text-white" 
        />

        <GlassButton className="mt-6 bg-blue-600/80" onPress={handleSave}>
          <Typography variant="body" className="font-bold">保存设置</Typography>
        </GlassButton>
      </GlassCard>
    </ScrollView>
  );
}