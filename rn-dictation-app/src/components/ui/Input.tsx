import React, { useState } from 'react';
import { TextInput, TextInputProps, View, Text } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSequence,
  withTiming,
  withSpring,
} from 'react-native-reanimated';

const AnimatedView = Animated.createAnimatedComponent(View);

export interface InputProps extends TextInputProps {
  label?: string;
  error?: string;
  isError?: boolean;
}

export function Input({
  label,
  error,
  isError = false,
  className = '',
  onFocus,
  onBlur,
  ...props
}: InputProps) {
  const [isFocused, setIsFocused] = useState(false);
  const translateX = useSharedValue(0);
  const scale = useSharedValue(1);

  // Trigger shake animation when error state becomes true
  React.useEffect(() => {
    if (isError || error) {
      translateX.value = withSequence(
        withTiming(10, { duration: 50 }),
        withTiming(-10, { duration: 50 }),
        withTiming(10, { duration: 50 }),
        withTiming(0, { duration: 50 })
      );
    }
  }, [isError, error, translateX]);

  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [
        { translateX: translateX.value },
        { scale: scale.value }
      ],
    };
  });

  const handleFocus = (e: any) => {
    setIsFocused(true);
    scale.value = withSpring(1.02, { damping: 10, stiffness: 200 });
    onFocus?.(e);
  };

  const handleBlur = (e: any) => {
    setIsFocused(false);
    scale.value = withSpring(1, { damping: 10, stiffness: 200 });
    onBlur?.(e);
  };

  return (
    <AnimatedView style={animatedStyle} {...(className ? { className: `w-full ${className}` } : { className: 'w-full' })}>
      {label && (
        <Text className="text-slate-300 text-sm font-medium mb-1.5 ml-1">
          {label}
        </Text>
      )}
      <View
        className={`flex-row items-center bg-white/5 border rounded-xl overflow-hidden px-4 h-12
          ${isFocused ? 'border-blue-400 bg-white/10' : 'border-white/10'}
          ${(isError || error) ? 'border-red-500 bg-red-500/10' : ''}
        `}
      >
        <TextInput
          className="flex-1 text-white text-base h-full outline-none"
          placeholderTextColor="#94a3b8"
          onFocus={handleFocus}
          onBlur={handleBlur}
          {...props}
        />
      </View>
      {error && (
        <Text className="text-red-400 text-xs mt-1.5 ml-1">
          {error}
        </Text>
      )}
    </AnimatedView>
  );
}
