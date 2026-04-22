import { useEffect, useState } from "react";
import { View, TouchableOpacity, Alert } from "react-native";
import { Link, useRouter } from "expo-router";
import { ScreenContainer, GlassCard, Typography, GlassButton } from "../components/theme";
import { useAccount } from "../lib/AccountContext";
import { getDictationStats, getUnfinishedSession, getMistakeWords } from "../lib/dbHelpers";
import { Ionicons } from "@expo/vector-icons";

export default function Index() {
  const { activeAccount } = useAccount();
  const router = useRouter();
  const [stats, setStats] = useState({ dictationTimes: 0, wordsPracticed: 0, accuracy: 0 });
  const [hasUnfinished, setHasUnfinished] = useState(false);
  const [mistakesCount, setMistakesCount] = useState(0);

  useEffect(() => {
    if (activeAccount) {
      const currentStats = getDictationStats(activeAccount.id);
      setStats(currentStats);

      const unfinished = getUnfinishedSession(activeAccount.id);
      if (unfinished) {
        Alert.alert("恢复听写", "检测到未完成的听写记录，是否继续？", [
          { text: "取消", style: "cancel", onPress: () => {
            // we could delete it, but let's just ignore for now
          } },
          { text: "继续", onPress: () => {
            router.push(`/testing?sessionId=${unfinished.id}`);
          } }
        ]);
        setHasUnfinished(true);
      }

      const mistakes = getMistakeWords(activeAccount.id);
      setMistakesCount(mistakes.length);
    }
  }, [activeAccount]);

  return (
    <ScreenContainer className="items-center">
      <View className="w-full flex-row justify-between items-center mb-6">
        <Typography variant="h2" className="mb-0">
          你好, {activeAccount?.username || "请登录"}
        </Typography>
        <Link href="/accounts" asChild>
          <TouchableOpacity className="p-2">
            <Ionicons name="person-circle" size={32} color="white" />
          </TouchableOpacity>
        </Link>
      </View>

      <GlassCard className="w-full mb-6">
        <Typography variant="h2" className="text-center mb-4">学习统计</Typography>
        <View className="flex-row justify-around">
          <View className="items-center">
            <Typography variant="h1" className="text-blue-400 mb-1">{stats.dictationTimes}</Typography>
            <Typography variant="caption">听写次数</Typography>
          </View>
          <View className="items-center">
            <Typography variant="h1" className="text-green-400 mb-1">{stats.wordsPracticed}</Typography>
            <Typography variant="caption">练习单词</Typography>
          </View>
          <View className="items-center">
            <Typography variant="h1" className="text-yellow-400 mb-1">{stats.accuracy.toFixed(1)}%</Typography>
            <Typography variant="caption">准确率</Typography>
          </View>
        </View>
      </GlassCard>

      <View className="w-full gap-4">
        <GlassButton className="w-full py-4 bg-blue-600/80" onPress={() => router.push("/select-content")}>
          <Typography variant="h2" className="mb-0">开始听写</Typography>
        </GlassButton>

        {mistakesCount > 0 && (
          <GlassButton className="w-full py-4 bg-orange-600/80" onPress={() => router.push("/mistakes")}>
            <Typography variant="h2" className="mb-0">错题重练 ({mistakesCount})</Typography>
          </GlassButton>
        )}

        <GlassButton className="w-full py-4 bg-teal-600/80" onPress={() => router.push("/data-browser")}>
          <Typography variant="h2" className="mb-0">数据浏览器</Typography>
        </GlassButton>

        {(activeAccount?.role === "Admin" || activeAccount?.role === "Super Admin") && (
          <GlassButton className="w-full py-4 bg-purple-600/80" onPress={() => router.push("/admin")}>
            <Typography variant="h2" className="mb-0">管理后台</Typography>
          </GlassButton>
        )}

        <GlassButton className="w-full py-4 bg-pink-600/80" onPress={() => router.push("/video-dictation")}>
          <Typography variant="h2" className="mb-0">视频字幕听写</Typography>
        </GlassButton>

        <Link href="/test-db" asChild>
          <GlassButton className="w-full bg-darkblue-800/80 mt-4">
            <Typography variant="h2" className="mb-0">数据库测试</Typography>
          </GlassButton>
        </Link>
      </View>
    </ScreenContainer>
  );
}