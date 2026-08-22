#!/bin/bash
# @Author: gunjianpan
# @Date:   2019-04-30 13:26:25
# @Last Modified time: 2026-08-22 16:35:00
# A zsh deploy shell for ubuntu.
# In this shell, will install zsh, oh-my-zsh, zsh-syntax-highlighting, zsh-autosuggestions, fzf-tab, fzf, atuin, zoxide, direnv, carapace, vimrc, bat

set -e

root=false
force_glibc=false

usage() {
    cat <<'EOS'
Usage: bash zsh.sh [options]

  -r, --root         chsh the current user default shell to zsh
      --force-glibc  CentOS only: build & install glibc-2.18 over the system
                     glibc when it is too old for the fd/bat .deb packages.
                     DANGEROUS, can break the system. Off by default.
  -h, --help         show this help

PS: you need to execute `bash zsh.sh && source ${ZDOTDIR:-$HOME}/.zshrc` twice.
EOS
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -r | --root) root=true ;;
    --force-glibc) force_glibc=true ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown parameter passed: $1"
        usage
        exit 1
        ;;
    esac
    shift
done

# some constant params
FD_VERSION=10.4.2
BAT_VERSION=0.26.1
ZSH_HL=zsh-syntax-highlighting
ZSH_AS=zsh-autosuggestions
ZSH_FT=fzf-tab
# $ZSH is exported by ~/.zshrc (oh-my-zsh); keep a default for the first run
ZSH=${ZSH:-${ZDOTDIR:-$HOME}/.oh-my-zsh}
ZSH_CUSTOM=${ZSH_CUSTOM:-${ZSH}/custom}
ZSH_P=${ZSH_CUSTOM}/plugins
ZSH_HL_P=${ZSH_P}/${ZSH_HL}
ZSH_AS_P=${ZSH_P}/${ZSH_AS}
ZSH_FT_P=${ZSH_P}/${ZSH_FT}
ZSHRC=${ZDOTDIR:-$HOME}/.zshrc
FZF=${ZDOTDIR:-$HOME}/.fzf
FD_URL=https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/
BAT_URL=https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/

VIM_P=${ZDOTDIR:-$HOME}/.vim_runtime
VIM_URL='https://github.com/amix/vimrc'
VIMRC=${ZDOTDIR:-$HOME}/.vimrc
VIMPLUG_URL='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
VIMPLUG_P=${ZDOTDIR:-$HOME}'/.vim/autoload/plug.vim'
VIMRC_URL='https://raw.githubusercontent.com/iofu728/zsh.sh/master/.vimrc'

BASH_SH='bash zsh.sh'
# literal on purpose: echoed back to the user as the command to run
# shellcheck disable=SC2016
SOURCE_SH='source ${ZDOTDIR:-$HOME}/.zshrc'
OH_MY_ZSH_URL='https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh'
GITHUB='https://github.com/iofu728/zsh.sh'
ZSH_USER_URL='https://github.com/zsh-users/'
ZSH_HL_URL=${ZSH_USER_URL}${ZSH_HL}
ZSH_AS_URL=${ZSH_USER_URL}${ZSH_AS}
ZSH_FT_URL='https://github.com/Aloxaf/fzf-tab'

HOMEBREW_URL='https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'
HOMEBREW_TUNA='https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/'

GLIBC='glibc-2.18'
GLIBC_TAR=${GLIBC}'.tar.gz'
GLIBC_URL='http://mirrors.ustc.edu.cn/gnu/libc/'${GLIBC_TAR}

SIGN_1='#-#-#-#-#-#-#-#-#-#'
SIGN_2='---__---'
SIGN_3='**************'
INS='Installing'
DOW='Downloading'

# echo color
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
CYAN='\033[1;96m'
NC='\033[0m'

echo_color() {
    local color
    case ${1} in
    red) color=${RED} ;;
    green) color=${GREEN} ;;
    yellow) color=${YELLOW} ;;
    blue) color=${BLUE} ;;
    cyan) color=${CYAN} ;;
    *)
        echo "${2}"
        return 0
        ;;
    esac
    echo -e "${color} ${2} ${NC}"
}

# has <cmd>: true when <cmd> is an executable in PATH
has() {
    command -v "${1}" >/dev/null 2>&1
}

unsupported() {
    echo_color red "Sorry, this .sh does not support your Distribution ${DISTRIBUTION:-unknown}. Please open one issue in ${GITHUB} "
    exit "${1:-2}"
}

