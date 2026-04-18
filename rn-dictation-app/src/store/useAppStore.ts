import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AppData, Account, Vocab, GlobalSettings, AccountHistory, Word } from '../types/models';

interface AppState extends AppData {
  currentAccountId: string;
  // Actions
  setVocab: (vocab: Vocab) => void;
  setAccounts: (accounts: Record<string, Account>) => void;
  setGlobalSettings: (settings: GlobalSettings) => void;
  setCurrentAccountId: (id: string) => void;
  getCurrentAccount: () => Account | undefined;
  updateAccountSettings: (id: string, settings: Partial<Account['settings']>) => void;
  addHistory: (accountId: string, history: AccountHistory) => void;
  updateWordStats: (accountId: string, word: string, isCorrect: boolean, timeSpent: number) => void;
  // Vocab CRUD
  addBook: (bookName: string) => void;
  deleteBook: (bookName: string) => void;
  updateBookName: (oldName: string, newName: string) => void;
  
  addUnit: (bookName: string, unitName: string) => void;
  deleteUnit: (bookName: string, unitName: string) => void;
  updateUnitName: (bookName: string, oldName: string, newName: string) => void;
  
  addWord: (bookName: string, unitName: string, word: Word) => void;
  deleteWord: (bookName: string, unitName: string, uid: string) => void;
  updateWord: (bookName: string, unitName: string, uid: string, word: Word) => void;
}

const defaultAccount: Account = {
  name: '默认账户',
  history: [],
  stats: {},
  settings: {
    allow_backward: true,
    allow_hint: false,
    timer_lock: true,
    per_q_time: 20.0,
    hide_test_config: false,
    hint_delay: 5,
    hint_limit: 0,
    folders: [],
  },
};

export const useAppStore = create<AppState>()(
  persist(
    (set, get) => ({
      vocab: {},
      accounts: {
        default: defaultAccount,
      },
      global_settings: {},
      currentAccountId: 'default',

      setVocab: (vocab) => set({ vocab }),
      setAccounts: (accounts) => set({ accounts }),
      setGlobalSettings: (global_settings) => set({ global_settings }),
      setCurrentAccountId: (currentAccountId) => set({ currentAccountId }),

      // Vocab CRUD Implementations
      addBook: (bookName) => set((state) => ({
        vocab: { ...state.vocab, [bookName]: {} }
      })),
      
      deleteBook: (bookName) => set((state) => {
        const newVocab = { ...state.vocab };
        delete newVocab[bookName];
        return { vocab: newVocab };
      }),
      
      updateBookName: (oldName, newName) => set((state) => {
        if (!state.vocab[oldName]) return state;
        const newVocab = { ...state.vocab };
        newVocab[newName] = newVocab[oldName];
        delete newVocab[oldName];
        return { vocab: newVocab };
      }),

      addUnit: (bookName, unitName) => set((state) => {
        if (!state.vocab[bookName]) return state;
        return {
          vocab: {
            ...state.vocab,
            [bookName]: { ...state.vocab[bookName], [unitName]: {} }
          }
        };
      }),

      deleteUnit: (bookName, unitName) => set((state) => {
        if (!state.vocab[bookName]) return state;
        const newBook = { ...state.vocab[bookName] };
        delete newBook[unitName];
        return {
          vocab: { ...state.vocab, [bookName]: newBook }
        };
      }),

      updateUnitName: (bookName, oldName, newName) => set((state) => {
        if (!state.vocab[bookName] || !state.vocab[bookName][oldName]) return state;
        const newBook = { ...state.vocab[bookName] };
        newBook[newName] = newBook[oldName];
        delete newBook[oldName];
        return {
          vocab: { ...state.vocab, [bookName]: newBook }
        };
      }),

      addWord: (bookName, unitName, word) => set((state) => {
        if (!state.vocab[bookName] || !state.vocab[bookName][unitName]) return state;
        return {
          vocab: {
            ...state.vocab,
            [bookName]: {
              ...state.vocab[bookName],
              [unitName]: {
                ...state.vocab[bookName][unitName],
                [word._uid]: word
              }
            }
          }
        };
      }),

      deleteWord: (bookName, unitName, uid) => set((state) => {
        if (!state.vocab[bookName] || !state.vocab[bookName][unitName]) return state;
        const newUnit = { ...state.vocab[bookName][unitName] };
        delete newUnit[uid];
        return {
          vocab: {
            ...state.vocab,
            [bookName]: {
              ...state.vocab[bookName],
              [unitName]: newUnit
            }
          }
        };
      }),

      updateWord: (bookName, unitName, uid, word) => set((state) => {
        if (!state.vocab[bookName] || !state.vocab[bookName][unitName]) return state;
        return {
          vocab: {
            ...state.vocab,
            [bookName]: {
              ...state.vocab[bookName],
              [unitName]: {
                ...state.vocab[bookName][unitName],
                [uid]: word
              }
            }
          }
        };
      }),

      getCurrentAccount: () => {
        const { accounts, currentAccountId } = get();
        return accounts[currentAccountId] || accounts['default'];
      },

      updateAccountSettings: (id, settings) =>
        set((state) => ({
          accounts: {
            ...state.accounts,
            [id]: {
              ...state.accounts[id],
              settings: {
                ...state.accounts[id].settings,
                ...settings,
              },
            },
          },
        })),

      addHistory: (accountId, historyItem) =>
        set((state) => ({
          accounts: {
            ...state.accounts,
            [accountId]: {
              ...state.accounts[accountId],
              history: [...(state.accounts[accountId]?.history || []), historyItem],
            },
          },
        })),

      updateWordStats: (accountId, wordText, isCorrect, timeSpent) =>
        set((state) => {
          const account = state.accounts[accountId];
          if (!account) return state;

          const stats = { ...(account.stats || {}) };
          const wordStat = stats[wordText] || {
            total: 0,
            correct: 0,
            wrong: 0,
            cumulative_seconds: 0,
            history: [],
          };

          const newWordStat = {
            ...wordStat,
            total: wordStat.total + 1,
            correct: isCorrect ? wordStat.correct + 1 : wordStat.correct,
            wrong: !isCorrect ? wordStat.wrong + 1 : Math.max(0, wordStat.wrong - 1),
            cumulative_seconds: wordStat.cumulative_seconds + timeSpent,
            history: [
              ...wordStat.history,
              {
                time: new Date().toLocaleString(),
                result: isCorrect ? '对' : '错',
              },
            ],
          };

          return {
            accounts: {
              ...state.accounts,
              [accountId]: {
                ...account,
                stats: {
                  ...stats,
                  [wordText]: newWordStat,
                },
              },
            },
          };
        }),

      loadInitialData: () => {
        const { accounts } = get();
        if (!accounts || Object.keys(accounts).length === 0) {
          set({
            accounts: {
              default: defaultAccount,
            },
            currentAccountId: 'default',
          });
        }
      },
    }),
    {
      name: '应用配置/全局数据',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
