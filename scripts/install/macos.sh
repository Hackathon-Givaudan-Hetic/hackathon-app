#!/usr/bin/env bash
# Prérequis du projet sur macOS (Apple Silicon ou Intel), à lancer une fois, avant le premier jour.
# Installe ce qui manque, ne touche pas à ce qui est déjà là. Peut être relancé sans risque.
#   bash scripts/install/macos.sh
# ou, sans avoir cloné le dépôt :
#   curl -fsSL https://raw.githubusercontent.com/Hackathon-Givaudan-Hetic/hackathon-app/develop/scripts/install/macos.sh | bash
set -euo pipefail

etape() { printf '\n==> %s\n' "$1"; }

# 1. Homebrew : le gestionnaire de paquets qui installe tout le reste
etape "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Rend brew disponible dans ce terminal (Apple Silicon : /opt/homebrew, Intel : /usr/local)
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
echo "ok : $(brew --version | head -1)"

# 2. Docker Desktop : fait tourner les conteneurs du projet
etape "Docker Desktop"
if [ ! -d /Applications/Docker.app ]; then
  brew install --cask docker-desktop
fi
open -a Docker
echo "Attente du démarrage de Docker (première fois : acceptez les conditions dans la fenêtre Docker)…"
for _ in $(seq 1 60); do
  docker info >/dev/null 2>&1 && break
  sleep 5
done
docker info >/dev/null 2>&1 && echo "ok : Docker $(docker version --format '{{.Server.Version}}')" \
  || echo "!! Docker ne répond pas encore : ouvrez Docker Desktop, terminez sa configuration, puis relancez ce script."

# 3. VS Code et l'extension Dev Containers
etape "VS Code"
# On cherche l'application elle-même : la commande « code » peut lancer un autre éditeur (Cursor…)
VSCODE_APP="/Applications/Visual Studio Code.app"
if [ ! -d "$VSCODE_APP" ]; then
  brew install --cask visual-studio-code
fi
"$VSCODE_APP/Contents/Resources/app/bin/code" --install-extension ms-vscode-remote.remote-containers --force >/dev/null
echo "ok : VS Code + Dev Containers"

# 4. git, et votre identité pour les commits
etape "git"
command -v git >/dev/null 2>&1 || brew install git
if [ -z "$(git config --global user.name || true)" ]; then
  read -r -p "Votre prénom et nom (pour les commits) : " nom < /dev/tty
  git config --global user.name "$nom"
fi
if [ -z "$(git config --global user.email || true)" ]; then
  read -r -p "Votre e-mail GitHub : " email < /dev/tty
  git config --global user.email "$email"
fi
echo "ok : $(git config --global user.name) <$(git config --global user.email)>"

# 5. Ollama et le modèle de dev : l'IA locale, gratuite, qui utilise le GPU du Mac
etape "Ollama"
if ! command -v ollama >/dev/null 2>&1; then
  brew install ollama
fi
# Démarre Ollama en arrière-plan, sauf s'il tourne déjà (application ou service)
curl -fs localhost:11434 >/dev/null 2>&1 || brew services start ollama
for _ in $(seq 1 20); do
  curl -fs localhost:11434 >/dev/null 2>&1 && break
  sleep 1
done
ollama pull llama3.2:1b
echo "ok : $(ollama list | grep llama3.2 || true)"

etape "Terminé"
echo "Suite : README.md, section « Démarrer en 4 étapes »."
