import { API_BASE } from "./config";

export function getToken(): string { return localStorage.getItem("jwt") || ""; }
export function setToken(t: string) { localStorage.setItem("jwt", t); }
export function clearToken() { localStorage.removeItem("jwt"); }

export async function login(email: string, password: string): Promise<string> {
  const r = await fetch(`${API_BASE}/auth/login`, {
    method: "POST",
    headers: {"Content-Type":"application/json"},
    body: JSON.stringify({email, password}),
  });
  if (!r.ok) throw new Error(`Login falhou: ${r.status}`);
  const data = await r.json();
  return data.access_token as string;
}

export async function me(): Promise<{email:string,role:string}> {
  const r = await fetch(`${API_BASE}/me`, { headers: {Authorization:`Bearer ${getToken()}`}});
  if (!r.ok) throw new Error(`Falha /me: ${r.status}`);
  return r.json();
}

export async function stats() {
  const r = await fetch(`${API_BASE}/admin/api/stats`, { headers: {Authorization:`Bearer ${getToken()}`}});
  if (!r.ok) throw new Error(`Stats: ${r.status}`);
  return r.json();
}

export async function pendingCpf() {
  const r = await fetch(`${API_BASE}/admin/api/pending-cpf`, { headers: {Authorization:`Bearer ${getToken()}`}});
  if (!r.ok) throw new Error(`Pending CPF: ${r.status}`);
  return r.json();
}

export async function conflicts() {
  const r = await fetch(`${API_BASE}/admin/api/conflicts`, { headers: {Authorization:`Bearer ${getToken()}`}});
  if (!r.ok) throw new Error(`Conflicts: ${r.status}`);
  return r.json();
}
