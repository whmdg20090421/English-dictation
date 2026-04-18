export interface Word {
  单词: string;
  _uid: string;
  source_book?: string;
  _ask_pos?: string;
  _test_mode?: string;
  [key: string]: string | undefined;
}

export type Unit = Record<string, Word>; // UID -> Word
export type Book = Record<string, Unit>; // Unit Name -> Unit
export type Vocab = Record<string, Book>; // Book Name -> Book

export interface WordStats {
  total: number;
  correct: number;
  wrong: number;
  cumulative_seconds: number;
  history: { time: string; result: string }[];
}

export interface AccountSettings {
  allow_backward: boolean;
  allow_hint: boolean;
  timer_lock: boolean;
  per_q_time: number;
  hide_test_config: boolean;
  hint_delay: number;
  hint_limit: number;
  folders: string[];
}

export interface AnswerDetail {
  q_index?: number;
  word?: string;
  correct?: boolean;
  score_val?: number;
  time_spent?: number;
  [key: string]: any;
}

export interface AccountHistory {
  timestamp: string;
  mode: string;
  score: number;
  total: number;
  correct: number;
  score_val: number;
  used_hints: number;
  status: string;
  details: AnswerDetail[];
}

export interface Account {
  name: string;
  history: AccountHistory[];
  stats: Record<string, WordStats>;
  settings: AccountSettings;
}

export interface GlobalSettings {
  password?: string;
  [key: string]: any;
}

export interface AppData {
  vocab: Vocab;
  accounts: Record<string, Account>;
  global_settings: GlobalSettings;
}
