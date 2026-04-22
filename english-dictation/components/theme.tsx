import React from "react";
import { View, Text, TouchableOpacity, ViewProps, TextProps, TouchableOpacityProps, KeyboardAvoidingView, Platform } from "react-native";

export function GlassCard({ children, className = "", ...props }: ViewProps) {
  return (
    <View 
      className={`glass rounded-2xl p-6 ${className}`}
      {...props}
    >
      {children}
    </View>
  );
}

export function GlassButton({ children, className = "", onPress, ...props }: TouchableOpacityProps) {
  return (
    <TouchableOpacity 
      activeOpacity={0.8}
      onPress={onPress}
      className={`bg-darkblue-500/80 border border-darkblue-300/30 rounded-full py-3 px-6 items-center justify-center shadow-lg ${className}`}
      {...props}
    >
      {children}
    </TouchableOpacity>
  );
}

export function Typography({ children, className = "", variant = "body", ...props }: TextProps & { variant?: "h1" | "h2" | "body" | "caption" }) {
  const baseStyle = "text-white";
  const variants = {
    h1: "text-3xl font-bold mb-4",
    h2: "text-xl font-semibold mb-2",
    body: "text-base text-white/90",
    caption: "text-sm text-white/60",
  };

  return (
    <Text className={`${baseStyle} ${variants[variant]} ${className}`} {...props}>
      {children}
    </Text>
  );
}

export function ScreenContainer({ children, className = "", ...props }: ViewProps) {
  return (
    <KeyboardAvoidingView 
      behavior={Platform.OS === "ios" ? "padding" : "height"} 
      className={`flex-1 bg-darkblue-950 p-4 ${className}`} 
      {...props as any}
    >
      {children}
    </KeyboardAvoidingView>
  );
}