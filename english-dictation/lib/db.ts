import * as SQLite from "expo-sqlite";

export const db = SQLite.openDatabaseSync("english_dictation.db");

export function initDB() {
  db.execSync("PRAGMA foreign_keys = ON;");

  // Create Accounts table
  db.execSync(`
    CREATE TABLE IF NOT EXISTS Accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      role TEXT DEFAULT 'User', -- 'Super Admin', 'Admin', 'User'
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  `);

  // Create Vocab table
  db.execSync(`
    CREATE TABLE IF NOT EXISTS Vocab (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book TEXT,
      unit TEXT,
      word TEXT NOT NULL,
      meaning TEXT,
      pos TEXT, -- part of speech
      account_id INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (account_id) REFERENCES Accounts(id) ON DELETE CASCADE
    );
  `);

  // Add columns if they don't exist for existing db
  try {
    db.execSync("ALTER TABLE Vocab ADD COLUMN book TEXT;");
  } catch (e) { /* ignore */ }
  try {
    db.execSync("ALTER TABLE Vocab ADD COLUMN unit TEXT;");
  } catch (e) { /* ignore */ }
  try {
    db.execSync("ALTER TABLE Vocab ADD COLUMN sort_order INTEGER DEFAULT 0;");
  } catch (e) { /* ignore */ }

  // Create DictationSessions table
  db.execSync(`
    CREATE TABLE IF NOT EXISTS DictationSessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account_id INTEGER NOT NULL,
      status TEXT DEFAULT 'in_progress', -- 'in_progress', 'completed'
      mode TEXT DEFAULT 'spelling', -- 'spelling', 'meaning', 'mixed'
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      completed_at DATETIME,
      FOREIGN KEY (account_id) REFERENCES Accounts(id) ON DELETE CASCADE
    );
  `);

  try {
    db.execSync("ALTER TABLE DictationSessions ADD COLUMN mode TEXT DEFAULT 'spelling';");
  } catch (e) { /* ignore */ }


  // Create DictationWords table
  db.execSync(`
    CREATE TABLE IF NOT EXISTS DictationWords (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL,
      vocab_id INTEGER NOT NULL,
      is_correct INTEGER DEFAULT 0,
      user_input TEXT,
      FOREIGN KEY (session_id) REFERENCES DictationSessions(id) ON DELETE CASCADE,
      FOREIGN KEY (vocab_id) REFERENCES Vocab(id) ON DELETE CASCADE
    );
  `);

  // Create Settings table
  db.execSync(`
    CREATE TABLE IF NOT EXISTS Settings (
      key TEXT PRIMARY KEY,
      value TEXT
    );
  `);

  // Create SyncQueue table
  db.execSync(`
    CREATE TABLE IF NOT EXISTS SyncQueue (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      action TEXT NOT NULL,
      payload TEXT,
      status TEXT DEFAULT 'pending',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  `);
}

export function resetDB() {
  db.execSync(`DROP TABLE IF EXISTS DictationWords;`);
  db.execSync(`DROP TABLE IF EXISTS DictationSessions;`);
  db.execSync(`DROP TABLE IF EXISTS Accounts;`);
  db.execSync(`DROP TABLE IF EXISTS Vocab;`);
  db.execSync(`DROP TABLE IF EXISTS Settings;`);
  db.execSync(`DROP TABLE IF EXISTS SyncQueue;`);
  initDB();
}

/**
 * Auto-fix the POS (part of speech) column in the Vocab table.
 * For example, if POS is empty but the meaning starts with "n. " or "v. ",
 * it extracts the POS and updates the record.
 */
export function autoFixVocabPOS() {
  const allVocabs = db.getAllSync<{id: number, word: string, meaning: string, pos: string | null}>(
    `SELECT id, word, meaning, pos FROM Vocab;`
  );

  let fixCount = 0;
  
  for (const vocab of allVocabs) {
    if (!vocab.pos && vocab.meaning) {
      // Check if meaning starts with standard pos like n., v., adj., adv., etc.
      const match = vocab.meaning.match(/^(n\.|v\.|adj\.|adv\.|prep\.|pron\.|conj\.|int\.)\s*(.*)/i);
      if (match) {
        const extractedPos = match[1].toLowerCase();
        const cleanedMeaning = match[2];
        
        db.runSync(
          `UPDATE Vocab SET pos = ?, meaning = ? WHERE id = ?`,
          extractedPos,
          cleanedMeaning,
          vocab.id
        );
        fixCount++;
      }
    } else if (vocab.pos) {
      // Standardize existing pos
      const posMap: Record<string, string> = {
        'noun': 'n.',
        'verb': 'v.',
        'adjective': 'adj.',
        'adverb': 'adv.',
        'preposition': 'prep.',
        'pronoun': 'pron.',
        'conjunction': 'conj.',
        'interjection': 'int.'
      };
      const lowerPos = vocab.pos.toLowerCase().trim();
      if (posMap[lowerPos]) {
        db.runSync(`UPDATE Vocab SET pos = ? WHERE id = ?`, posMap[lowerPos], vocab.id);
        fixCount++;
      }
    }
  }
  
  return fixCount;
}
