import React, { useState } from "react";

export default function Login({ onLogin }: { onLogin: (email: string, password: string) => Promise<void> }) {
  const [email, setEmail] = useState("admin@demo.com");
  const [password, setPassword] = useState("123456");
  const [err, setErr] = useState("");

  return (
    <div style={{maxWidth:420, margin:"40px auto", padding:20, border:"1px solid #ddd", borderRadius:12}}>
      <h2>Admin - Login</h2>
      <div style={{display:"flex", flexDirection:"column", gap:10}}>
        <input value={email} onChange={e=>setEmail(e.target.value)} placeholder="email" />
        <input value={password} onChange={e=>setPassword(e.target.value)} placeholder="senha" type="password" />
        <button onClick={async ()=>{
          setErr("");
          try { await onLogin(email, password); } catch (e:any) { setErr(e.message || "erro"); }
        }}>Entrar</button>
        {err && <div style={{color:"crimson"}}>{err}</div>}
      </div>
      <p style={{fontSize:12, color:"#555"}}>Requer role supervisor/admin para stats/pendências/conflitos.</p>
    </div>
  );
}
