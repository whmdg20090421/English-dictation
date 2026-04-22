import { useState, useEffect } from "react";
import { ScrollView, View } from "react-native";
import { ScreenContainer, GlassCard, Typography, GlassButton } from "../components/theme";
import { db, autoFixVocabPOS } from "../lib/db";

export default function TestDB() {
  const [vocabCount, setVocabCount] = useState(0);
  const [vocabList, setVocabList] = useState<any[]>([]);

  const loadData = () => {
    const list = db.getAllSync(`SELECT * FROM Vocab ORDER BY id DESC LIMIT 5`);
    setVocabList(list);
    const count: any = db.getFirstSync(`SELECT COUNT(*) as c FROM Vocab`);
    setVocabCount(count?.c || 0);
  };

  useEffect(() => {
    loadData();
  }, []);

  const addDummyWord = () => {
    db.runSync(
      `INSERT INTO Vocab (word, meaning, pos) VALUES (?, ?, ?)`,
      "apple", "n. A fruit", null
    );
    db.runSync(
      `INSERT INTO Vocab (word, meaning, pos) VALUES (?, ?, ?)`,
      "run", "v. To move fast", null
    );
    loadData();
  };

  const fixPOS = () => {
    const fixedCount = autoFixVocabPOS();
    alert(`Fixed ${fixedCount} records`);
    loadData();
  };

  return (
    <ScreenContainer>
      <ScrollView>
        <GlassCard className="mb-4">
          <Typography variant="h2">Database Status</Typography>
          <Typography variant="body">Total Vocabs: {vocabCount}</Typography>
        </GlassCard>

        <View className="flex-row gap-4 mb-6">
          <GlassButton className="flex-1" onPress={addDummyWord}>
            <Typography variant="body" className="font-bold">Add Dummy Words</Typography>
          </GlassButton>
          <GlassButton className="flex-1 bg-green-600/80" onPress={fixPOS}>
            <Typography variant="body" className="font-bold">Auto Fix POS</Typography>
          </GlassButton>
        </View>

        <Typography variant="h2" className="mb-4">Recent Words</Typography>
        {vocabList.map((v) => (
          <GlassCard key={v.id} className="mb-2 !p-4">
            <Typography variant="h2" className="mb-1">{v.word}</Typography>
            <Typography variant="body">Meaning: {v.meaning}</Typography>
            <Typography variant="caption">POS: {v.pos || "null"}</Typography>
          </GlassCard>
        ))}
      </ScrollView>
    </ScreenContainer>
  );
}