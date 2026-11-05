# hackathon-app

Service assisté par l'IA, hackathon HETIC × Givaudan. Le squelette actuel : le front envoie une question, l'API la transmet à l'IA, et la question et la réponse sont enregistrées dans PostgreSQL. Le sujet précis sera ajouté ici dès qu'il sera connu.

## Stack

- **Front** : React + Vite, TypeScript (`web/`, port 5173)
- **API** : Express, TypeScript (`api/`, port 3000) ; base **PostgreSQL 17** en SQL direct
- **IA** : toute API compatible OpenAI, choisie dans `api/.env` (Ollama en dev). Service **Python / FastAPI** prêt pour l'équipe Data/IA (`ia/`, port 8000)

Tout tourne dans un **dev container** VS Code : Node 24, Python 3.12 et psql 17, identiques pour toute l'équipe, sur macOS, Windows et Linux. Les raisons de ces choix : [`docs/adr/`](docs/adr/).

## Avant le premier jour : les prérequis (une fois par machine)

On part de zéro. Un script par système installe ce qui manque : **Docker**, **VS Code** et l'extension **Dev Containers**, **git**, **Ollama** et son modèle d'IA (1,3 Go). Il ne touche pas à ce qui est déjà installé, et peut être relancé sans risque. Comptez **20 à 40 minutes**, surtout du téléchargement : faites-le **chez vous, avant le premier jour**. Vous pouvez lire chaque script avant de le lancer, dans [`scripts/install/`](scripts/install/).

<details>
<summary><strong>macOS</strong> (Apple Silicon ou Intel)</summary>

Dans l'application **Terminal** :

```bash
curl -fsSL https://raw.githubusercontent.com/Hackathon-Givaudan-Hetic/hackathon-app/develop/scripts/install/macos.sh | bash
```

Le script demande votre mot de passe (Homebrew), votre nom et votre e-mail (pour les commits). À la première ouverture de Docker Desktop, acceptez ses conditions dans sa fenêtre. Puis passez à **Démarrer en 3 étapes**.

</details>

<details>
<summary><strong>Windows</strong> 10 ou 11 (avec WSL)</summary>

Sous Windows, le projet tourne dans **Ubuntu (WSL)**, un Linux intégré à Windows : les fichiers y sont bien plus rapides, et PostgreSQL refuse souvent de démarrer depuis `C:\`.

1. **Le script** : menu Démarrer → tapez `PowerShell` → clic droit → **Exécuter en tant qu'administrateur**, puis :
   ```powershell
   irm https://raw.githubusercontent.com/Hackathon-Givaudan-Hetic/hackathon-app/develop/scripts/install/windows.ps1 | iex
   ```
   Il installe WSL 2 + Ubuntu, Docker Desktop, VS Code (extensions WSL et Dev Containers) et Ollama avec son modèle.
2. **Redémarrez** l'ordinateur. Puis :
   - lancez **Docker Desktop** et acceptez ses conditions ; vérifiez Settings → General → **Use the WSL 2 based engine** coché, et Settings → Resources → **WSL integration** → **Ubuntu** activé ;
   - si le script n'a pas pu télécharger le modèle : dans PowerShell, `ollama pull llama3.2:1b`.
3. **Ubuntu** : menu Démarrer → **Ubuntu**. La première fois, choisissez un nom d'utilisateur et un mot de passe (rien ne s'affiche quand vous tapez le mot de passe : c'est normal). Puis, dans ce terminal Ubuntu, votre identité pour les commits :
   ```bash
   git config --global user.name "Prénom Nom"
   ```
   ```bash
   git config --global user.email "vous@exemple.com"
   ```
4. Passez à **Démarrer en 3 étapes**, **toujours dans le terminal Ubuntu**, jamais dans PowerShell.

</details>

<details>
<summary><strong>Linux</strong> (Ubuntu ou Debian)</summary>

Dans un terminal :

```bash
curl -fsSL https://raw.githubusercontent.com/Hackathon-Givaudan-Hetic/hackathon-app/develop/scripts/install/linux.sh | bash
```

Le script demande votre mot de passe (sudo), votre nom et votre e-mail. Il installe Docker Engine, VS Code, Ollama, et configure Ollama pour qu'il soit joignable depuis les conteneurs (`OLLAMA_HOST=0.0.0.0` : évitez alors les Wi-Fi publics sans pare-feu). **Déconnectez-vous puis reconnectez-vous** (droit d'utiliser Docker), puis passez à **Démarrer en 3 étapes**.

</details>

Ollama tourne ensuite en arrière-plan sur votre machine : le projet le trouve tout seul, à l'adresse `host.docker.internal:11434`, déjà écrite dans les fichiers `.env`.

## Démarrer en 3 étapes (moins de 5 minutes)

1. **Cloner**, dans un terminal (Windows : le terminal **Ubuntu**) :
   ```bash
   mkdir -p ~/projets && cd ~/projets
   ```
   ```bash
   git clone https://github.com/Hackathon-Givaudan-Hetic/hackathon-app.git && code hackathon-app
   ```
2. **Ouvrir dans le conteneur** : dans VS Code, `F1` → `Dev Containers: Reopen in Container`. La première fois, environ 3 minutes : l'image se construit, la base démarre avec ses données de test, les dépendances Node et Python s'installent, les fichiers `.env` sont créés. Rien à taper.
3. **Lancer et vérifier**, dans le terminal de VS Code (`` Ctrl+` ``) :
   ```bash
   npm run dev
   ```
   Ouvrez http://localhost:5173 et posez une question. Dans un second terminal (`+`) : `npm run verifier` doit tout afficher en vert.

