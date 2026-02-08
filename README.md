# Cadastro Municipal Offline — v0.4 (Starter Autoral)

v0.4 adiciona:
- **SYNC PULL incremental** (app recebe atualizações do servidor)
- **Proteção contra sobrescrever alterações locais** (se existir outbox pendente para um registro, o pull ignora aquele UUID)
- **Admin Web (React/Vite) mínimo** com login JWT e telas:
  - Pendências CPF
  - Conflitos de sincronização
  - Stats simples

## Subir backend + DB
```bash
cd backend
docker compose up --build
```
Swagger: http://localhost:8000/docs

Criar usuário:
`POST /auth/register`
```json
{"email":"admin@demo.com","password":"123456","role":"admin"}
```

## Rodar Gateway
```bash
cd gateway
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
UPSTREAM_URL=http://localhost:8000 python -m gateway.main
```

## App Flutter
```bash
cd mobile
flutter pub get
flutter run
```

## Admin Web
```bash
cd web
npm install
npm run dev
```
Abra: http://localhost:5173


## Executáveis (APK/EXE/PWA)
Veja **BUILD_EXECUTAVEIS.md**.
