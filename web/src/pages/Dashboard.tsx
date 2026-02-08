import React, { useEffect, useState } from "react";
import { conflicts, pendingCpf, stats } from "../api";

type User = { email: string; role: string };

export default function Dashboard({ user, onLogout }: { user: User; onLogout: ()=>void }) {
  const [tab, setTab] = useState<"stats"|"pending"|"conflicts">("stats");
  const [data, setData] = useState<any>(null);
  const [err, setErr] = useState<string>("");

  async function load() {
    setErr("");
    try {
      if (tab === "stats") setData(await stats());
      if (tab === "pending") setData(await pendingCpf());
      if (tab === "conflicts") setData(await conflicts());
    } catch (e:any) {
      setErr(e.message || "erro");
      setData(null);
    }
  }

  useEffect(()=>{ load(); }, [tab]);

  return (
    <div style={{padding:20}}>
      <div style={{display:"flex", justifyContent:"space-between", alignItems:"center"}}>
        <h2>Admin</h2>
        <div>
          <span style={{marginRight:12}}>{user.email} ({user.role})</span>
          <button onClick={onLogout}>Sair</button>
        </div>
      </div>

      <div style={{display:"flex", gap:10, margin:"12px 0"}}>
        <button onClick={()=>setTab("stats")}>Stats</button>
        <button onClick={()=>setTab("pending")}>Pendências CPF</button>
        <button onClick={()=>setTab("conflicts")}>Conflitos</button>
        <button onClick={load}>Atualizar</button>
      </div>

      {err && <div style={{color:"crimson"}}>{err}</div>}
      {!data && !err && <div>Carregando...</div>}

      {tab === "stats" && data && (
        <div style={{display:"grid", gridTemplateColumns:"repeat(4, minmax(0, 1fr))", gap:10}}>
          {Object.entries(data).map(([k,v])=>(
            <div key={k} style={{border:"1px solid #ddd", borderRadius:12, padding:12}}>
              <div style={{fontSize:12, color:"#666"}}>{k}</div>
              <div style={{fontSize:22, fontWeight:700}}>{String(v)}</div>
            </div>
          ))}
        </div>
      )}

      {(tab === "pending" || tab === "conflicts") && data && (
        <div style={{overflowX:"auto"}}>
          <table cellPadding={8} style={{borderCollapse:"collapse", minWidth:900}}>
            <thead>
              <tr>
                {Object.keys(data[0] || {}).map(k => (
                  <th key={k} style={{borderBottom:"1px solid #ddd", textAlign:"left"}}>{k}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {data.map((row:any, idx:number)=>(
                <tr key={idx}>
                  {Object.keys(data[0] || {}).map(k => (
                    <td key={k} style={{borderBottom:"1px solid #f0f0f0"}}>{String(row[k] ?? "")}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
          {!data.length && <div>Nenhum registro.</div>}
        </div>
      )}
    </div>
  );
}
