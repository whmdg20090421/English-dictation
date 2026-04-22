import { Stack } from "expo-router";
import { useEffect, useState } from "react";
import { initDB } from "../lib/db";
import { AccountProvider } from "../lib/AccountContext";
import { useSyncQueue } from "../lib/useSyncQueue";
import "../global.css";
import { View, ActivityIndicator } from "react-native";

function AppContent() {
  useSyncQueue();

  return (
    <AccountProvider>
      <Stack screenOptions={{
        headerStyle: { backgroundColor: '#1a3247' },
        headerTintColor: '#fff',
        headerTitleStyle: { fontWeight: 'bold' },
        contentStyle: { backgroundColor: '#0d1d2b' }
      }}>
        <Stack.Screen name="index" options={{ title: "首页" }} />
        <Stack.Screen name="accounts" options={{ title: "账户管理" }} />
        <Stack.Screen name="mistakes" options={{ title: "错题重练", presentation: 'modal' }} />
        <Stack.Screen name="dictation" options={{ title: "听写" }} />
      </Stack>
    </AccountProvider>
  );
}

export default function RootLayout() {
  const [isDbReady, setIsDbReady] = useState(false);

  useEffect(() => {
    try {
      initDB();
      setIsDbReady(true);
    } catch (error) {
      console.error("Failed to initialize database", error);
    }
  }, []);

  if (!isDbReady) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center", backgroundColor: "#0d1d2b" }}>
        <ActivityIndicator size="large" color="#ffffff" />
      </View>
    );
  }

  return <AppContent />;
}