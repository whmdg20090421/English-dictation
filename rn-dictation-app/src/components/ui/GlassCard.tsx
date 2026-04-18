import React from 'react';
import { View, StyleSheet, ViewProps } from 'react-native';
import { BlurView } from 'expo-blur';

interface GlassCardProps extends ViewProps {
  children: React.ReactNode;
  intensity?: number;
}

export function GlassCard({ children, intensity = 20, style, ...props }: GlassCardProps) {
  return (
    <View style={[styles.container, style]} {...props}>
      <BlurView intensity={intensity} tint="dark" style={StyleSheet.absoluteFillObject} />
      <View style={styles.content}>
        {children}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: 24,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.15)',
    backgroundColor: 'rgba(255, 255, 255, 0.05)',
  },
  content: {
    padding: 24,
  },
});
