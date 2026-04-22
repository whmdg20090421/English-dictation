import { db } from "./db";

export type Role = "Super Admin" | "Admin" | "User";

export interface Account {
  id: number;
  username: string;
  role: Role;
  created_at: string;
}

export function getAccounts(): Account[] {
  return db.getAllSync<Account>("SELECT * FROM Accounts ORDER BY created_at DESC;");
}

export function createAccount(username: string, role: Role = "User"): number {
  const result = db.runSync(
    "INSERT INTO Accounts (username, role) VALUES (?, ?)",
    username,
    role
  );
  return result.lastInsertRowId;
}

export function updateAccountName(id: number, username: string) {
  db.runSync("UPDATE Accounts SET username = ? WHERE id = ?", username, id);
}

export function deleteAccountFromDB(id: number) {
  db.runSync("DELETE FROM Accounts WHERE id = ?", id);
}

export function getSetting(key: string): string | null {
  const row = db.getFirstSync<{ value: string }>("SELECT value FROM Settings WHERE key = ?", key);
  return row ? row.value : null;
}

export function setSetting(key: string, value: string) {
  db.runSync("INSERT OR REPLACE INTO Settings (key, value) VALUES (?, ?)", key, value);
}

export function getDictationStats(accountId: number) {
  const sessions = db.getAllSync<{ id: number }>(
    "SELECT id FROM DictationSessions WHERE account_id = ? AND status = 'completed'",
    accountId
  );
  
  const dictationTimes = sessions.length;

  const words = db.getAllSync<{ is_correct: number }>(
    "SELECT is_correct FROM DictationWords dw JOIN DictationSessions ds ON dw.session_id = ds.id WHERE ds.account_id = ? AND ds.status = 'completed'",
    accountId
  );

  const wordsPracticed = words.length;
  const correctWords = words.filter((w) => w.is_correct === 1).length;
  const accuracy = wordsPracticed > 0 ? (correctWords / wordsPracticed) * 100 : 0;

  return { dictationTimes, wordsPracticed, accuracy };
}

export function getMistakeWords(accountId: number) {
  return db.getAllSync<{ vocab_id: number, word: string, meaning: string, wrong_count: number }>(`
    SELECT v.id as vocab_id, v.word, v.meaning, COUNT(dw.id) as wrong_count
    FROM DictationWords dw
    JOIN DictationSessions ds ON dw.session_id = ds.id
    JOIN Vocab v ON dw.vocab_id = v.id
    WHERE ds.account_id = ? AND ds.status = 'completed' AND dw.is_correct = 0
    GROUP BY v.id
    HAVING wrong_count > 0
    ORDER BY wrong_count DESC
  `, accountId);
}

export function getUnfinishedSession(accountId: number) {
  return db.getFirstSync<{ id: number, created_at: string, mode: string }>(
    "SELECT id, created_at, mode FROM DictationSessions WHERE account_id = ? AND status = 'in_progress' ORDER BY created_at DESC LIMIT 1",
    accountId
  );
}

export function createSession(accountId: number, mode: string = 'spelling') {
  const result = db.runSync("INSERT INTO DictationSessions (account_id, status, mode) VALUES (?, 'in_progress', ?)", accountId, mode);
  return result.lastInsertRowId;
}

export function createSessionWithWords(accountId: number, mode: string, vocabIds: number[]) {
  const sessionId = createSession(accountId, mode);
  const stmt = db.prepareSync("INSERT INTO DictationWords (session_id, vocab_id) VALUES (?, ?)");
  for (const vid of vocabIds) {
    stmt.executeSync([sessionId, vid]);
  }
  stmt.finalizeSync();
  return sessionId;
}

export function getSession(sessionId: number) {
  return db.getFirstSync<{ id: number, account_id: number, status: string, mode: string, created_at: string }>(
    "SELECT id, account_id, status, mode, created_at FROM DictationSessions WHERE id = ?",
    sessionId
  );
}

export function getSessionWords(sessionId: number) {
  return db.getAllSync<{ id: number, vocab_id: number, is_correct: number | null, user_input: string | null, word: string, meaning: string, pos: string }>(
    "SELECT dw.id, dw.vocab_id, dw.is_correct, dw.user_input, v.word, v.meaning, v.pos FROM DictationWords dw JOIN Vocab v ON dw.vocab_id = v.id WHERE dw.session_id = ?",
    sessionId
  );
}

