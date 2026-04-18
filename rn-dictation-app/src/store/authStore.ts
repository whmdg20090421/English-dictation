import { create } from 'zustand';
import * as SecureStore from 'expo-secure-store';

type Role = 'admin' | 'guest' | null;

interface AuthState {
  role: Role;
  hasAdminPin: boolean;
  isLoading: boolean;
  login: (role: Role) => void;
  logout: () => void;
  checkAdminPinStatus: () => Promise<void>;
  setAdminPin: (pin: string) => Promise<void>;
  verifyAdminPin: (pin: string) => Promise<boolean>;
}

export const useAuthStore = create<AuthState>((set) => ({
  role: null,
  hasAdminPin: false,
  isLoading: true,
  login: (role) => set({ role }),
  logout: () => set({ role: null }),
  checkAdminPinStatus: async () => {
    try {
      const pin = await SecureStore.getItemAsync('admin_pin');
      set({ hasAdminPin: !!pin, isLoading: false });
    } catch (e) {
      console.error('Failed to check admin pin status', e);
      set({ hasAdminPin: false, isLoading: false });
    }
  },
  setAdminPin: async (pin: string) => {
    try {
      await SecureStore.setItemAsync('admin_pin', pin);
      set({ hasAdminPin: true });
    } catch (e) {
      console.error('Failed to set admin pin', e);
      throw e;
    }
  },
  verifyAdminPin: async (pin: string) => {
    try {
      const storedPin = await SecureStore.getItemAsync('admin_pin');
      return storedPin === pin;
    } catch (e) {
      console.error('Failed to verify admin pin', e);
      return false;
    }
  }
}));
