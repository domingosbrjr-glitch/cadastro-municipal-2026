import React, { useEffect, useState } from "react";
import { clearToken, getToken, login, me, setToken } from "../api";
import Dashboard from "./Dashboard";
import Login from "./Login";

export default function App() {
  const [ready, setReady] = useState(false);
  const [user, setUser] = useState<{email:string,role:string} | null>(null);

  async function refreshMe() {
    if (!getToken()) { setUser(null); setReady(true); return; }
    try {
      const u = await me();
      setUser(u);
    } catch {
      clearToken();
      setUser(null);
    } finally {
      setReady(true);
    }
  }

  useEffect(() => { refreshMe(); }, []);

  async function doLogin(email: string, password: string) {
    const t = await login(email, password);
    setToken(t);
    await refreshMe();
  }

  function doLogout() {
    clearToken();
    setUser(null);
  }

  if (!ready) return <div style={{padding:20}}>Carregando...</div>;
  if (!user) return <Login onLogin={doLogin} />;
  return <Dashboard user={user} onLogout={doLogout} />;
}
