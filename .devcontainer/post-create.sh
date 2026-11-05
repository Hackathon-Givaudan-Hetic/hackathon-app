#!/usr/bin/env bash
# Exécuté une fois, à la création du dev container (postCreateCommand).
# Objectif : le nouvel arrivant ne tape rien, tout est prêt à coder.
set -euo pipefail

git config --global --add safe.directory /workspace

# Node : les versions exactes de package-lock.json (installe aussi le hook pre-commit)
npm ci

# Python : un environnement virtuel pour le service de l'équipe Data/IA
python -m venv ia/.venv
ia/.venv/bin/pip install --quiet --upgrade pip
ia/.venv/bin/pip install --quiet -r ia/requirements-dev.txt

# Fichiers .env locaux, à partir des modèles. Un .env existant n'est jamais écrasé.
test -f api/.env || cp api/.env.example api/.env
test -f ia/.env || cp ia/.env.example ia/.env

echo "Prêt : npm run dev (API + front), npm run dev:ia (service Data/IA), npm run verifier."
