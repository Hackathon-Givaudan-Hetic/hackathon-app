# AGENTS.md

Hackathon HETIC × Givaudan (deux semaines à partir du 9 novembre 2026). Une API Express et un front React en TypeScript, PostgreSQL 17, un service Python FastAPI pour l'équipe Data/IA, et un fournisseur d'IA compatible OpenAI, le tout dans un dev container VS Code. Présentation et installation : `README.md`.

## Lancer

Toutes les commandes se lancent dans le dev container (terminal de VS Code), jamais sur la machine hôte.

- `npm run dev` : API sur le port 3000, front sur le port 5173.
- `npm run dev:ia` : service Python sur le port 8000, Swagger sur `/docs`.
- `npm run verifier` : contrôle outils, base, API, front et IA ; tout doit être vert (le service Python est optionnel).
- Base : `psql postgres://app:app@db:5432/app`.
- Avant de dire « fini » : `npm run lint`, `npm run format:check`, `npm run build`. Ce sont les étapes du job `qualite` de `.github/workflows/ci.yml`, exigé pour fusionner.

## Règles

- Les routes de l'API sont dans `api/src/index.ts`, toutes sous `/api`. Le front (`web/src/App.tsx`) appelle `/api` : le proxy est dans `web/vite.config.ts`, il n'y a pas de CORS à configurer.
- SQL direct avec `pg`, requêtes paramétrées (`$1`, `$2`), jamais de concaténation. Pas d'ORM (ADR 0001).
- Le schéma et les données de test sont dans `db/init/`, joués au premier démarrage seulement : les modifier ne change pas une base existante. Pour les rejouer : supprimer `db/data/` puis recréer le conteneur.
- L'IA passe par `ask()` (fournisseur compatible OpenAI) ou `askDataTeam()` (service Python, si `DATA_AI_URL` est défini), dans `api/src/index.ts`. Changer de fournisseur = modifier `api/.env`, pas le code.
- Le contrat du service Python est son Swagger : `ia/main.py`, route `/docs`. Ses dépendances sont figées dans `ia/requirements.txt` et installées dans `ia/.venv`.
- Les fichiers d'environnement (`.devcontainer/`, `compose.yaml`, `package.json`, `eslint.config.mjs`, `.github/`) sont protégés par `.github/CODEOWNERS` : une modification demande l'accord d'un tech-lead.
- Une branche par ticket, depuis `develop` (`feature/nom-court`). La pull request vise `develop`, suit `.github/pull_request_template.md` et contient `Closes #N`.
- Le plan d'un travail vit dans son ticket : `gh issue view N`. Les brouillons de session vont dans `.scratch/`, ignoré par git, en Markdown.

## Décisions

- Lis `docs/adr/` avant d'ajouter une dépendance ou de changer de composant.
- Ne contredis pas un ADR au statut « acceptée ».
- S'il faut en changer, propose un nouvel ADR (modèle : `docs/adr/0000-modele.md`), puis arrête-toi.
- TypeScript pour l'application ; Python seulement dans `ia/`, derrière l'API (ADR 0001).

## À ne pas faire

- Passer `--no-verify` à `git commit`, ou ajouter `eslint-disable`, pour faire passer un contrôle.
- Lancer `npm install` ou `pip install` hors du conteneur : `package-lock.json` et `ia/.venv` doivent rester valables sous Linux.
- Écrire une clé ou un mot de passe dans le code. Les secrets vont dans `api/.env` ou `ia/.env`, jamais commités ; les modèles sont `api/.env.example` et `ia/.env.example`.
- Ajouter un framework, un ORM ou un service à `compose.yaml` sans ADR.
- Pousser directement sur `main` ou `develop` : le ruleset le refuse, passer par une pull request.