# fetch <url> <dest>
fetch() {
    curl -fsSL "${1}" -o "${2}"
}

detect_distribution() {
    if has sw_vers; then
        echo MacOS
        return 0
    fi
    if [ -r /etc/os-release ]; then
        local ids
        # /etc/os-release is a shell-fragment by spec
        # shellcheck disable=SC1091
        ids=$(. /etc/os-release 2>/dev/null && echo "${ID:-} ${ID_LIKE:-}") || ids=
        case " ${ids} " in
        *ubuntu* | *debian*)
            echo Ubuntu
            return 0
            ;;
        *centos* | *rhel* | *fedora*)
            echo CentOS
            return 0
            ;;
        *arch*)
            echo Arch
            return 0
            ;;
        *alpine*)
            echo Alpine
            return 0
            ;;
        esac
    fi
    if has yum || has dnf; then
        echo CentOS
    elif has apt || has apt-get; then
        echo Ubuntu
    elif has pacman; then
        echo Arch
    elif has apk; then
        echo Alpine
    fi
    return 0
}

DISTRIBUTION=${DISTRIBUTION:-$(detect_distribution)}

# a normal account needs sudo, root does not have to have it installed
if [ "$(id -u)" -ne 0 ] && has sudo; then
    SUDO=sudo
else
    SUDO=
fi

case ${DISTRIBUTION} in
Ubuntu)
    if has apt; then APT=apt; else APT=apt-get; fi
    ag="${SUDO} ${APT}"
    ;;
CentOS)
    if has dnf; then YUM=dnf; else YUM=yum; fi
    ;;
esac

check_install() {
    if has "${1}"; then
        return 0
    fi
    echo_color green "${SIGN_1} ${INS} ${1} ${SIGN_1}"
    case ${DISTRIBUTION} in
    MacOS) brew install "${1}" ;;
    Ubuntu) ${ag} install "${1}" -y ;;
    CentOS) ${SUDO} "${YUM}" install "${1}" -y ;;
    Arch) ${SUDO} pacman -Sy "${1}" --noconfirm ;;
    Alpine) ${SUDO} apk add "${1}" ;;
    *) unsupported 2 ;;
    esac
}

# fd/bat publish i686 debs, but `dpkg --print-architecture` says i386
deb_arch() {
    local bit
    bit=$(dpkg --print-architecture)
    case ${bit} in
    i386) echo i686 ;;
    *) echo "${bit}" ;;
    esac
}

# CentOS 7 ships glibc 2.17, the prebuilt debs need >= 2.18.
# Building glibc over /usr can brick the box, so it is opt-in.
prepare_centos_glibc() {
    if ! has dpkg; then
        echo_color yellow "${SIGN_2} ${INS} dpkg ${SIGN_2}"
        ${SUDO} "${YUM}" install epel-release -y && ${SUDO} "${YUM}" repolist &&
            ${SUDO} "${YUM}" install dpkg-devel dpkg-dev -y
    fi
    if strings /lib64/libc.so.6 2>/dev/null | grep -q 'GLIBC_2.18'; then
        return 0
    fi
    if [ "${force_glibc}" != true ]; then
        echo_color red "${SIGN_3} system glibc < 2.18, skip this package. Rerun with --force-glibc to build ${GLIBC} (DANGEROUS) ${SIGN_3}"
        return 1
    fi
    if ! has gcc; then
        echo_color yellow "${SIGN_2} ${INS} gcc ${SIGN_2}"
        ${SUDO} "${YUM}" install gcc make -y
    fi
    echo_color yellow "${SIGN_2} ${DOW} ${GLIBC} ${SIGN_2}"
    cd "${ZDOTDIR:-$HOME}" && fetch "${GLIBC_URL}" "${GLIBC_TAR}"
    tar -zxf "${GLIBC_TAR}" && cd "${GLIBC}"
    echo_color yellow "${SIGN_2} ${INS} ${GLIBC} ${SIGN_2}"
    mkdir -p build && cd build && bash ../configure --prefix=/usr
    make -j4 >/dev/null && ${SUDO} make install >/dev/null
}

