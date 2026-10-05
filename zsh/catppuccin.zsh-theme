# ╭──────────────────────────────────────────────────────────╮
# │  Thème Oh My Zsh — Catppuccin Mocha, sans outil externe   │
# │  Copier dans ~/.oh-my-zsh/custom/themes/                  │
# │  puis ZSH_THEME="catppuccin" dans ~/.zshrc                │
# ╰──────────────────────────────────────────────────────────╯
# Rendu :
#   ~/projets/jeu  main ●
#   ❯

typeset -g c_dir="%F{#89b4fa}"     # bleu
typeset -g c_git="%F{#cba6f7}"     # mauve
typeset -g c_dirty="%F{#f9e2af}"   # jaune
typeset -g c_ok="%F{#a6e3a1}"      # vert
typeset -g c_err="%F{#f38ba8}"     # rouge
typeset -g c_dim="%F{#6c7086}"     # gris

ZSH_THEME_GIT_PROMPT_PREFIX=" ${c_git} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" ${c_dirty}●"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# Durée de la dernière commande si elle dépasse 2 s.
zmodload zsh/datetime 2>/dev/null
_cat_preexec() { _cat_start=$EPOCHREALTIME }
_cat_precmd() {
  _cat_took=""
  if [[ -n $_cat_start ]]; then
    local d=$(( EPOCHREALTIME - _cat_start ))
    (( d > 2 )) && _cat_took=" ${c_dim}$(printf '%.1fs' $d)%f"
    unset _cat_start
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _cat_preexec
add-zsh-hook precmd _cat_precmd

PROMPT='
${c_dir}%~%f$(git_prompt_info)${_cat_took}
%(?.${c_ok}.${c_err})❯%f '
RPROMPT='%(1j.${c_dim}✦ %j%f.)'
