import React from 'react';
import { View, StyleSheet, ViewProps } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';

interface AppLayoutProps extends ViewProps {
  children: React.ReactNode;
}

export function AppLayout({ children, style, ...props }: AppLayoutProps) {
  return (
    <View style={[styles.container, style]} {...props}>
      <LinearGradient
        colors={['#0f172a', '#2e1022']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={StyleSheet.absoluteFillObject}
      />
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