export function updateDictationWord(dwId: number, userInput: string, isCorrect: number) {
  db.runSync("UPDATE DictationWords SET user_input = ?, is_correct = ? WHERE id = ?", userInput, isCorrect, dwId);
}

export function completeSession(sessionId: number) {
  db.runSync("UPDATE DictationSessions SET status = 'completed', completed_at = CURRENT_TIMESTAMP WHERE id = ?", sessionId);
}

export function getFolders() {
  return db.getAllSync<{ book: string }>("SELECT DISTINCT IFNULL(book, '未分类') as book FROM Vocab ORDER BY book");
}

export function getUnits(book: string) {
  if (book === '未分类') {
    return db.getAllSync<{ unit: string }>("SELECT DISTINCT IFNULL(unit, '未分类') as unit FROM Vocab WHERE book IS NULL OR book = '未分类' ORDER BY unit");
  }
  return db.getAllSync<{ unit: string }>("SELECT DISTINCT IFNULL(unit, '未分类') as unit FROM Vocab WHERE book = ? ORDER BY unit", book);
}

export function getWordsForUnit(book: string, unit: string) {
  let query = "SELECT id, word, meaning, pos FROM Vocab WHERE 1=1";
  const params: any[] = [];
  if (book === '未分类') {
    query += " AND (book IS NULL OR book = '未分类')";
  } else {
    query += " AND book = ?";
    params.push(book);
  }
  if (unit === '未分类') {
    query += " AND (unit IS NULL OR unit = '未分类')";
  } else {
    query += " AND unit = ?";
    params.push(unit);
  }
  query += " ORDER BY sort_order, id";
  return db.getAllSync<{ id: number, word: string, meaning: string, pos: string }>(query, ...params);
}

export function getVocabTreeStats(accountId: number) {
  return db.getAllSync<{
    id: number, word: string, meaning: string, pos: string, book: string, unit: string,
    total_tests: number, wrong_count: number
  }>(`
    SELECT 
      v.id, v.word, v.meaning, v.pos, IFNULL(v.book, '未分类') as book, IFNULL(v.unit, '未分类') as unit, 
      COUNT(dw.id) as total_tests, 
      SUM(CASE WHEN dw.is_correct = 0 THEN 1 ELSE 0 END) as wrong_count 
    FROM Vocab v 
    LEFT JOIN (
      SELECT dw2.vocab_id, dw2.id, dw2.is_correct 
      FROM DictationWords dw2 
      JOIN DictationSessions ds2 ON dw2.session_id = ds2.id 
      WHERE ds2.account_id = ? AND ds2.status = 'completed'
    ) dw ON v.id = dw.vocab_id
    GROUP BY v.id
    ORDER BY book, unit, v.sort_order, v.id
  `, accountId);
}

export function getWordHistory(accountId: number, vocabId: number) {
  return db.getAllSync<{
    is_correct: number, created_at: string
  }>(`
    SELECT dw.is_correct, ds.created_at
    FROM DictationWords dw
    JOIN DictationSessions ds ON dw.session_id = ds.id
    WHERE ds.account_id = ? AND dw.vocab_id = ? AND ds.status = 'completed'
    ORDER BY ds.created_at DESC
    LIMIT 50
  `, accountId, vocabId);
}

export function getFolderSessions(accountId: number, book: string, unit?: string) {
  let query = `
    SELECT DISTINCT ds.id, ds.created_at
    FROM DictationSessions ds
    JOIN DictationWords dw ON ds.id = dw.session_id
    JOIN Vocab v ON dw.vocab_id = v.id
    WHERE ds.account_id = ? AND ds.status = 'completed' AND IFNULL(v.book, '未分类') = ?
  `;
  const params: any[] = [accountId, book];
  if (unit !== undefined) {
    query += ` AND IFNULL(v.unit, '未分类') = ?`;
    params.push(unit);
  }
  query += ` ORDER BY ds.created_at DESC LIMIT 50`;
  return db.getAllSync<{ id: number, created_at: string }>(query, ...params);
}
