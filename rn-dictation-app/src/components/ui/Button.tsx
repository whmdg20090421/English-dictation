import React from 'react';
import { Pressable, Text, PressableProps } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withSequence,
  withTiming,
} from 'react-native-reanimated';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

export interface ButtonProps extends PressableProps {
  title: string;
  variant?: 'primary' | 'secondary' | 'ghost' | 'glass' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
  isError?: boolean;
}

export function Button({
  title,
  variant = 'primary',
  size = 'md',
  className = '',
  isError = false,
  ...props
}: ButtonProps) {
  const scale = useSharedValue(1);
  const translateX = useSharedValue(0);

  const baseClasses = "flex flex-row items-center justify-center rounded-xl overflow-hidden";
  
  const variantClasses = {
    primary: "bg-blue-600",
    secondary: "bg-slate-700",
    ghost: "bg-transparent",
    glass: "bg-white/10 border border-white/20",
    danger: "bg-red-600",
  };
  
  const sizeClasses = {
    sm: "px-4 py-2",
    md: "px-6 py-3",
    lg: "px-8 py-4",
  };
  
  const textVariantClasses = {
    primary: "text-white font-semibold",
    secondary: "text-white font-semibold",
    ghost: "text-slate-200 font-medium",
    glass: "text-white font-medium",
    danger: "text-white font-semibold",
  };
  
  const textSizeClasses = {
    sm: "text-sm",
    md: "text-base",
    lg: "text-lg",
  };

  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [
        { scale: scale.value },
        { translateX: translateX.value },
      ],
    };
  });

  const handlePressIn = () => {
    scale.value = withSpring(0.95, { damping: 10, stiffness: 200 });
  };

  const handlePressOut = () => {
    scale.value = withSpring(1, { damping: 10, stiffness: 200 });
  };

  // Shake animation on error
  React.useEffect(() => {
    if (isError) {
      translateX.value = withSequence(
        withTiming(10, { duration: 50 }),
        withTiming(-10, { duration: 50 }),
        withTiming(10, { duration: 50 }),
        withTiming(0, { duration: 50 })
      );
    }
  }, [isError, translateX]);

  return (
    <AnimatedPressable
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
      style={animatedStyle}
      {...props}
    >
      <Text className={`${textVariantClasses[variant]} ${textSizeClasses[size]}`}>
        {title}
      </Text>
    </AnimatedPressable>
  );
}