# install_pkg <name> <version> <deb-url-prefix>
install_pkg() {
    if has "${1}"; then
        return 0
    fi
    case ${DISTRIBUTION} in
    MacOS) check_install "${1}" ;;
    Arch)
        # skip on Git Bash / MSYS, where pacman has no such package
        if ! command -v git | grep -q mingw64; then
            ${SUDO} pacman -S "${1}" --noconfirm
        fi
        ;;
    Alpine) ${SUDO} apk add "${1}" ;;
    Ubuntu | CentOS)
        if [ "${DISTRIBUTION}" = CentOS ]; then
            prepare_centos_glibc || return 0
        elif ! has dpkg; then
            ${ag} install dpkg -y
        fi
        echo_color yellow "${SIGN_2} ${DOW} ${1} ${SIGN_2}"
        local deb
        deb=${1}_${2}_$(deb_arch).deb
        cd "${ZDOTDIR:-$HOME}" && rm -rf "${deb}"*
        fetch "${3}${deb}" "${deb}" && ${SUDO} dpkg -i "${deb}"
        ;;
    *) unsupported 2 ;;
    esac
}

# append <line> to ~/.zshrc, once
append_zshrc() {
    if ! grep -qF "${1}" "${ZSHRC}" 2>/dev/null; then
        echo "${1}" >>"${ZSHRC}"
    fi
}

# append <line> to ~/.zshrc unless <match> already appears in it; use this
# when the same line may exist with different quoting
append_zshrc_match() {
    if ! grep -qF "${1}" "${ZSHRC}" 2>/dev/null; then
        echo "${2}" >>"${ZSHRC}"
    fi
}

# sed -i, BSD (MacOS) and GNU flavours
sed_i() {
    local expr=${1}
    shift
    case ${DISTRIBUTION} in
    MacOS) sed -i '' "${expr}" "$@" ;;
    *) sed -i "${expr}" "$@" ;;
    esac
}

update_list() {
    case ${DISTRIBUTION} in
    MacOS)
        if [ ! -d /Library/Developer/CommandLineTools ]; then
            xcode-select --install
        fi
        # Homebrew
        if ! has brew; then
            echo_color yellow "${SIGN_2} ${INS} homebrew ${SIGN_2}"
            /bin/bash -c "$(curl -fsSL ${HOMEBREW_URL})"
            # brew is not in PATH yet in this shell
            for brew_p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
                if [ -x "${brew_p}" ]; then
                    eval "$(${brew_p} shellenv)"
                    break
                fi
            done

            echo_color green "${SIGN_1} ${INS} git ${SIGN_1}"
            brew install git

            # tuna mirror, comment out the block below outside of China
            if [ -d "$(brew --repo)/.git" ]; then
                git -C "$(brew --repo)" remote set-url origin ${HOMEBREW_TUNA}brew.git
            fi
            if [ -d "$(brew --repo)/Library/Taps/homebrew/homebrew-core/.git" ]; then
                git -C "$(brew --repo)/Library/Taps/homebrew/homebrew-core" \
                    remote set-url origin ${HOMEBREW_TUNA}homebrew-core.git
            fi
        fi
        ;;
    Ubuntu) ${ag} update -y && ${ag} install dpkg -y ;;
    # no `yum update -y` here: a full system upgrade is slow and not needed
    CentOS) ${SUDO} "${YUM}" install which -y ;;
    Arch) ${SUDO} pacman -Syu --noconfirm ;;
    Alpine) ${SUDO} apk update ;;
    *) unsupported 1 ;;
    esac
}

# zsh-syntax-highlighting + zsh-autosuggestions + fzf-tab + .zshrc plugins line
install_zsh_plugins() {
    if [ ! -d "${ZSH_HL_P}" ]; then
        echo_color yellow "${SIGN_2} ${DOW} ${ZSH_HL} ${SIGN_2}"
        git clone --depth 1 ${ZSH_HL_URL} "${ZSH_HL_P}"
    fi
    append_zshrc_match "plugins/${ZSH_HL}/${ZSH_HL}.zsh" "source \$ZSH_CUSTOM/plugins/${ZSH_HL}/${ZSH_HL}.zsh"

    if [ ! -d "${ZSH_FT_P}" ]; then
        echo_color yellow "${SIGN_2} ${DOW} ${ZSH_FT} ${SIGN_2}"
        git clone --depth 1 ${ZSH_FT_URL} "${ZSH_FT_P}"
    fi
    # fzf-tab wraps the completion widgets, so it should load BEFORE
    # zsh-autosuggestions; on a fresh .zshrc this append order guarantees it.
    # On a .zshrc where autosuggestions is already sourced it lands at the end,
    # which still works but is not the upstream-recommended order.
    append_zshrc_match "plugins/${ZSH_FT}/fzf-tab.plugin.zsh" "source \$ZSH_CUSTOM/plugins/${ZSH_FT}/fzf-tab.plugin.zsh"

    if [ ! -d "${ZSH_AS_P}" ]; then
        echo_color yellow "${SIGN_2} ${DOW} ${ZSH_AS} ${SIGN_2}"
        git clone --depth 1 ${ZSH_AS_URL} "${ZSH_AS_P}"
    fi
    append_zshrc_match "plugins/${ZSH_AS}/${ZSH_AS}.zsh" "source \$ZSH_CUSTOM/plugins/${ZSH_AS}/${ZSH_AS}.zsh"

    # change ~/.zshrc, the plugins are sourced above, don't load them twice
    sed_i 's/plugins=(git)/plugins=(git docker)/' "${ZSHRC}"
}

