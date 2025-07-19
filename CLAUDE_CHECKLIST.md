# Pre-Commit Checklist für Claude Code

**WICHTIG**: Diese Checks MÜSSEN vor jedem Commit lokal durchgeführt werden!

## 🧪 Tests
```bash
# Alle BATS Tests müssen grün sein
bats tests/test_vpnctl.bats
# Erwartung: Alle Tests "ok", keine Fehler
```

## 🔍 Linting & Style
```bash
# Shellcheck muss ohne Warnungen durchlaufen
shellcheck bin/vpnctl
# Erwartung: Keine Ausgabe = Erfolg

# Shellcheck auf Test-Skripte
shellcheck tests/*.sh
# Erwartung: Keine Warnungen oder Fehler
```

## ⚡ Funktionalität
```bash
# Basis-Funktionalität testen
./bin/vpnctl --version
./bin/vpnctl status
# Erwartung: Korrekte Ausgabe, keine Fehler
```

## 📋 Commit-Workflow

1. **Lokale Checks ausführen**:
   ```bash
   bats tests/test_vpnctl.bats && \
   shellcheck bin/vpnctl && \
   ./bin/vpnctl --version
   ```

2. **Nur bei allen grünen Checks**: `git commit`

3. **Nach Push**: CI-Pipeline überwachen

## 🚫 Niemals committen wenn:
- Tests fehlschlagen
- Shellcheck Warnungen zeigt  
- Basis-Funktionalität nicht funktioniert
- CI Pipeline rot wird

**Ziel**: Keine Überraschungen mehr in der CI!