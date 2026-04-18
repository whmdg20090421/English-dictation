import './global.css';
import { StatusBar } from 'expo-status-bar';
import { RootNavigator } from './src/navigation/RootNavigator';
import { useAuthStore } from './src/store/authStore';
import { useEffect } from 'react';
import { View, ActivityIndicator } from 'react-native';

export default function App() {
  const { checkAdminPinStatus, isLoading } = useAuthStore();

  useEffect(() => {
    checkAdminPinStatus();
  }, [checkAdminPinStatus]);

  if (isLoading) {
    return (
      <View className="flex-1 justify-center items-center bg-slate-900">
        <ActivityIndicator size="large" color="#ffffff" />
      </View>
    );
  }

  return (
    <>
      <RootNavigator />
      <StatusBar style="light" />
    </>
  );
}