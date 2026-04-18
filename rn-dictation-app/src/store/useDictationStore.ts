import { create } from 'zustand';
import { Word } from '../types/models';

interface TestWord extends Word {
  // Add any extra fields needed during test, e.g. target definition
  target_definition?: string;
  target_pos?: string;
}

interface Answer {
  q_index: number;
  word: string;
  correct: boolean;
  score_val: number;
  time_spent: number;
  user_input?: string;
}

interface DictationState {
  currentView: 'home' | 'test_config' | 'testing' | 'result' | 'admin' | 'mistake_book' | 'history';
  testMode: string;
  testQueue: TestWord[];
  currentQIndex: number;
  userAnswers: Record<number, Answer>;
  
  perQTime: number;
  totalTime: number;
  qTimeLeft: number;
  totLeft: number;

  allowBackward: boolean;
  allowHint: boolean;
  usedHints: number[];

  // Actions
  setCurrentView: (view: DictationState['currentView']) => void;
  setTestConfig: (config: Partial<DictationState>) => void;
  startTest: (queue: TestWord[], mode: string, config: any) => void;
  submitAnswer: (index: number, answer: Answer) => void;
  nextQuestion: () => void;
  prevQuestion: () => void;
  resetTest: () => void;
}

export const useDictationStore = create<DictationState>((set) => ({
  currentView: 'home',
  testMode: '',
  testQueue: [],
  currentQIndex: 0,
  userAnswers: {},
  
  perQTime: 20.0,
  totalTime: 0.0,
  qTimeLeft: 20.0,
  totLeft: 0.0,

  allowBackward: true,
  allowHint: false,
  usedHints: [],

  setCurrentView: (currentView) => set({ currentView }),
  
  setTestConfig: (config) => set((state) => ({ ...state, ...config })),
  
  startTest: (queue, mode, config) => set({
    testQueue: queue,
    testMode: mode,
    currentQIndex: 0,
    userAnswers: {},
    usedHints: [],
    ...config,
    currentView: 'testing'
  }),
  
  submitAnswer: (index, answer) => set((state) => ({
    userAnswers: {
      ...state.userAnswers,
      [index]: answer
    }
  })),
  
  nextQuestion: () => set((state) => ({
    currentQIndex: Math.min(state.currentQIndex + 1, state.testQueue.length - 1)
  })),
  
  prevQuestion: () => set((state) => ({
    currentQIndex: Math.max(state.currentQIndex - 1, 0)
  })),
  
  resetTest: () => set({
    testQueue: [],
    testMode: '',
    currentQIndex: 0,
    userAnswers: {},
    usedHints: [],
    currentView: 'home'
  })
}));
