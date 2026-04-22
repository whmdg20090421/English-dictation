import React, { createContext, useContext, useState, useEffect } from "react";
import { getAccounts, createAccount as dbCreateAccount, updateAccountName, deleteAccountFromDB, getSetting, setSetting, Account, Role } from "./dbHelpers";

interface AccountContextProps {
  accounts: Account[];
  activeAccount: Account | null;
  createAccount: (username: string, role: Role) => void;
  switchAccount: (id: number) => void;
  renameAccount: (id: number, username: string) => void;
  deleteAccount: (id: number) => void;
}

const AccountContext = createContext<AccountContextProps | undefined>(undefined);

export function AccountProvider({ children }: { children: React.ReactNode }) {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [activeAccount, setActiveAccount] = useState<Account | null>(null);

  useEffect(() => {
    loadAccounts();
  }, []);

  const loadAccounts = () => {
    try {
      const allAccounts = getAccounts();
      setAccounts(allAccounts);

      const lastActiveId = getSetting("last_active_account_id");
      if (lastActiveId) {
        const found = allAccounts.find(a => a.id.toString() === lastActiveId);
        if (found) {
          setActiveAccount(found);
        } else if (allAccounts.length > 0) {
          setActiveAccount(allAccounts[0]);
        }
      } else if (allAccounts.length > 0) {
        setActiveAccount(allAccounts[0]);
      }
    } catch (e) {
      console.error(e);
    }
  };

  const createAccount = (username: string, role: Role) => {
    const newId = dbCreateAccount(username, role);
    const newAccount: Account = { id: newId as number, username, role, created_at: new Date().toISOString() };
    setAccounts(prev => [newAccount, ...prev]);
    switchAccount(newId as number);
  };

  const switchAccount = (id: number) => {
    const found = accounts.find(a => a.id === id);
    if (found) {
      setActiveAccount(found);
      setSetting("last_active_account_id", id.toString());
    }
  };

  const renameAccount = (id: number, username: string) => {
    updateAccountName(id, username);
    setAccounts(prev => prev.map(a => a.id === id ? { ...a, username } : a));
    if (activeAccount?.id === id) {
      setActiveAccount(prev => prev ? { ...prev, username } : prev);
    }
  };

  const deleteAccount = (id: number) => {
    deleteAccountFromDB(id);
    const updatedAccounts = accounts.filter(a => a.id !== id);
    setAccounts(updatedAccounts);
    if (activeAccount?.id === id) {
      const nextActive = updatedAccounts.length > 0 ? updatedAccounts[0] : null;
      setActiveAccount(nextActive);
      if (nextActive) {
        setSetting("last_active_account_id", nextActive.id.toString());
      } else {
        setSetting("last_active_account_id", "");
      }
    }
  };

  return (
    <AccountContext.Provider value={{ accounts, activeAccount, createAccount, switchAccount, renameAccount, deleteAccount }}>
      {children}
    </AccountContext.Provider>
  );
}

export function useAccount() {
  const context = useContext(AccountContext);
  if (!context) {
    throw new Error("useAccount must be used within an AccountProvider");
  }
  return context;
}
