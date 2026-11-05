#!/usr/bin/env bash
# Vérifie toute la chaîne, dans le dev container : outils, base, API, IA.
# Usage : npm run verifier   (avec npm run dev lancé dans un autre terminal pour l'API et l'IA)

ok=0
check() {
  # $1 : libellé, $2 : commande à tester
  if eval "$2" >/dev/null 2>&1; then
    echo "  ✔ $1"
  else
    echo "  ✘ $1"
    ok=1
  fi
}

# api/.env : DATABASE_URL, AI_BASE_URL…
if [ -f api/.env ]; then
  set -a
  # shellcheck disable=SC1091
  . api/.env
  set +a
fi

echo "Outils"
check "Node 24 ($(node -v 2>/dev/null))" 'node -v | grep -q "^v24"'
check "psql 17" 'psql --version | grep -q " 17"'
check "api/.env présent" 'test -f api/.env'
check "dépendances installées (node_modules)" 'test -d node_modules'
check "Python 3.12 ($(python --version 2>/dev/null))" 'python --version | grep -q "3\.12"'
check "environnement Python de ia/ (FastAPI installé)" 'ia/.venv/bin/python -c "import fastapi"'

echo "Base de données"
check "PostgreSQL répond (db:5432)" 'psql "$DATABASE_URL" -c "SELECT 1"'
check "table questions présente" 'psql "$DATABASE_URL" -c "SELECT 1 FROM questions LIMIT 1"'

echo "API (npm run dev doit tourner)"
check "GET /api/health" 'curl -fs localhost:3000/api/health | grep -q "\"status\":\"ok\""'
check "GET /api/questions" 'curl -fs localhost:3000/api/questions | grep -q "\"question\""'

echo "Front (npm run dev doit tourner)"
check "Vite répond sur 5173, proxy /api" 'curl -fs localhost:5173/api/health | grep -q "\"status\":\"ok\""'

echo "IA"
if [ -n "$DATA_AI_URL" ]; then
  check "API Data/IA joignable ($DATA_AI_URL/docs)" 'curl -fs --max-time 10 "$DATA_AI_URL/docs"'
else
  check "fournisseur joignable ($AI_BASE_URL)" 'curl -fs --max-time 10 -H "Authorization: Bearer $AI_API_KEY" "$AI_BASE_URL/models"'
  # Joignable ne suffit pas : le modèle configuré doit être disponible (ollama pull …)
  check "modèle $AI_MODEL disponible" 'curl -fs --max-time 10 -H "Authorization: Bearer $AI_API_KEY" "$AI_BASE_URL/models" | grep -q "\"$AI_MODEL\""'
fi

# Le service Data/IA est optionnel : une information, pas un échec
if curl -fs --max-time 3 localhost:8000/health >/dev/null 2>&1; then
  echo "  ✔ service Data/IA (npm run dev:ia) répond sur 8000"
else
  echo "  · service Data/IA non lancé (npm run dev:ia), optionnel"
fi

if [ "$ok" -eq 0 ]; then
  echo "Tout est vert."
else
  echo "Au moins un contrôle a échoué : voir le README, section Dépannage."
fi
exit "$ok"
