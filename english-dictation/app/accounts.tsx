import React, { useState } from "react";
import { FlatList, View, TextInput, Alert, TouchableOpacity } from "react-native";
import { ScreenContainer, GlassCard, Typography, GlassButton } from "../components/theme";
import { useAccount } from "../lib/AccountContext";
import { Role } from "../lib/dbHelpers";
import { Ionicons } from "@expo/vector-icons";

export default function AccountsScreen() {
  const { accounts, activeAccount, createAccount, switchAccount, renameAccount, deleteAccount } = useAccount();
  const [newUsername, setNewUsername] = useState("");
  const [newRole, setNewRole] = useState<Role>("User");
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editUsername, setEditUsername] = useState("");

  const handleCreate = () => {
    if (!newUsername.trim()) return;
    createAccount(newUsername.trim(), newRole);
    setNewUsername("");
    setNewRole("User");
  };

  const handleRename = (id: number) => {
    if (!editUsername.trim()) return;
    renameAccount(id, editUsername.trim());
    setEditingId(null);
  };

  const handleDelete = (id: number) => {
    Alert.alert("确认删除", "删除账户将丢失所有相关数据，是否继续？", [
      { text: "取消", style: "cancel" },
      { text: "删除", style: "destructive", onPress: () => deleteAccount(id) }
    ]);
  };

  return (
    <ScreenContainer>
      <GlassCard className="mb-4">
        <Typography variant="h2">添加新账户</Typography>
        <TextInput
          className="bg-darkblue-900/50 text-white p-3 rounded-lg mb-3 border border-darkblue-300/30"
          placeholder="用户名"
          placeholderTextColor="#8ba1b5"
          value={newUsername}
          onChangeText={setNewUsername}
        />
        <View className="flex-row mb-4 justify-between">
          {(["User", "Admin", "Super Admin"] as Role[]).map((r) => (
            <TouchableOpacity
              key={r}
              onPress={() => setNewRole(r)}
              className={`px-3 py-2 rounded-lg border ${newRole === r ? 'bg-blue-500 border-blue-400' : 'bg-darkblue-800 border-darkblue-300/30'}`}
            >
              <Typography variant="caption">{r}</Typography>
            </TouchableOpacity>
          ))}
        </View>
        <GlassButton onPress={handleCreate}>
          <Typography variant="body" className="font-bold">创建</Typography>
        </GlassButton>
      </GlassCard>

      <FlatList
        data={accounts}
        keyExtractor={item => item.id.toString()}
        renderItem={({ item }) => (
          <GlassCard className={`mb-3 flex-row justify-between items-center p-4 ${activeAccount?.id === item.id ? 'border-blue-400/50' : ''}`}>
            {editingId === item.id ? (
              <View className="flex-1 mr-2">
                <TextInput
                  className="bg-darkblue-900/50 text-white p-2 rounded border border-darkblue-300/30 mb-2"
                  value={editUsername}
                  onChangeText={setEditUsername}
                />
                <View className="flex-row gap-2">
                  <GlassButton onPress={() => handleRename(item.id)} className="py-1 px-3 flex-1">
                    <Typography variant="caption">保存</Typography>
                  </GlassButton>
                  <GlassButton onPress={() => setEditingId(null)} className="py-1 px-3 flex-1 bg-gray-600">
                    <Typography variant="caption">取消</Typography>
                  </GlassButton>
                </View>
              </View>
            ) : (
              <TouchableOpacity className="flex-1" onPress={() => switchAccount(item.id)}>
                <Typography variant="h2" className="mb-1 text-lg">
                  {item.username} {activeAccount?.id === item.id && "(当前)"}
                </Typography>
                <Typography variant="caption">{item.role}</Typography>
              </TouchableOpacity>
            )}

            {editingId !== item.id && (
              <View className="flex-row gap-3">
                <TouchableOpacity onPress={() => { setEditingId(item.id); setEditUsername(item.username); }}>
                  <Ionicons name="pencil" size={20} color="#8ba1b5" />
                </TouchableOpacity>
                <TouchableOpacity onPress={() => handleDelete(item.id)}>
                  <Ionicons name="trash" size={20} color="#ef4444" />
                </TouchableOpacity>
              </View>
            )}
          </GlassCard>
        )}
      />
    </ScreenContainer>
  );
}
