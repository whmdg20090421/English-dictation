import React, { useRef, useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, KeyboardAvoidingView, Platform, Keyboard, TouchableWithoutFeedback } from 'react-native';
import { Video, ResizeMode } from 'expo-av';
import { BlurView } from 'expo-blur';
import { Ionicons } from '@expo/vector-icons';
import { Stack, useRouter } from 'expo-router';
import { db } from '../lib/db';

export default function VideoDictationScreen() {
  const router = useRouter();
  const videoRef = useRef<Video>(null);
  const [status, setStatus] = useState<any>({});
  const [inputText, setInputText] = useState('');
  const [showSubtitle, setShowSubtitle] = useState(false);
  const [feedback, setFeedback] = useState<'success' | 'error' | null>(null);

  // Sample video with some dialogue, though BBB doesn't have subtitles hardcoded, 
  // we just simulate the UI masking the bottom 20%
  const videoSource = {
    uri: 'https://d23dyxeqlo5psv.cloudfront.net/big_buck_bunny.mp4',
  };

  const handleCheck = () => {
    // Basic mock check logic: in reality we'd compare against known subtitle text
    if (inputText.trim().length > 0) {
      setFeedback('success');
      setShowSubtitle(true);
      
      // Save sync event as a mock for Task 8
      try {
        db.runSync(
          `INSERT INTO SyncQueue (action, payload, status) VALUES (?, ?, ?)`,
          'dictation_complete',
          JSON.stringify({ type: 'video', input: inputText, timestamp: Date.now() }),
          'pending'
        );
      } catch (e) {
        console.log('Failed to save to SyncQueue', e);
      }
      
      setTimeout(() => setFeedback(null), 2000);
    } else {
      setFeedback('error');
      setTimeout(() => setFeedback(null), 2000);
    }
  };

  const togglePlayback = () => {
    if (status.isPlaying) {
      videoRef.current?.pauseAsync();
    } else {
      videoRef.current?.playAsync();
    }
  };

  const replay = () => {
    videoRef.current?.setPositionAsync(Math.max(0, status.positionMillis - 5000));
    videoRef.current?.playAsync();
  };

  return (
    <KeyboardAvoidingView 
      style={{ flex: 1 }} 
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <Stack.Screen options={{ title: 'Video Dictation', headerBackTitle: 'Back' }} />
      <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <View className="flex-1 bg-neutral-900">
          
          {/* Video Container */}
          <View className="w-full aspect-video bg-black relative">
            <Video
              ref={videoRef}
              source={videoSource}
              useNativeControls={false}
              resizeMode={ResizeMode.CONTAIN}
              isLooping
              onPlaybackStatusUpdate={status => setStatus(() => status)}
              className="w-full h-full"
            />
            
            {/* Play/Pause overlay */}
            <TouchableOpacity 
              activeOpacity={0.8}
              onPress={togglePlayback}
              className="absolute inset-0 items-center justify-center"
            >
              {!status.isPlaying && (
                <View className="bg-black/50 p-4 rounded-full">
                  <Ionicons name="play" size={48} color="white" />
                </View>
              )}
            </TouchableOpacity>

            {/* Subtitle Masking Overlay (Bottom 20%) */}
            {!showSubtitle && (
              <View className="absolute bottom-0 left-0 right-0 h-[20%] overflow-hidden">
                <BlurView intensity={30} tint="dark" className="flex-1 items-center justify-center">
                  <Text className="text-white/70 text-sm font-medium">Subtitles Hidden</Text>
                  <Ionicons name="eye-off-outline" size={20} color="rgba(255,255,255,0.7)" className="mt-1" />
                </BlurView>
              </View>
            )}
          </View>

          {/* Controls & Input Area */}
          <View className="flex-1 p-6 flex flex-col justify-between">
            <View>
              <View className="flex-row justify-between items-center mb-6">
                <Text className="text-white text-lg font-bold">Listen & Type</Text>
                <View className="flex-row space-x-4 gap-4">
                  <TouchableOpacity onPress={replay} className="bg-neutral-800 p-3 rounded-full">
                    <Ionicons name="play-back" size={20} color="white" />
                  </TouchableOpacity>
                  <TouchableOpacity 
                    onPress={() => setShowSubtitle(!showSubtitle)} 
                    className={`p-3 rounded-full ${showSubtitle ? 'bg-blue-600' : 'bg-neutral-800'}`}
                  >
                    <Ionicons name={showSubtitle ? "eye" : "eye-off"} size={20} color="white" />
                  </TouchableOpacity>
                </View>
              </View>

              <Text className="text-neutral-400 mb-2">Type what you hear:</Text>
              <View className={`border-2 rounded-xl bg-neutral-800 overflow-hidden ${
                feedback === 'success' ? 'border-green-500 animate-flash-success' : 
                feedback === 'error' ? 'border-red-500 animate-shake animate-flash-error' : 'border-transparent'
              }`}>
                <TextInput
                  className="p-4 text-white text-lg min-h-[120px]"
                  multiline
                  placeholder="Start typing..."
                  placeholderTextColor="#666"
                  value={inputText}
                  onChangeText={setInputText}
                  style={{ textAlignVertical: 'top' }}
                />
              </View>
            </View>

            <TouchableOpacity 
              onPress={handleCheck}
              className="bg-blue-600 p-4 rounded-xl items-center mt-4"
            >
              <Text className="text-white font-bold text-lg">Check Answer</Text>
            </TouchableOpacity>
          </View>
        </View>
      </TouchableWithoutFeedback>
    </KeyboardAvoidingView>
  );
}
