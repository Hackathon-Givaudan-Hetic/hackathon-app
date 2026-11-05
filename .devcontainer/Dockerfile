# Même base que l'image de production : Node 24 sur Debian trixie
FROM mcr.microsoft.com/devcontainers/typescript-node:24-trixie

# Miroir français pour les paquets Debian : le dépôt officiel (deb.debian.org) est bloqué sur le réseau HETIC
RUN sed -i 's|deb.debian.org|ftp.fr.debian.org|g' /etc/apt/sources.list.d/debian.sources

# Client PostgreSQL (psql 17, comme le serveur)
RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Dossier de connexion de gh, monté sur un volume (compose.yaml) : la connexion
# GitHub survit aux Rebuild. Créé ici pour appartenir à l'utilisateur node.
RUN mkdir -p /home/node/.config/gh && chown -R node:node /home/node/.config
