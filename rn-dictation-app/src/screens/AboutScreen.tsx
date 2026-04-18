import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, ActivityIndicator } from 'react-native';
import { AppLayout } from '../components/layout/AppLayout';
import { GlassCard } from '../components/ui/GlassCard';
import { Asset } from 'expo-asset';
import * as FileSystem from 'expo-file-system';

// @ts-ignore
import pkg from '../../package.json';
// @ts-ignore
import changelogAsset from '../../assets/CHANGELOG.md';

export default function AboutScreen() {
  const [changelog, setChangelog] = useState<string>('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadChangelog = async () => {
      try {
        const asset = Asset.fromModule(changelogAsset);
        await asset.downloadAsync();
        const content = await FileSystem.readAsStringAsync(asset.localUri || asset.uri);
        setChangelog(content);
      } catch (e) {
        console.error('Failed to load changelog:', e);
        setChangelog('无法加载更新日志。');
      } finally {
        setLoading(false);
      }
    };
    loadChangelog();
  }, []);

  return (
    <AppLayout>
      <ScrollView className="flex-1 px-4 py-8" contentContainerStyle={{ paddingBottom: 60 }}>
        <GlassCard className="p-6 mb-6 items-center">
          <Text className="text-white text-3xl font-bold mb-2">英语听写·艨艟战舰</Text>
          <Text className="text-slate-300 text-lg">版本: {pkg.version}</Text>
        </GlassCard>

        <GlassCard className="p-6">
          <Text className="text-white text-xl font-bold mb-4">更新日志 (Changelog)</Text>
          {loading ? (
            <ActivityIndicator size="small" color="#4ade80" />
          ) : (
            <Text className="text-slate-300 text-base leading-7">
              {changelog}
            </Text>
          )}
        </GlassCard>
      </ScrollView>
    </AppLayout>
  );
}
