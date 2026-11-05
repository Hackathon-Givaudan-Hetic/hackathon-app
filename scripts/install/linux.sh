#!/usr/bin/env bash
# Prérequis du projet sur Linux (Ubuntu ou Debian), à lancer une fois, avant le premier jour.
# Installe ce qui manque, ne touche pas à ce qui est déjà là. Peut être relancé sans risque.
#   bash scripts/install/linux.sh
# ou, sans avoir cloné le dépôt :
#   curl -fsSL https://raw.githubusercontent.com/Hackathon-Givaudan-Hetic/hackathon-app/develop/scripts/install/linux.sh | bash
# Demande votre mot de passe (sudo). Pas pour WSL : sous Windows, voir scripts/install/windows.ps1.
set -euo pipefail

etape() { printf '\n==> %s\n' "$1"; }

if grep -qi microsoft /proc/version 2>/dev/null; then
  echo "Vous êtes dans WSL : Docker et Ollama s'installent côté Windows (scripts/install/windows.ps1)."
  exit 1
fi

etape "Outils de base"
sudo apt-get update -qq
sudo apt-get install -y -qq curl git ca-certificates >/dev/null
echo ok

# 1. Docker Engine (le script officiel de Docker), et le droit de l'utiliser sans sudo
etape "Docker Engine"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sudo sh
fi
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  echo "!! Ajouté au groupe docker : déconnectez-vous puis reconnectez-vous (ou redémarrez) avant d'ouvrir le projet."
fi
echo "ok : $(docker --version)"

# 2. VS Code et l'extension Dev Containers
etape "VS Code"
if ! command -v code >/dev/null 2>&1; then
  if command -v snap >/dev/null 2>&1; then
    sudo snap install code --classic
  else
    curl -fsSL -o /tmp/vscode.deb 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
    sudo apt-get install -y -qq /tmp/vscode.deb >/dev/null
  fi
fi
code --install-extension ms-vscode-remote.remote-containers --force >/dev/null
echo "ok : VS Code + Dev Containers"

# 3. Votre identité pour les commits
etape "git"
if [ -z "$(git config --global user.name || true)" ]; then
  read -r -p "Votre prénom et nom (pour les commits) : " nom < /dev/tty
  git config --global user.name "$nom"
fi
if [ -z "$(git config --global user.email || true)" ]; then
  read -r -p "Votre e-mail GitHub : " email < /dev/tty
  git config --global user.email "$email"
fi
echo "ok : $(git config --global user.name) <$(git config --global user.email)>"

# 4. Ollama, joignable depuis les conteneurs
etape "Ollama"
if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
fi
# Par défaut, Ollama n'écoute que sur 127.0.0.1 : le conteneur ne le voit pas.
# On le fait écouter sur toutes les interfaces (FAQ Ollama). Attention aux Wi-Fi publics sans pare-feu.
sudo mkdir -p /etc/systemd/system/ollama.service.d
printf '[Service]\nEnvironment="OLLAMA_HOST=0.0.0.0"\n' | sudo tee /etc/systemd/system/ollama.service.d/override.conf >/dev/null
sudo systemctl daemon-reload
sudo systemctl restart ollama
for _ in $(seq 1 20); do
  curl -fs localhost:11434 >/dev/null 2>&1 && break
  sleep 1
done
ollama pull llama3.2:1b
echo "ok : $(ollama list | grep llama3.2 || true)"

etape "Terminé"
echo "Suite : README.md, section « Démarrer en 3 étapes »."