**Pour pousser du code** (une fois, dans le terminal de VS Code) : connectez GitHub, puis suivez les instructions (choisissez `HTTPS`, puis `Login with a web browser`) :

```bash
gh auth login && gh auth setup-git
```

La connexion est conservée, même après un `Rebuild Container`. Vous devez aussi avoir accepté l'invitation à l'organisation GitHub (reçue par e-mail).

## Équipe Data/IA : le service Python

Tout est installé dans `ia/.venv` à la création du conteneur.

```bash
npm run dev:ia
```

Swagger sur http://localhost:8000/docs (en-tête `X-API-Key` : la valeur de `API_KEY` dans `ia/.env`, `dev` par défaut). Les notebooks (`.ipynb`) s'ouvrent dans VS Code, avec le noyau `ia/.venv`. Pour ajouter une dépendance : l'ajouter, version figée, dans `ia/requirements.txt`, puis `ia/.venv/bin/pip install -r ia/requirements-dev.txt`.

Pour que l'API passe par ce service plutôt que par Ollama directement, dans `api/.env` :

```bash
DATA_AI_URL=http://localhost:8000
DATA_AI_KEY=dev
```

puis relancez `npm run dev`.

## Changer de fournisseur d'IA

Décommentez l'option voulue dans `api/.env` (modèle et explications : `api/.env.example`), puis relancez `npm run dev`. Le code ne change pas. **Ne commitez jamais un `.env`** : une clé commitée se révoque immédiatement chez le fournisseur.

## Commandes

| Commande           | Rôle                                      |
| ------------------ | ----------------------------------------- |
| `npm run dev`      | API et front, rechargement à chaud        |
| `npm run dev:ia`   | service Python de l'équipe Data/IA        |
| `npm run verifier` | vérifie outils, base, API, front, IA      |
| `npm run lint`     | ESLint                                    |
| `npm run format`   | Prettier, corrige la forme                |
| `npm run build`    | compile et vérifie les types, comme la CI |

Base de données : `psql postgres://app:app@db:5432/app` dans le terminal de VS Code, ou un client graphique (TablePlus, DBeaver) sur `127.0.0.1:5432`, utilisateur, mot de passe et base `app`.

## Contribuer

- Une branche par ticket, depuis `develop` : `feature/nom-court`. Pull request vers `develop`, avec `Closes #N`.
- Commitez **depuis le dev container** : le hook pre-commit (ESLint, Prettier) utilise son Node.
- La CI `qualite` doit être verte, et un membre doit approuver, pour fusionner.

## Dépannage

| Symptôme                                  | Parade                                                                                                                    |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Le conteneur ne démarre pas               | `F1` → `Dev Containers: Show Container Log`, puis `Rebuild Container`. Docker Desktop est-il lancé ?                      |
| `Author identity unknown`                 | configurez `git config --global user.name/user.email` sur votre machine (Windows : dans Ubuntu), puis `Rebuild Container` |
| `git push` refusé (authentification)      | dans le terminal de VS Code : `gh auth login && gh auth setup-git`                                                        |
| `permission denied … docker.sock` (Linux) | déconnectez-vous puis reconnectez-vous (groupe `docker`)                                                                  |
| `relation "questions" does not exist`     | `Reopen Folder Locally`, supprimez `db/data` (Linux : `sudo rm -rf db/data`), puis `Reopen in Container`                  |
| `model … not found`                       | `ollama pull llama3.2:1b` sur votre machine                                                                               |
| IA injoignable (`verifier` en rouge)      | Ollama est-il lancé ? Linux : voir la configuration `OLLAMA_HOST` ci-dessus                                               |
| Rien dans le navigateur                   | onglet **Ports** de VS Code : 3000 et 5173 doivent y figurer                                                              |
