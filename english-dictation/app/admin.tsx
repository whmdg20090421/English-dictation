import React, { useState } from 'react';
import { View, ScrollView, TouchableOpacity, Alert } from 'react-native';
import { Stack } from 'expo-router';
import { ScreenContainer, GlassCard, Typography, GlassButton } from '../components/theme';
import { useAccount } from '../lib/AccountContext';

import AdminWordsTab from '../components/AdminWordsTab';
import AdminImportExportTab from '../components/AdminImportExportTab';
import AdminSettingsTab from '../components/AdminSettingsTab';
import AdminLogsTab from '../components/AdminLogsTab';

type Tab = 'words' | 'import-export' | 'settings' | 'logs';

export default function AdminConsole() {
  const { activeAccount } = useAccount();
  const [activeTab, setActiveTab] = useState<Tab>('words');

  if (!activeAccount || (activeAccount.role !== 'Admin' && activeAccount.role !== 'Super Admin')) {
    return (
      <ScreenContainer className="items-center justify-center">
        <Stack.Screen options={{ title: "权限拒绝" }} />
        <Typography variant="h2" className="text-red-400">无权访问管理后台</Typography>
      </ScreenContainer>
    );
  }

  const renderTab = () => {
    switch (activeTab) {
      case 'words': return <AdminWordsTab />;
      case 'import-export': return <AdminImportExportTab />;
      case 'settings': return <AdminSettingsTab />;
      case 'logs': return <AdminLogsTab />;
    }
  };

  return (
    <ScreenContainer>
      <Stack.Screen options={{ title: "管理后台" }} />
      
      {/* Tabs Header */}
      <View className="flex-row mb-4 bg-white/10 rounded-xl overflow-hidden">
        {[
          { key: 'words', label: '词库管理' },
          { key: 'import-export', label: '导入导出' },
          { key: 'settings', label: '系统设置' },
          { key: 'logs', label: '听写日志' }
        ].map(tab => (
          <TouchableOpacity
            key={tab.key}
            className={`flex-1 p-3 items-center ${activeTab === tab.key ? 'bg-blue-600' : ''}`}
            onPress={() => setActiveTab(tab.key as Tab)}
          >
            <Typography variant="body" className={`font-bold ${activeTab === tab.key ? 'text-white' : 'text-gray-300'}`}>
              {tab.label}
            </Typography>
          </TouchableOpacity>
        ))}
      </View>

      <View className="flex-1">
        {renderTab()}
      </View>
    </ScreenContainer>
  );
}