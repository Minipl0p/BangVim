# Config Neovim

Une config Neovim pensée pour remplacer un IDE au quotidien : C, C++, C#, Rust, Go, Python, Java, Lua, le web, et les moteurs de jeu Unreal, Unity et Godot. Elle est jolie, tient sur un minimum de raccourcis, met les fenêtres en flottant partout où c'est possible, et fonctionne à l'identique sous Linux, WSL et Windows.

Tout ce qui est réglable passe par une fenêtre de paramètres et par des **profils** : un profil « Perso », un profil « Boulot » avec un autre formatage et une autre norme de commit, et on bascule de l'un à l'autre en une touche.

![Vue d'ensemble](docs/screenshots/vue-ensemble.png) <!-- capture : éditeur avec Claude Code à droite -->

---

## Sommaire

- [Aperçu](#aperçu)
- [Installation](#installation)
  - [Ce qui est installé](#ce-qui-est-installé)
  - [Linux et WSL](#linux-et-wsl)
  - [Windows](#windows)
  - [Premier lancement](#premier-lancement)
- [Moteurs de jeu](#moteurs-de-jeu)
- [Utilisation](#utilisation)
  - [Les raccourcis](#les-raccourcis)
  - [Paramètres et profils](#paramètres-et-profils)
  - [Claude Code](#claude-code)
  - [Git et commits par IA](#git-et-commits-par-ia)
  - [Markdown](#markdown)
  - [Débogueur](#débogueur)
- [Modifier la config](#modifier-la-config)
  - [Organisation des fichiers](#organisation-des-fichiers)
  - [Ajouter un langage](#ajouter-un-langage)
  - [Ajouter un thème](#ajouter-un-thème)
  - [Formateurs](#formateurs)
  - [Normes de commit](#normes-de-commit)
  - [Raccourcis](#ajouter-ou-modifier-un-raccourci)
  - [Profils : le fichier](#profils--le-fichier)
- [Dépannage](#dépannage)
- [Plugins](#plugins)

---

## Aperçu

| | |
| --- | --- |
| ![Arbre flottant](docs/screenshots/arbre.png) | ![Recherche](docs/screenshots/recherche.png) |
| Arbre de fichiers flottant, `h`/`l` pour replier/déplier | Recherche de fichiers et live grep flottants, avec aperçu |
| ![Paramètres](docs/screenshots/parametres.png) | ![Claude Code](docs/screenshots/claude.png) |
| `:Param` : profils, thème, formatage, commits, raccourcis | Claude Code en split à droite, le code reste visible |
| ![Markdown](docs/screenshots/markdown.png) | ![Debug](docs/screenshots/debug.png) |
| Aperçu Markdown navigateur avec Mermaid, en écran partagé | Débogueur en panneaux ou en flottant |

**Ce qu'il y a dedans**

- **Interface** : fond en dégradé (dessiné par WezTerm), barre des buffers à onglets inclinés, statusline, ligne de commande flottante au centre, bordure colorée autour du split actif, traînée animée du curseur. Une quinzaine de thèmes, Catppuccin Mocha par défaut.
- **Navigation** : arbre de fichiers toujours flottant, picker flottant (fichiers, grep, buffers, références), sauts rapides avec `s`.
- **Code** : LSP, coloration Treesitter, formatage et débogueurs installés automatiquement pour tous les langages listés. Aller à la définition, la déclaration, l'implémentation, le type, les références.
- **Complétion** : menu classique (LSP, snippets) + suggestions IA en texte grisé (GitHub Copilot, plan gratuit disponible), acceptables en entier, par mot ou par ligne.
- **Copier-coller** : historique de 50 copies, picker pour choisir quoi coller, indentation automatique.
- **Claude Code** : dans un split vertical, avec défilement au clavier et un raccourci pour tout quitter proprement.
- **Git** : lazygit flottant, message de commit généré par IA selon une norme choisie par profil, rappels discrets de commit.
- **Markdown** : rendu stylé dans l'éditeur et aperçu navigateur façon Obsidian.
- **Pour le fun** : animation « BOUM » des lettres tapées (désactivée par défaut).

Les raccourcis affichés par which-key sont uniquement ceux de cette config, jamais ceux natifs de Neovim.

---

## Installation

### Ce qui est installé

| Logiciel | Rôle | Linux / WSL | Windows |
| --- | --- | --- | --- |
| Neovim ≥ 0.12 | L'éditeur | tarball officiel | winget |
| WezTerm | Terminal (dégradé, protocole clavier) | paquet | winget |
| Git | Plugins, git | paquet | winget |
| ripgrep, fd | Recherche de texte et de fichiers | paquet | winget |
| lazygit | Interface git | paquet / release | winget |
| Node.js | Plusieurs serveurs LSP (web, Bash…) | paquet | winget |
| Python 3 | debugpy, gdtoolkit, jdtls | paquet | winget |
| Compilateur C | Parseurs Treesitter | gcc | Visual Studio C++ / Build Tools |
| JetBrainsMono Nerd Font | Police avec icônes | téléchargée | winget |
| Claude Code | Split Claude, commits IA | script officiel | script officiel |
| zsh + Oh My Zsh | Shell et thème | paquet + script | — |
| PowerShell 7 | Shell Windows | — | winget |

**Selon tes langages** (installés à part) : SDK .NET 8+ pour C# et Unity, JDK 21 pour Java, Go, Rust (`rustup`).

Tout le reste (serveurs LSP, formateurs, débogueurs, `tree-sitter-cli`) est installé **automatiquement par Neovim** au premier lancement, via Mason.

### Linux et WSL

```bash
git clone https://github.com/Minipl0p/BangVim.git ~/nvim-config
cd ~/nvim-config
./install/linux.sh
```

Le script reconnaît Arch, Fedora et Debian/Ubuntu. Il installe les paquets, Neovim, la police, Claude Code, Oh My Zsh avec le thème `catppuccin`, puis crée les liens :

- `~/.config/nvim` → ce repo (une config existante est d'abord sauvegardée) ;
- `~/.wezterm.lua` → `wezterm/wezterm.lua` (sauf sous WSL).

**WSL** : WezTerm et la police s'installent côté Windows (script Windows ci-dessous). Dans WezTerm, tape `wsl` pour entrer dans ta distribution, ou décommente `config.default_domain` dans `wezterm/wezterm.lua`. Pour les projets Unreal et Unity, lance plutôt Neovim côté Windows : les outils MSVC y sont, et l'accès aux fichiers Windows depuis WSL est lent.

### Windows

Dans PowerShell, depuis la racine du repo :

```powershell
git clone <url-de-ce-repo> $HOME\nvim-config
cd $HOME\nvim-config
powershell -ExecutionPolicy Bypass -File install\windows.ps1 -Langages
```

| Option | Effet |
| --- | --- |
| `-Langages` | Installe aussi .NET 8, JDK 21, Go et Rust |
| `-BuildTools` | Installe les Build Tools C++ de Visual Studio (inutile si Visual Studio avec le module C++ est déjà là, ce qui est le cas pour Unreal) |

Le script crée une jonction `%LOCALAPPDATA%\nvim` → ce repo, et copie la config WezTerm dans `%USERPROFILE%\.wezterm.lua`.

Le prompt PowerShell est un projet séparé (repo `powershell-prompt`).

### Premier lancement

1. Ouvre WezTerm, puis `nvim`.
2. Patiente quelques minutes : plugins, serveurs LSP, formateurs, débogueurs et parseurs s'installent. `:Mason` montre la progression.
3. Active le plan gratuit de Copilot sur GitHub (*Settings → Copilot → Copilot Free*), puis lance `:Copilot auth` et saisis le code affiché sur la page indiquée.
4. Vérifie l'état avec `:checkhealth`.

![Premier lancement](docs/screenshots/premier-lancement.png) <!-- capture : Mason qui installe -->

---

## Moteurs de jeu

Le débogage des moteurs se fait dans Rider ou dans l'éditeur du moteur. Neovim sert à écrire le code, avec navigation et complétion complètes.

### Unreal Engine

clangd a besoin d'un fichier `compile_commands.json` à la racine du projet. Génère-le avec UnrealBuildTool (adapte les chemins et le nom du projet) :

```powershell
& "C:\Program Files\Epic Games\UE_5.4\Engine\Build\BatchFiles\RunUBT.bat" `
  -mode=GenerateClangDatabase -project="C:\Projets\MonJeu\MonJeu.uproject" `
  MonJeuEditor Win64 Development
Copy-Item "C:\Program Files\Epic Games\UE_5.4\compile_commands.json" "C:\Projets\MonJeu\"
```

Relance la commande quand tu ajoutes des modules ou des fichiers. La première indexation du moteur prend du temps, ensuite les sauts vers les définitions marchent jusque dans le code du moteur.

### Unity

1. Installe le SDK .NET 8 ou plus.
2. Dans Unity : *Edit → Preferences → External Tools*, choisis l'éditeur externe et clique **Regenerate project files** pour créer les `.csproj` et la `.sln`.
3. Ouvre le dossier du projet dans Neovim : le serveur Roslyn démarre sur les fichiers `.cs` (`:Roslyn target` pour choisir la solution s'il y en a plusieurs).

### Godot

Godot embarque son propre serveur LSP (port 6005). **L'éditeur Godot doit être ouvert** pour que la complétion GDScript fonctionne.

Pour que Godot ouvre les scripts dans Neovim : *Éditeur → Paramètres de l'éditeur → Text Editor → External*

- **Use External Editor** : activé
- **Exec Path** : chemin de `nvim`
- **Exec Flags** :
  - Linux : `--server /tmp/godot.pipe --remote-send "<C-\><C-N>:e {file}<CR>:call cursor({line},{col})<CR>"`
  - Windows : `--server \\.\pipe\godot.pipe --remote-send "<C-\><C-N>:e {file}<CR>:call cursor({line},{col})<CR>"`

Et lance Neovim dans ton projet avec `nvim --listen /tmp/godot.pipe` (Windows : `nvim --listen \\.\pipe\godot.pipe`).

---

## Utilisation

### Les raccourcis

La touche **leader** est `Espace`. Tous les raccourcis se modifient par profil dans `:Param`.

**Bases**

| Touche | Action |
| --- | --- |
| `<C-s>` | Sauvegarder |
| `<C-q>` | Fermer le buffer (avec sauvegarde). Dernier buffer : quitte tout |
| `<C-S-q>` | Fermer le buffer sans sauvegarder |
| `jk` | Sortir du mode insertion |
| `<Esc>` | Effacer le surlignage de recherche |
| `<C-/>` | Commenter la ligne ou la sélection |
| `J` | Joindre les lignes sans bouger le curseur |
| `<` `>` (visuel) | Indenter en gardant la sélection |
| `<C-j>` / `<C-k>` | Descendre / monter de 5 lignes |

**Buffers et fenêtres**

| Touche | Action |
| --- | --- |
| `<C-h>` / `<C-l>` | Buffer précédent / suivant (Claude et terminaux exclus) |
| ``<C-`>`` | Fermer tous les autres buffers |
| `<leader><Espace>` | Liste des buffers ouverts |
| `<C-;>` | Rotation entre les splits ; depuis Claude, retour au code |
| `<leader>v` / `<leader>h` | Split vertical / horizontal |
| `<leader>w` | Fermer le split |
| `<leader>=` | Égaliser les splits |
| `<C-flèches>` | Redimensionner (ou à la souris sur les bordures) |
| `<C-t>` | Ouvrir / cacher le terminal flottant |
| `<Esc><Esc>` | Mode normal dans le terminal flottant |

**Recherche et fichiers**

| Touche | Action |
| --- | --- |
| `<leader>f` | Chercher un fichier |
| `<leader>g` | Live grep |
| `s` | Saut rapide (flash) |
| `S` | Sélectionner un bloc de code (Treesitter) |
| `<leader>e` | Arbre de fichiers flottant |
| `l` / `h` (arbre) | Déplier / replier (ou remonter au parent) |
| `<CR>` (arbre) | Ouvrir le fichier |
| `<C-CR>` (arbre) | Ouvrir le fichier et fermer tous les autres buffers |
| `a` `d` `r` `m` (arbre) | Créer, supprimer, renommer, déplacer |

**Copier-coller**

| Touche | Action |
| --- | --- |
| `y` | Copier (dans l'historique) |
| `p` / `P` | Coller après / avant, avec indentation automatique |
| `<C-p>` / `<C-n>` | Juste après un collage : remplacer par la copie précédente / suivante |
| `<leader>y` | Historique des copies : choisir quoi coller |

**Code**

| Touche | Action |
| --- | --- |
| `gd` / `gD` | Définition / déclaration |
| `gi` / `gy` | Implémentation / type |
| `gr` | Références |
| `K` | Documentation au survol |
| `gl` | Diagnostic complet de la ligne |
| `[d` / `]d` | Diagnostic précédent / suivant |
| `<leader>b` | Renommer partout (LSP) |
| `<leader>n` | Renommer dans le fichier (texte). En visuel : remplacer dans la sélection |

**Complétion et IA** (mode insertion)

| Touche | Action |
| --- | --- |
| `Tab` | Accepter toute la suggestion IA (sinon : indentation ou placeholder suivant) |
| `<C-l>` / `<C-j>` | Accepter un mot / une ligne de la suggestion IA |
| `<C-]>` | Variante suivante de la suggestion |
| `<C-e>` | Rejeter la suggestion / fermer le menu |
| `<C-n>` / `<C-p>` | Naviguer dans le menu de complétion |
| `<CR>` | Valider l'élément du menu |
| `<C-Space>` | Forcer l'ouverture du menu |
| `<S-Tab>` | Placeholder précédent d'un snippet |

**Claude Code, Git, Markdown, Debug, Paramètres**

| Touche | Action |
| --- | --- |
| `<leader>a` | Ouvrir / cacher Claude Code |
| `<C-j>` / `<C-k>` (dans Claude) | Défiler dans les réponses |
| `<leader>Q` | Tout quitter (Neovim et Claude) |
| `<C-g>` | Lazygit |
| `<C-a>` (dans lazygit) | Commit avec message généré par IA |
| `<leader>m` | Aperçu Markdown dans le navigateur (on/off) |
| `F5` / `<S-F5>` | Lancer ou continuer / arrêter le débogage |
| `F9` / `<leader>B` | Breakpoint / breakpoint conditionnel |
| `F10` / `F11` / `<S-F11>` | Passer / entrer / sortir |
| `<leader>D` | Interface du débogueur |
| `<leader>,` ou `:Param` | Paramètres et profils |

### Paramètres et profils

![Fenêtre des paramètres](docs/screenshots/parametres-detail.png)

`<leader>,` (ou `:Param`, ou `:param`) ouvre la fenêtre des paramètres. `Entrée` modifie la ligne, `r` remet un raccourci par défaut, `q` ferme.

| Section | Réglages |
| --- | --- |
| Profil | Profil actif, associer le dossier courant, créer, dupliquer, renommer, supprimer |
| Apparence | Thème (aperçu en direct), traînée du curseur, animation BOUM |
| Formatage | Formatage à la sauvegarde, formateur par langage |
| Commits | Norme, modifier ou créer une norme, seuils de rappel |
| Complétion IA | Suggestions en texte grisé on/off |
| Débogueur | Interface en panneaux ou flottante |
| Markdown | Navigateur de l'aperçu |
| Raccourcis | Tous les raccourcis, modifiables (un `●` marque ceux personnalisés) |

**Quel profil est utilisé ?**

1. Si le dossier ouvert (ou un dossier parent) est **associé** à un profil, celui-ci s'applique automatiquement.
2. Sinon, c'est le **dernier profil choisi** à la main.

Exemple : associe `C:\Boulot` au profil « Boulot » une fois pour toutes. Tous les projets en dessous auront le formatage et la norme de commit de l'entreprise, sans risque de les oublier. `:Profil <nom>` change aussi de profil depuis la ligne de commande.

La police se règle dans WezTerm (`wezterm/wezterm.lua`), pas dans Neovim.

### Claude Code

![Claude Code](docs/screenshots/claude-detail.png)

- `<leader>a` ouvre Claude Code dans un split à droite (38 % de la largeur), ou le cache sans perdre la session.
- `<C-;>` passe du code à Claude et inversement.
- Dans Claude, `<C-j>` et `<C-k>` passent en **mode lecture** et font défiler les réponses comme la molette. En mode lecture, toutes les motions Vim marchent (`j`, `k`, `w`, `v`, `y`…) : `j`/`k` font défiler quand le curseur touche le bas ou le haut, et `i` revient à la saisie. La sélection se limite à ce qui est affiché à l'écran ; pour récupérer une très longue réponse, utilise `/export` dans Claude Code.
- `<C-t>` ouvre le terminal flottant même depuis Claude (le raccourci `Ctrl+T` de Claude Code, la liste des tâches, n'est donc plus disponible).
- `<leader>Q` quitte tout : demande de sauvegarder si besoin, rappelle les modifs non commitées, envoie `/exit` à Claude, ferme Neovim.

Dans la saisie de Claude, seuls `<C-;>`, `<C-t>`, `<C-j>` et `<C-k>` sont pris par la config : `Esc`, `Shift+Tab` et le reste restent à Claude Code. Pour aller à la ligne dans un message : `\` puis `Entrée`.

Quand Claude propose une modification, elle s'affiche en diff dans Neovim : `:w` pour accepter, ferme le diff pour refuser.

### Git et commits par IA

**Commit IA** (`<C-a>` dans lazygit) :

1. Indexe tes fichiers comme d'habitude (`Espace`, ou `a` pour tout).
2. `<C-a>` : Claude Code rédige le message à partir des modifications indexées, selon la norme du profil.
3. Le message s'ouvre dans Neovim : modifie-le si besoin.
4. Sauvegarde et ferme (`<C-q>`) pour commiter. Vide le message ou ferme sans sauvegarder pour annuler.

Le message ne contient jamais de trace d'IA : les lignes `Co-Authored-By`, « Generated with » et équivalentes sont retirées automatiquement. Rien d'indexé : le script l'indique et s'arrête.

Une norme propre à un projet peut aussi être posée dans un fichier `.commit-convention.md` à la racine du dépôt : elle passe alors avant celle du profil.

**Rappels de commit** :

- Un compteur dans la statusline (`+42 −8 · 3 fichiers`), neutre, puis jaune, puis orange quand les modifs s'accumulent.
- Une seule notification au-delà du seuil (par défaut 150 lignes ou 30 minutes, réglable par profil).
- Un avertissement en quittant s'il reste des modifs non commitées.

Hors d'un dépôt git (Perforce par exemple), rien ne s'affiche et aucune erreur n'apparaît.

### Markdown

![Aperçu Markdown](docs/screenshots/markdown-detail.png)

- Dans Neovim, les fichiers Markdown sont rendus avec titres, listes, tableaux et blocs de code stylés.
- `<leader>m` (ou `:MarkdownApercu`) ouvre l'aperçu dans le navigateur : diagrammes Mermaid, maths KaTeX, coloration du code, scroll synchronisé, mise à jour pendant la frappe. `<leader>m` à nouveau ou `:MarkdownStop` l'arrête.
- Avec **Chrome, Edge, Brave ou Chromium**, l'aperçu s'ouvre en fenêtre d'application sur la moitié droite de l'écran, et WezTerm se place sur la moitié gauche. Avec **Firefox**, l'aperçu s'ouvre dans une nouvelle fenêtre à placer soi-même (Win+→).

Le navigateur se choisit dans `:Param` → Markdown.

### Débogueur

![Débogueur](docs/screenshots/debug-detail.png)

Débogage intégré pour C, C++, Rust (codelldb), Python (debugpy), Go (delve), JavaScript/TypeScript (js-debug) et Java (via jdtls). `F5` lance une session ; la configuration à utiliser est demandée la première fois.

Deux interfaces, au choix dans `:Param` → Débogueur :

- **panneaux** : variables, pile d'appels, breakpoints et console autour du code, ouverts au lancement et fermés à la fin ;
- **flottant** : le code garde tout l'écran, `<leader>D` ouvre la vue voulue par-dessus.

---

## Modifier la config

### Organisation des fichiers

```
init.lua                  point d'entrée
lua/config/
  options.lua             options de Neovim, presse-papier, shell Windows
  lazy.lua                gestionnaire de plugins
  autocmds.lua            démarrage sur l'arbre, Treesitter, terminaux…
lua/core/                 le fonctionnement propre à cette config
  profiles.lua            profils (lecture, écriture, association aux dossiers)
  keys.lua                registre de tous les raccourcis
  param.lua               fenêtre :Param
  apply.lua               applique le profil (thème, touches, IA…)
  format.lua              formateurs par langage
  claude.lua              Claude Code : focus, défilement, tout quitter
  commit_reminder.lua     rappels de commit
  lazygit.lua             touche de commit IA dans lazygit
  markdown.lua            aperçu navigateur et écran partagé
  debug.lua               interface du débogueur
  boom.lua                animation des lettres
  buffers.lua, terminal.lua, tree.lua, paste.lua, rename.lua, ai.lua, platform.lua
lua/plugins/              un fichier par famille de plugins
scripts/ai_commit.lua     script du commit IA (lancé par lazygit)
conventions/              normes de commit fournies
wezterm/wezterm.lua       config WezTerm
zsh/                      thème Oh My Zsh
install/                  scripts d'installation
```

### Ajouter un langage

Trois endroits, chacun une ligne :

1. **Serveur LSP** — `lua/plugins/lsp.lua` :
   - le nom du paquet Mason dans `tools` (liste sur `:Mason` ou [mason-registry](https://mason-registry.dev/registry/list)) ;
   - le nom lspconfig dans `servers` (liste dans [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig/tree/master/lsp)).
2. **Coloration** — `lua/plugins/treesitter.lua` : le nom du parseur dans `langs`.
3. **Formatage** — `lua/core/format.lua` : une ligne dans `M.by_ft`, avec le formateur par défaut en premier puis les alternatives. Ajoute le formateur à `tools` dans `lsp.lua` s'il vient de Mason.

Exemple pour Zig :

```lua
-- lsp.lua
local tools = { …, "zls" }
local servers = { …, "zls" }
-- treesitter.lua
local langs = { …, "zig" }
-- format.lua
zig = { "zigfmt", "lsp" },
```

Au prochain lancement, Mason installe le serveur et Treesitter le parseur.

### Ajouter un thème

Ajoute une ligne dans `lua/plugins/themes.lua` :

```lua
{ "auteur/mon-theme.nvim", lazy = false, priority = 900, opts = { transparent = true } },
```

Il apparaît dans le sélecteur de `:Param` → Thème. Active l'option de transparence du thème si elle existe : le fond reste ainsi le dégradé de WezTerm.

### Formateurs

Le formatage passe par [conform.nvim](https://github.com/stevearc/conform.nvim) :

- À la sauvegarde, si le profil l'autorise, le formateur choisi pour le langage est lancé.
- Les fichiers de configuration du projet sont respectés : `.clang-format`, `.editorconfig`, `rustfmt.toml`, `.prettierrc`, `pyproject.toml`, `stylua.toml`… C'est l'endroit pour coller aux règles d'une entreprise.
- Le choix `lsp` utilise le formatage du serveur de langage.
- `:ConformInfo` montre quel formateur s'applique au fichier courant.

### Normes de commit

Une norme est un fichier Markdown décrivant les règles en langage naturel, langue des messages comprise.

- Fournies : `conventional-fr` (par défaut), `conventional-en`, `libre-fr`, dans `conventions/`.
- Les tiennes : dans `:Param` → Commits → **Nouvelle norme**. Le fichier est créé dans le dossier de données de Neovim (hors du repo), à partir de `conventional-fr`, et s'ouvre pour modification.
- **Modifier cette norme** crée une copie personnelle d'une norme fournie avant de l'ouvrir.
- `.commit-convention.md` à la racine d'un dépôt passe avant la norme du profil.

### Ajouter ou modifier un raccourci

Pour changer une touche, `:Param` suffit. Pour ajouter une action, une ligne dans `lua/core/keys.lua` :

```lua
A({ id = "mon_action", group = "Bases", desc = "Ce que ça fait", key = "<leader>x",
  fn = function() print("bonjour") end })
```

- `id` : identifiant unique, utilisé par les profils.
- `mode` : `"n"` par défaut, ou une liste (`{ "n", "x" }`).
- `fn` : une fonction ou une suite de touches (`"<Cmd>w<CR>"`).
- `scope = "lsp"` : la touche n'existe que dans les buffers où un LSP est attaché.

L'action apparaît automatiquement dans `:Param` et dans which-key.

### Profils : le fichier

Les profils sont enregistrés dans `profils.json`, dans le dossier de données de Neovim :

| Système | Emplacement |
| --- | --- |
| Linux / WSL | `~/.local/share/nvim/profils.json` |
| Windows | `%LOCALAPPDATA%\nvim-data\profils.json` |

Ce fichier n'est jamais dans le repo : tes réglages d'entreprise restent sur ta machine. Pour retrouver tes profils sur un autre PC, copie ce fichier. Les valeurs possibles et par défaut sont dans `M.defaults` de `lua/core/profiles.lua`.

---

## Dépannage

| Problème | Solution |
| --- | --- |
| Icônes en carrés | La police Nerd Font n'est pas installée, ou WezTerm n'utilise pas la bonne (`wezterm/wezterm.lua`). |
| `<C-;>`, `<C-/>` ou `<C-S-q>` ne répondent pas | Utilise WezTerm avec la config fournie : ces touches demandent le protocole clavier kitty. |
| Pas de coloration | `:checkhealth nvim-treesitter`. Il faut `tree-sitter-cli` (installé par Mason) et un compilateur C (gcc, ou Visual Studio C++ sous Windows). |
| Pas de complétion ni de `gd` | `:checkhealth vim.lsp` et `:Mason` pour voir si le serveur est installé. Unreal : `compile_commands.json` manquant. Godot : l'éditeur Godot doit être ouvert. |
| Pas de suggestions IA | `:Copilot auth`, `:Copilot status`, et vérifie que l'IA est activée dans `:Param`. |
| Commit IA : « claude introuvable » | Installe Claude Code et connecte-toi une fois en lançant `claude` dans un terminal. |
| Le défilement de Claude au clavier ne marche pas | Utilise la souris en attendant et signale-le : le comportement dépend de la version de Claude Code. |
| L'aperçu Markdown ne s'ouvre pas en écran partagé | Fonctionne avec Chrome, Edge, Brave et Chromium. Sous Linux, demande X11 (Wayland ignore la position des fenêtres). |
| Repartir de zéro | Supprime les dossiers de données et de cache de Neovim (`~/.local/share/nvim`, `~/.cache/nvim` ; sous Windows `%LOCALAPPDATA%\nvim-data`). |

---

## Plugins

| Domaine | Plugins |
| --- | --- |
| Gestion | [lazy.nvim](https://github.com/folke/lazy.nvim) |
| Interface | [bufferline](https://github.com/akinsho/bufferline.nvim), [lualine](https://github.com/nvim-lualine/lualine.nvim), [noice](https://github.com/folke/noice.nvim), [which-key](https://github.com/folke/which-key.nvim), [colorful-winsep](https://github.com/nvim-zh/colorful-winsep.nvim), [smear-cursor](https://github.com/sphamba/smear-cursor.nvim) |
| Outils | [snacks.nvim](https://github.com/folke/snacks.nvim) (picker, terminal, lazygit, notifications), [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim), [flash](https://github.com/folke/flash.nvim), [yanky](https://github.com/gbprod/yanky.nvim) |
| Code | [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter), [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), [mason](https://github.com/mason-org/mason.nvim), [mason-tool-installer](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim), [roslyn.nvim](https://github.com/seblyng/roslyn.nvim), [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls), [conform](https://github.com/stevearc/conform.nvim) |
| Complétion | [blink.cmp](https://github.com/saghen/blink.cmp), [friendly-snippets](https://github.com/rafamadriz/friendly-snippets), [copilot.lua](https://github.com/zbirenbaum/copilot.lua) |
| Debug | [nvim-dap](https://github.com/mfussenegger/nvim-dap), [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui), [mason-nvim-dap](https://github.com/jay-babu/mason-nvim-dap.nvim), [nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text) |
| IA | [claudecode.nvim](https://github.com/coder/claudecode.nvim) |
| Markdown | [render-markdown](https://github.com/MeanderingProgrammer/render-markdown.nvim), [live-preview](https://github.com/brianhuster/live-preview.nvim) |
| Thèmes | Catppuccin, Tokyo Night, Kanagawa, Rosé Pine, Nightfox, OneDark, Cyberdream, Dracula, Nord, GitHub, Gruvbox Material, Everforest, Sonokai, Oxocarbon |