# fd & bat, from https://github.com/sharkdp
install_fd_bat() {
    install_pkg fd $FD_VERSION $FD_URL
    if [ "${DISTRIBUTION}" != Alpine ]; then
        install_pkg bat $BAT_VERSION $BAT_URL
    fi
}

# fzf & default key-bindings
install_fzf() {
    if [ -d "${FZF}" ] || [ "${DISTRIBUTION}" = Alpine ]; then
        return 0
    fi
    echo_color yellow "${SIGN_2} ${DOW} fzf ${SIGN_2}"
    git clone --depth 1 https://github.com/junegunn/fzf "${FZF}"
    echo_color yellow "${SIGN_2} ${INS} fzf ${SIGN_2}"
    bash "${FZF}"/install --all

    # alter filefind to fd
    append_zshrc "export FZF_DEFAULT_COMMAND='fd --type file'"
    append_zshrc "export FZF_CTRL_T_COMMAND=\$FZF_DEFAULT_COMMAND"
    append_zshrc "export FZF_ALT_C_COMMAND='fd -t d . '"

    # Ctrl+R History command; Ctrl+R file catalog
    # if you want to DIY key of like 'Atl + C'
    # maybe line-num is not 64, but must nearby
    sed_i 's/\\ec/^\\/' "${FZF}"/shell/key-bindings.zsh
}

# vimrc + vim-plug
install_vimrc() {
    if [ -d "${VIM_P}" ] || [ "${DISTRIBUTION}" = Alpine ]; then
        return 0
    fi
    echo_color yellow "${SIGN_2} ${DOW} vimrc ${SIGN_2}"
    git clone --depth=1 ${VIM_URL} "${VIM_P}"
    echo_color yellow "${SIGN_2} ${INS} vimrc ${SIGN_2}"
    sh "${VIM_P}"/install_awesome_vimrc.sh

    curl -fLo "${VIMPLUG_P}" --create-dirs ${VIMPLUG_URL}
    if [ -f "${VIMRC}" ]; then
        cp "${VIMRC}" "${VIMRC}".old.1
    fi
    fetch ${VIMRC_URL} "${VIMRC}"

    if [ -z "${IS_DOCKER:-}" ] && [ -e /dev/tty ]; then
        echo_color yellow "${SIGN_2} ${INS} vim plugs ${SIGN_2}"
        vim +'PlugInstall --sync' +qall &>/dev/null </dev/tty ||
            echo_color red "PlugInstall failed, run ·vim +'PlugInstall --sync' +qall· by hand"
    fi
}

# atuin (history search), zoxide (smart cd), direnv (per-dir env),
# carapace (generic completions) -- best effort per distro
install_shell_tools() {
    local tool
    for tool in atuin zoxide direnv carapace; do
        if has "${tool}"; then
            continue
        fi
        case ${DISTRIBUTION} in
        MacOS) brew install "${tool}" ;;
        Ubuntu | CentOS)
            # only zoxide & direnv are in the default apt/yum repos
            case ${tool} in
            zoxide | direnv) check_install "${tool}" ;;
            *) echo_color yellow "${SIGN_2} ${tool} is not in the default repos, install it manually ${SIGN_2}" ;;
            esac
            ;;
        Arch) ${SUDO} pacman -S "${tool}" --noconfirm || echo_color yellow "${SIGN_2} install ${tool} manually (AUR) ${SIGN_2}" ;;
        Alpine) ${SUDO} apk add "${tool}" || echo_color yellow "${SIGN_2} install ${tool} manually ${SIGN_2}" ;;
        *) echo_color yellow "${SIGN_2} install ${tool} manually ${SIGN_2}" ;;
        esac
    done
}

