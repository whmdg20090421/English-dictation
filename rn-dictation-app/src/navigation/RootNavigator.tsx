import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { useAuthStore } from '../store/authStore';
import { LoginScreen } from '../screens/LoginScreen';
import { HomeScreen } from '../screens/HomeScreen';
import { TestConfigScreen } from '../screens/test/TestConfigScreen';
import { ActiveTestScreen } from '../screens/test/ActiveTestScreen';
import { PostTestSummaryScreen } from '../screens/history/PostTestSummaryScreen';
import { HistoryListScreen } from '../screens/history/HistoryListScreen';
import { MistakeBookScreen } from '../screens/history/MistakeBookScreen';
import { RootStackParamList } from '../types';

const Stack = createNativeStackNavigator<RootStackParamList>();

export function RootNavigator() {
  const { role } = useAuthStore();

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {role ? (
          // Authenticated screens
          <>
            <Stack.Screen name="Home" component={HomeScreen} />
            <Stack.Screen name="TestConfig" component={TestConfigScreen} />
            <Stack.Screen name="ActiveTest" component={ActiveTestScreen} />
            <Stack.Screen name="PostTestSummary" component={PostTestSummaryScreen} />
            <Stack.Screen name="HistoryList" component={HistoryListScreen} options={{ title: '历史记录' }} />
            <Stack.Screen name="MistakeBook" component={MistakeBookScreen} options={{ title: '智能错题本' }} />
            <Stack.Screen name="About" component={AboutScreen} options={{ title: '关于' }} />
          </>
        ) : (
          // Auth screens
          <Stack.Screen name="Login" component={LoginScreen} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
