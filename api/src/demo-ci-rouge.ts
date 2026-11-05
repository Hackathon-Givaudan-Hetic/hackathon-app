// Démo : ce fichier viole volontairement deux règles ESLint.
// Le hook pre-commit l'aurait refusé ; poussé avec --no-verify, c'est la CI qui l'arrête.
// Cette pull request ne doit jamais être fusionnée.
const inutile: any = 1;