# zshrc tweaks: startup perf, brew mirrors and the cached tool inits.
# Runs in the foreground (after the parallel installs) because it appends
# multi-line blocks to ${ZSHRC}.
configure_zshrc() {
    # skip oh-my-zsh's compaudit security scan of $fpath on every startup
    append_zshrc "export ZSH_DISABLE_COMPFIX=true"

    if [ "${DISTRIBUTION}" = MacOS ]; then
        # ghcr.io (the default bottle host) is slow from some networks;
        # route brew API metadata, bottles and git fetches through USTC
        append_zshrc "export HOMEBREW_API_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles/api"
        append_zshrc "export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles"
        append_zshrc "export HOMEBREW_BREW_GIT_REMOTE=https://mirrors.ustc.edu.cn/brew.git"
        append_zshrc "export HOMEBREW_CORE_GIT_REMOTE=https://mirrors.ustc.edu.cn/homebrew-core.git"
    fi

    # `eval "$(tool init zsh)"` forks a subprocess on every startup; cache the
    # generated code and regenerate only when the binary changes (brew upgrade)
    if ! grep -qF '_cached_init()' "${ZSHRC}" 2>/dev/null; then
        cat >>"${ZSHRC}" <<'EOS'

_cached_init() {
  local name=$1 bin=$2; shift 2
  local cache="$HOME/.cache/zsh/init-$name.zsh"
  if [[ ! -r $cache || $commands[$bin] -nt $cache ]]; then
    mkdir -p "$HOME/.cache/zsh"
    "$@" >| "$cache" 2>/dev/null
  fi
  source "$cache"
}
# atuin: Ctrl+R becomes a full-text history search (up arrow untouched)
(( $+commands[atuin] ))    && _cached_init atuin atuin atuin init zsh --disable-up-arrow
# zoxide: `z foo` jumps to frecent directories, `zi` for interactive pick
(( $+commands[zoxide] ))   && _cached_init zoxide zoxide zoxide init zsh
# direnv: per-directory env via .envrc
(( $+commands[direnv] ))   && _cached_init direnv direnv direnv hook zsh
# carapace: lazy completions for hundreds of CLIs
(( $+commands[carapace] )) && _cached_init carapace carapace carapace _carapace zsh
EOS
    fi
}

if [ ! -d "${ZSH}" ]; then
    update_list
    check_install zsh
    check_install curl
    check_install git
    check_install vim
    case ${DISTRIBUTION} in
    Arch | Alpine) ;; # busybox / no chsh
    *)
        if [ "${root}" = true ]; then
            chsh -s "$(command -v zsh)" || echo_color red "chsh failed, keep the current default shell"
        fi
        ;;
    esac

    echo_color yellow "${SIGN_1} ${INS} oh-my-zsh ${SIGN_1}"
    echo_color red "${SIGN_3} After Install you should ·${BASH_SH} && ${SOURCE_SH}· Again ${SIGN_3}"
    sh -c "$(curl -fsSL ${OH_MY_ZSH_URL})" "" --unattended
else
    echo_color green "ZSH_CUSTOM: ${ZSH_CUSTOM}"

    # the four installs are independent, run them in parallel;
    # wait for all and fail if any of them failed
    install_zsh_plugins &
    install_fd_bat &
    install_fzf &
    install_vimrc &

    rc=0
    for pid in $(jobs -p); do
        wait "${pid}" || rc=1
    done
    if [ ${rc} -ne 0 ]; then
        echo_color red "some install step failed, rerun ·${BASH_SH}· to retry"
        exit 1
    fi

    # in the foreground: package managers don't like running concurrently,
    # and configure_zshrc appends multi-line blocks to ${ZSHRC}
    install_shell_tools
    configure_zshrc

    echo_color red "Warning: If you only execute ·${BASH_SH}·. You need ·${SOURCE_SH}· After running this shell."
    echo_color blue 'Zsh deploy finish. Now you can enjoy it💂'
    echo_color yellow "More Info Can Find in https://wyydsb.xin/other/terminal.html & ${GITHUB} 😶"
fi
