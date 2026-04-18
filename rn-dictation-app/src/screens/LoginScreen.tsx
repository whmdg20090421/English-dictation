import React, { useState, useEffect } from 'react';
import { Text, View, ScrollView } from 'react-native';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { GlassCard } from '../components/ui/GlassCard';
import { AppLayout } from '../components/layout/AppLayout';
import { useAuthStore } from '../store/authStore';

export function LoginScreen() {
  const { hasAdminPin, login, setAdminPin, verifyAdminPin, checkAdminPinStatus } = useAuthStore();
  const [mode, setMode] = useState<'select' | 'admin-login' | 'admin-setup'>('select');
  const [pin, setPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    checkAdminPinStatus();
  }, [checkAdminPinStatus]);

  const handleAdminSelect = () => {
    if (hasAdminPin) {
      setMode('admin-login');
    } else {
      setMode('admin-setup');
    }
    setPin('');
    setConfirmPin('');
    setError('');
  };

  const handleGuestSelect = () => {
    login('guest');
  };

  const handleAdminSetup = async () => {
    if (pin.length < 4) {
      setError('PIN must be at least 4 characters');
      return;
    }
    if (pin !== confirmPin) {
      setError('PINs do not match');
      return;
    }
    try {
      await setAdminPin(pin);
      login('admin');
    } catch (e) {
      setError('Failed to set PIN');
    }
  };

  const handleAdminLogin = async () => {
    if (pin.length < 4) {
      setError('Invalid PIN');
      return;
    }
    const isValid = await verifyAdminPin(pin);
    if (isValid) {
      login('admin');
    } else {
      setError('Incorrect PIN');
    }
  };

  return (
    <AppLayout>
      <ScrollView contentContainerStyle={{ flexGrow: 1, justifyContent: 'center', padding: 24, gap: 24 }}>
        <View className="items-center mb-8">
          <Text className="text-3xl font-bold text-white mb-2 text-center">RN Dictation</Text>
          <Text className="text-slate-300 text-base text-center">Authentication</Text>
        </View>

        <GlassCard intensity={30} className="p-6 gap-y-4">
          {mode === 'select' && (
            <>
              <Text className="text-xl font-semibold text-white mb-4 text-center">Select Role</Text>
              <Button 
                title="Login as Admin" 
                variant="primary" 
                onPress={handleAdminSelect}
              />
              <Button 
                title="Continue as Guest" 
                variant="glass" 
                onPress={handleGuestSelect}
                className="mt-2"
              />
            </>
          )}

          {mode === 'admin-setup' && (
            <>
              <Text className="text-xl font-semibold text-white mb-2 text-center">Set Admin PIN</Text>
              <Text className="text-slate-300 text-sm mb-4 text-center">
                Create a PIN to secure admin access
              </Text>
              
              <Input 
                label="New PIN" 
                placeholder="Enter 4+ digit PIN" 
                value={pin}
                onChangeText={(t) => { setPin(t); setError(''); }}
                secureTextEntry
                keyboardType="numeric"
              />
              <Input 
                label="Confirm PIN" 
                placeholder="Confirm your PIN" 
                value={confirmPin}
                onChangeText={(t) => { setConfirmPin(t); setError(''); }}
                secureTextEntry
                keyboardType="numeric"
                isError={!!error}
                error={error}
              />

              <View className="flex-row gap-4 mt-4">
                <Button 
                  title="Back" 
                  variant="glass" 
                  className="flex-1"
                  onPress={() => setMode('select')}
                />
                <Button 
                  title="Save & Login" 
                  variant="primary" 
                  className="flex-1"
                  onPress={handleAdminSetup}
                />
              </View>
            </>
          )}

          {mode === 'admin-login' && (
            <>
              <Text className="text-xl font-semibold text-white mb-2 text-center">Admin Login</Text>
              <Text className="text-slate-300 text-sm mb-4 text-center">
                Enter your admin PIN to continue
              </Text>
              
              <Input 
                label="PIN" 
                placeholder="Enter your PIN" 
                value={pin}
                onChangeText={(t) => { setPin(t); setError(''); }}
                secureTextEntry
                keyboardType="numeric"
                isError={!!error}
                error={error}
              />

              <View className="flex-row gap-4 mt-4">
                <Button 
                  title="Back" 
                  variant="glass" 
                  className="flex-1"
                  onPress={() => setMode('select')}
                />
                <Button 
                  title="Login" 
                  variant="primary" 
                  className="flex-1"
                  onPress={handleAdminLogin}
                />
              </View>
            </>
          )}
        </GlassCard>
      </ScrollView>
    </AppLayout>
  );
}
