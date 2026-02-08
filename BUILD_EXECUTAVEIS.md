# Como gerar APP executável (Android / Windows / Web-PWA)

Este repositório contém:
- `mobile/` (Flutter) => **APK Android**, **Windows .exe** (opcional) e **Web/PWA**
- `backend/` (FastAPI) => API cloud
- `gateway/` (FastAPI) => gateway local (fila)

> Observação: o **APK/EXE não é gerado dentro do ChatGPT** porque aqui não há Flutter/Android SDK instalado.
> Mas com os comandos abaixo você gera o executável em minutos na sua máquina ou via GitHub Actions.

---

## 1) Android (APK release)

### Pré-requisitos (PC):
- Flutter SDK
- Android Studio (Android SDK + build-tools)

### Comandos:
```bash
cd mobile
flutter doctor
flutter pub get
flutter build apk --release
```

O APK sai em:
`mobile/build/app/outputs/flutter-apk/app-release.apk`

### Assinatura (Play Store)
Para publicar na loja, use `.aab`:
```bash
flutter build appbundle --release
```
Saída:
`mobile/build/app/outputs/bundle/release/app-release.aab`

---

## 2) Windows (executável .exe) — opcional

### Pré-requisitos:
- Flutter SDK
- Windows 10/11
- Visual Studio (Desktop development with C++)

### Comandos:
```powershell
cd mobile
flutter config --enable-windows-desktop
flutter doctor
flutter pub get
flutter build windows --release
```

Executável:
`mobile/build/windows/x64/runner/Release/cadastro_municipal_offline.exe`

---

## 3) Web / PWA (instalável no navegador)

```bash
cd mobile
flutter build web --release
```

Saída:
`mobile/build/web/`

Você pode hospedar esse `build/web` em qualquer servidor.

---

## 4) Gerar executáveis via GitHub Actions (automático)

Este repo já inclui workflows em `.github/workflows/` para:
- build de APK Android (artefato)
- build Web (artefato)

Basta subir o projeto no GitHub e rodar o workflow em Actions.


---

## IMPORTANTE (Windows .exe)
No Windows, o `.exe` **não é um arquivo único**: ele precisa ir junto com as DLLs e pastas da pasta:

`mobile/build/windows/x64/runner/Release/`

Para “entregar” o app, compacte essa pasta inteira. Script pronto:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\pack_windows_release.ps1
```

Ele gera:
`dist/cadastro_municipal_offline_windows_release.zip`
