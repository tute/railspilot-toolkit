#!/usr/bin/env bash
# PreToolUse Bash hook. Allows rm on literal paths inside the project or a
# temp dir, and lockfile installs. Asks for risky rm and for installs that
# fetch new code. Stays silent otherwise.
set -u

input=$(cat)

if ! command -v jq >/dev/null; then
  case $input in
    *rm\ *) printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"bash-guard needs jq to check rm targets"}}' ;;
  esac
  exit 0
fi

decide() {
  jq -cn --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0
cwd=$(jq -r '.cwd // empty' <<<"$input")
cwd=${cwd:-$PWD}

phys_dir() { (cd "$1" 2>/dev/null && pwd -P); }

normalize() {
  local IFS=/ part out=''
  set -f
  for part in $1; do
    case $part in
      '' | .) ;;
      ..) out=${out%/*} ;;
      *) out="$out/$part" ;;
    esac
  done
  set +f
  printf '%s' "${out:-/}"
}

phys_path() {
  local p=$1 rest='' d
  while [ "$p" != / ] && [ ! -d "$p" ]; do
    rest="/${p##*/}$rest"
    p=${p%/*}
    [ -n "$p" ] || p=/
  done
  d=$(phys_dir "$p") || d=$p
  [ "$d" = / ] && d=''
  printf '%s' "$d$rest"
}

home=$(phys_dir "$HOME")
roots=''
add_root() {
  local r
  r=$(phys_dir "${1:-/nonexistent}") || return 0
  case $r in / | "$home") return 0 ;; esac
  roots="$roots$r
"
}
project=$(phys_dir "${CLAUDE_PROJECT_DIR:-$cwd}")
add_root "$project"
add_root "${TMPDIR:-}"
add_root /tmp

inside_roots() {
  local r
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    case $1 in "$r"/*) return 0 ;; esac
  done <<<"$roots"
  return 1
}

n=0
unclear=0
w=''
f=''
inword=0
redir=0

flush() {
  if [ "$inword" = 1 ]; then
    if [ "$redir" = 1 ]; then
      redir=0
    else
      T_WORD[n]=$w T_FLAG[n]=$f T_OP[n]=''
      n=$((n + 1))
    fi
  fi
  w='' f='' inword=0
}

add_op() {
  flush
  [ "$redir" = 1 ] && unclear=1
  T_WORD[n]='' T_FLAG[n]='' T_OP[n]=$1
  n=$((n + 1))
}

tokenize() {
  local s=$1 len=${#1} i=0 c nx j
  while [ $i -lt $len ]; do
    c=${s:i:1}
    nx=${s:i+1:1}
    case $c in
      ' ' | $'\t') flush ;;
      $'\n') add_op ';' ;;
      "'")
        inword=1
        j=$((i + 1))
        while [ $j -lt $len ] && [ "${s:j:1}" != "'" ]; do j=$((j + 1)); done
        [ $j -lt $len ] || { unclear=1; return; }
        w="$w${s:i+1:j-i-1}"
        i=$j
        ;;
      '"')
        inword=1
        i=$((i + 1))
        while [ $i -lt $len ] && [ "${s:i:1}" != '"' ]; do
          c=${s:i:1}
          case $c in
            \\) i=$((i + 1)); w="$w${s:i:1}" ;;
            '$')
              f="${f}e"
              [ "${s:i+1:1}" = '(' ] && { unclear=1; return; }
              w="$w$c"
              ;;
            '`') unclear=1; return ;;
            *) w="$w$c" ;;
          esac
          i=$((i + 1))
        done
        [ $i -lt $len ] || { unclear=1; return; }
        ;;
      \\)
        i=$((i + 1))
        if [ "$nx" != $'\n' ]; then inword=1; w="$w$nx"; fi
        ;;
      '$')
        [ "$nx" = '(' ] && { unclear=1; return; }
        inword=1 f="${f}e" w="$w$c"
        ;;
      '`' | '(' | ')') unclear=1; return ;;
      '*' | '?' | '[') inword=1 f="${f}g" w="$w$c" ;;
      '{' | '}') inword=1 f="${f}b" w="$w$c" ;;
      '~')
        [ "$inword" = 0 ] && f="${f}t"
        inword=1 w="$w$c"
        ;;
      '#')
        if [ "$inword" = 0 ]; then break; fi
        w="$w$c"
        ;;
      ';')
        [ "$nx" = ';' ] && { unclear=1; return; }
        add_op ';'
        ;;
      '&')
        if [ "$nx" = '&' ]; then add_op '&&'; i=$((i + 1))
        elif [ "$nx" = '>' ]; then flush; redir=1; i=$((i + 1))
        else add_op '&'
        fi
        ;;
      '|')
        if [ "$nx" = '|' ]; then add_op '||'; i=$((i + 1))
        elif [ "$nx" = '&' ]; then add_op '|&'; i=$((i + 1))
        else add_op '|'
        fi
        ;;
      '>' | '<')
        case $w in *[!0-9]* | '') flush ;; *) [ -z "$f" ] && w='' inword=0 || flush ;; esac
        case $c$nx in '<<' | '<(' | '>(') unclear=1; return ;; esac
        case $nx in '>' | '|') i=$((i + 1)); nx=${s:i+1:1} ;; esac
        if [ "$nx" = '&' ]; then
          i=$((i + 1))
          while case ${s:i+1:1} in [0-9] | -) true ;; *) false ;; esac; do i=$((i + 1)); done
        else
          redir=1
        fi
        ;;
      *) inword=1 w="$w$c" ;;
    esac
    i=$((i + 1))
  done
  flush
  [ "$redir" = 1 ] && unclear=1
}

tokenize "$cmd"

if [ "$unclear" = 1 ]; then
  case " $cmd" in
    *[\ \;\&\|\(\`/\$\'\"]rm*) decide ask "Could not parse this command to check its rm targets" ;;
    *curl* | *wget*) decide ask "Could not parse this command that downloads with curl or wget" ;;
  esac
  exit 0
fi

seg=other
acted=0
fetched=0

arg_is_value_flag() {
  case $1 in
    -C | --dir | --filter | -F | --prefix | --cwd | --gemfile | --jobs | -j | --path | --with | --without | --retry | --workspace | -w) return 0 ;;
  esac
  return 1
}

only_options() {
  local i=$1 a
  while [ $i -lt $2 ]; do
    a=${T_WORD[i]}
    case $a in
      -g | --global | --location=global) return 2 ;;
      -*) arg_is_value_flag "$a" && i=$((i + 1)) ;;
      *) return 1 ;;
    esac
    i=$((i + 1))
  done
  return 0
}

lockfile_install() {
  only_options "$1" "$2"
  case $? in
    0) seg=safe; acted=1 ;;
    2) decide ask "$3 installs globally" ;;
    *) decide ask "$3 with package names adds new dependencies" ;;
  esac
}

check_runner() {
  local i=$1 a name
  while [ $i -lt $2 ]; do
    a=${T_WORD[i]}
    case $a in
      -y | --yes | -p | --package | --package=*) decide ask "$3 $a may download a package" ;;
      -*) ;;
      *) name=$a; break ;;
    esac
    i=$((i + 1))
  done
  [ -n "${name:-}" ] || return 0
  case $name in ?*@*) decide ask "$3 $name downloads a pinned package" ;; esac
  [ -n "$cwd" ] && [ -x "$cwd/node_modules/.bin/$name" ] && return 0
  decide ask "$3 $name is not in node_modules/.bin, so it may download it"
}

first_sub() {
  local i=$1 a
  while [ $i -lt $2 ]; do
    a=${T_WORD[i]}
    case $a in
      -*) arg_is_value_flag "$a" && i=$((i + 1)) ;;
      *) printf '%s' "$i"; return ;;
    esac
    i=$((i + 1))
  done
  printf '%s' "$2"
}

check_target() {
  local word=$1 flags=$2 path base dir
  case $flags in *e*) decide ask "rm target uses a variable: $word" ;; esac
  case $flags in *b*) decide ask "rm target uses brace expansion: $word" ;; esac
  [ -n "$word" ] || decide ask "rm target is an empty string"
  path=$word
  case $flags in
    *t*)
      case $word in
        '~' | '~/'*) path="$HOME${word#\~}" ;;
        *) decide ask "rm target uses another user's home: $word" ;;
      esac
      ;;
  esac
  case $path in
    /*) ;;
    *)
      [ -n "$cwd" ] || decide ask "rm target is relative after cd to an unknown dir: $word"
      path="$cwd/$path"
      ;;
  esac
  case $flags in
    *g*)
      base=${path%%[*?[]*}
      dir=${base%/*}
      path=$(phys_path "$(normalize "${dir:-/}")")
      inside_roots "$path" || decide ask "rm glob $word expands in $path, outside the project and temp dirs"
      ;;
    *)
      case $word in
        */) path=$(normalize "$path"); [ -d "$path" ] && path=$(phys_dir "$path") ;;
        *) path=$(phys_path "$(normalize "$path")") ;;
      esac
      inside_roots "$path" || decide ask "rm target $path is outside the project and temp dirs"
      ;;
  esac
  case $path in */.git | */.git/*) decide ask "rm target is inside .git: $word" ;; esac
  case $project/ in "$path"/*) decide ask "rm target $word would remove the project or its parent" ;; esac
  return 0
}

check_rm() {
  local i=$1 opts=1 a
  while [ $i -lt $2 ]; do
    a=${T_WORD[i]}
    i=$((i + 1))
    if [ $opts = 1 ] && [ -z "${T_FLAG[i-1]}" ]; then
      case $a in
        --) opts=0; continue ;;
        -?*) continue ;;
      esac
    fi
    check_target "$a" "${T_FLAG[i-1]}"
  done
  seg=safe
  acted=1
}

check_segment() {
  local s=$1 e=$2 prev=$3 cmd0 base i sub assign=0
  seg=other
  while [ $s -lt $e ]; do
    case ${T_WORD[s]} in
      [A-Za-z_]*=*) assign=1; s=$((s + 1)) ;;
      *) break ;;
    esac
  done
  [ $s -lt $e ] || { seg=empty; return; }
  [ "${T_WORD[s]}" = rtk ] && [ $((s + 1)) -lt $e ] && s=$((s + 1))
  cmd0=${T_WORD[s]}
  base=${cmd0##*/}
  case $prev in '|' | '|&') ;; *) fetched=0 ;; esac

  if [ "$base" != rm ] && [ "$base" != rmdir ] && [ "$base" != git ]; then
    i=$((s + 1))
    while [ $i -lt $e ]; do
      case ${T_WORD[i]} in
        rm | rmdir | */rm | */rmdir) decide ask "rm runs through $base, so its targets can't be checked" ;;
      esac
      i=$((i + 1))
    done
  fi

  case $base in
    rm | rmdir)
      [ $assign = 0 ] || decide ask "rm runs with variable assignments in front"
      check_rm $((s + 1)) "$e"
      ;;
    cd)
      if [ $((s + 2)) = "$e" ] && [ -z "${T_FLAG[s+1]}" ]; then
        case ${T_WORD[s+1]} in
          /*) cwd=$(normalize "${T_WORD[s+1]}") ;;
          -) cwd='' ;;
          *) [ -n "$cwd" ] && cwd=$(normalize "$cwd/${T_WORD[s+1]}") ;;
        esac
      else
        cwd=''
      fi
      seg=safe
      ;;
    curl | wget) fetched=1 ;;
    sh | bash | zsh | dash | ksh | fish | python | python3 | ruby | node | perl)
      [ "$fetched" = 1 ] && decide ask "Pipes downloaded content into $base"
      ;;
    pnpm)
      sub=$(first_sub $((s + 1)) "$e")
      case ${T_WORD[sub]:-} in
        install | i) lockfile_install $((sub + 1)) "$e" "pnpm install" ;;
        add) decide ask "pnpm add adds new dependencies" ;;
        dlx) decide ask "pnpm dlx downloads and runs a package" ;;
      esac
      ;;
    npm)
      sub=$(first_sub $((s + 1)) "$e")
      case ${T_WORD[sub]:-} in
        ci | install | i | isntall) lockfile_install $((sub + 1)) "$e" "npm ${T_WORD[sub]}" ;;
        add) decide ask "npm add adds new dependencies" ;;
        exec | x) decide ask "npm exec may download and run a package" ;;
      esac
      ;;
    yarn)
      sub=$(first_sub $((s + 1)) "$e")
      case ${T_WORD[sub]:-} in
        '') [ "$sub" = "$e" ] && lockfile_install "$e" "$e" yarn ;;
        install) lockfile_install $((sub + 1)) "$e" "yarn install" ;;
        add | global) decide ask "yarn ${T_WORD[sub]} adds new dependencies" ;;
        dlx) decide ask "yarn dlx downloads and runs a package" ;;
      esac
      ;;
    bun)
      sub=$(first_sub $((s + 1)) "$e")
      case ${T_WORD[sub]:-} in
        install | i) lockfile_install $((sub + 1)) "$e" "bun install" ;;
        add) decide ask "bun add adds new dependencies" ;;
        x) decide ask "bun x may download and run a package" ;;
      esac
      ;;
    npx | bunx) check_runner $((s + 1)) "$e" "$base" ;;
    pnpx) decide ask "pnpx downloads and runs a package" ;;
    bundle)
      sub=$(first_sub $((s + 1)) "$e")
      case ${T_WORD[sub]:-} in
        '') [ "$sub" = "$e" ] && lockfile_install "$e" "$e" bundle ;;
        install) lockfile_install $((sub + 1)) "$e" "bundle install" ;;
        add) decide ask "bundle add adds new gems" ;;
      esac
      ;;
    gem | pip | pip3 | cargo | go | brew)
      case ${T_WORD[s+1]:-} in
        install | i | reinstall) decide ask "$base ${T_WORD[s+1]} downloads new code" ;;
      esac
      ;;
    uv)
      case ${T_WORD[s+1]:-} in
        add | pip | tool) decide ask "uv ${T_WORD[s+1]} may download new packages" ;;
      esac
      ;;
    uvx | pipx) decide ask "$base downloads and runs a package" ;;
  esac
  return 0
}

i=0
start=0
prev=''
all_safe=1
while [ $i -le $n ]; do
  if [ $i = $n ] || [ -n "${T_OP[i]}" ]; then
    check_segment "$start" "$i" "$prev"
    [ "$seg" = other ] && all_safe=0
    [ $i -lt $n ] && prev=${T_OP[i]}
    start=$((i + 1))
  fi
  i=$((i + 1))
done

[ "$all_safe" = 1 ] && [ "$acted" = 1 ] && decide allow "rm on literal project or temp paths, or a lockfile install"
exit 0
