# 0001. TypeScript pour l'application, Python seulement pour l'IA, dans un seul dev container

- Statut : acceptée
- Date : 2026-11-05
- Décideurs : Wissem (tech-lead)

## Contexte

- Le hackathon dure deux semaines, à partir du lundi 9 novembre. Le jalon m0 tombe le premier jour, à 18 h.
- L'équipe mélange des développeurs, des profils Data/IA et des profils Product. Le Product ne code pas, mais relit les tickets et les critères. La Data/IA travaille d'habitude en Python (à confirmer avec elle lundi).
- Le sujet n'est pas connu. On ne sait pas encore si l'IA se limitera à appeler un LLM (prompt, chat, classification) ou demandera un traitement de données (RAG, embeddings, notebooks, modèle affiné).
- Objectif : chacun code dès le premier jour, sur Mac (Intel ou Apple Silicon), Windows ou Linux, sans rien installer d'autre que Docker, VS Code et Ollama.

## Options

1. **NestJS + React** : structure imposée, OpenAPI généré par `@nestjs/swagger`. Mais modules, décorateurs et injection de dépendances à apprendre, pour une API de quelques routes écrite par un ou deux développeurs.
2. **Next.js seul** (front et routes API dans un projet) : un seul framework. Mais rendu serveur, cache et Server Components inutiles pour une démo interne, et une API mêlée au front, alors que la Data/IA a besoin d'un contrat clair.
3. **Tout en Python** (FastAPI + un front) : la langue de la Data/IA. Mais le front resterait en JavaScript, et les développeurs devraient changer de langage côté API.
4. **Express + React (Vite), TypeScript ; PostgreSQL en SQL direct ; service Python FastAPI prêt mais optionnel** : les outils les plus simples et les plus documentés de chaque couche. Express et Vite sont déjà en place et testés dans le dev container.

## Décision

Nous choisissons l'option 4.

- **TypeScript** pour le front (React + Vite) et l'API (Express) : un seul langage côté application, des routes de quelques lignes, sans concept supplémentaire.
- **PostgreSQL en SQL direct** (`pg`), sans ORM : le SQL est la langue commune des développeurs et de la Data/IA ; un ORM ajouterait un langage de schéma et des migrations.
- **L'IA par une API compatible OpenAI** (`ask()` dans `api/src/index.ts`) : Ollama en dev, un fournisseur commercial pour la démo, choisi dans `api/.env`, sans changer le code.
- **Python 3.12 et un squelette FastAPI dans `ia/`**, installés dans le dev container pour tous, mais branchés seulement si le besoin est prouvé. Règle : si l'IA se limite à appeler un LLM, elle reste dans l'API TypeScript ; si elle demande un traitement de données, elle vit dans `ia/`, derrière l'API (`askDataTeam()`), avec son Swagger pour contrat. Un spike, le premier jour, tranche avec un seuil chiffré.
- **Le contrat entre les dossiers** : scripts `dev` et `build`, ports 3000, 5173 et 8000, routes sous `/api`. Un framework se remplace dans son dossier, sans toucher à l'environnement.

## Conséquences

- Positives : environnement prouvé par une installation neuve (dossier vierge → tout vert en moins de 3 minutes) ; un développeur peut lire tout le code ; la Data/IA a Python, Jupyter et FastAPI prêts sans rien installer.
- Négatives, à accepter : Express n'impose aucune structure, il faudra une convention de dossiers dès que l'API dépasse `api/src/index.ts` ; pas de génération automatique d'OpenAPI, le fichier `openapi.yaml` s'écrit à la main ; image du dev container plus lourde (Node et Python pour tous).
- À revoir si : le spike montre que l'IA demande un GPU (le dev container n'y a pas accès sur Mac : le modèle tournerait alors sur la machine de la Data/IA, exposée par ngrok) ; l'API dépasse une quinzaine de routes (NestJS ou Fastify redeviendraient pertinents).
