#!/bin/bash
# @Author: gunjianpan
# @Date:   2019-04-30 13:26:25
# @Last Modified time: 2019-04-30 18:03:28
# A zsh deploy shell for ubuntu.
# In this shell, will install zsh, oh-my-zsh, zsh-syntax-highlighting, zsh-autosuggestions, fzf

set -e

FD_VERSION=7.3.0
ZSH_CUSTOM=${ZSH}/custom
DISTRIBUTION=$(lsb_release -a | grep -n 'Distributor ID:.*' | awk '{print $3}' 2>/dev/null)

# echo color
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
CYAN='\033[1;96m'
NC='\033[0m'

echo_color() {
    case ${1} in
    red)
        echo -e "${RED} ${2} ${NC}"
        ;;
    green)
        echo -e "${GREEN} ${2} ${NC}"
        ;;
    yellow)
        echo -e "${YELLOW} ${2} ${NC}"
        ;;
    blue)
        echo -e "${BLUE} ${2} ${NC}"
        ;;
    cyan)
        echo -e "${CYAN} ${2} ${NC}"
        ;;
    esac
}

check_install() {
    case $DISTRIBUTION in
    Ubuntu)
        if [ !-n "$(which ${1} | sed -n '/found/p')" ]; then
            echo_color green "#-#-#-#-#-#-#-#-#-# Instaling ${1} #-#-#-#-#-#-#-#-#-#"
            apt-get install ${1} -y
        fi
        ;;
    CentOS)
        if [ -n $(which ${1} 2>/dev/null) ]; then
            echo_color green "#-#-#-#-#-#-#-#-#-# Instaling ${1} #-#-#-#-#-#-#-#-#-#"
            yum install ${1} -y
        fi
        ;;
    *)
        echo_color red 'Sorry, this  does not support your Linux Distribution. Please open one issue in https://github.com/iofu728/zsh.sh '
        exit 2
        ;;
    esac
}

if [ ! -n "$(ls -a ${ZDOTDIR:-$HOME} | sed -n '/\.oh-my-zsh/p')" ]; then

    check_install zsh
    check_install curl
    check_install git
    check_install dpkg
    chsh -s $(which zsh)

    echo_color yellow '#-#-#-#-#-#-#-#-#-# Instaling oh-my-zsh #-#-#-#-#-#-#-#-#-#'
    echo_color red '************** After Install you should ·bash zsh_linux.sh && source ${ZDOTDIR:-$HOME}/.zshrc · Again **************'
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
else
    echo_color green "ZSH_CUSTOM: ${ZSH_CUSTOM}"
    # syntax highlighting
    if [ ! -n "$(ls ${ZSH_CUSTOM}/plugins | sed -n '/zsh-syntax-highlighting/p')" ]; then
        echo_color yellow '---__--- Downloading zsh highlighting ---__---'
        git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
        echo "source \$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >>${ZDOTDIR:-$HOME}/.zshrc
    fi

    # zsh-autosuggestions
    if [ ! -n "$(ls ${ZSH_CUSTOM}/plugins | sed -n '/zsh-autosuggestions/p')" ]; then
        echo_color yellow '---__--- Downloading zsh autosuggestions ---__---'
        git clone git://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
        echo "source \$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >>${ZDOTDIR:-$HOME}/.zshrc
    fi

    # change ~/.zshrc
    sed -i 's/plugins=(git)/plugins=(git docker zsh-autosuggestions)/' ${ZDOTDIR:-$HOME}/.zshrc

    # install fzf & bind default key-binding
    if [ ! -n "$(ls -a ${ZDOTDIR:-$HOME} | sed -n '/\.fzf/p')" ]; then
        echo_color yellow '---__--- Downloading fzf ---__---'
        git clone --depth 1 https://github.com/junegunn/fzf ${ZDOTDIR:-$HOME}/.fzf
        echo_color yellow '---__--- Installing fzf ---__---'
        bash ${ZDOTDIR:-$HOME}/.fzf/install <<<'yyy'

        # install fd, url from https://github.com/sharkdp/fd/releases
        echo_color yellow '---__--- Downloading fd  ---__---'
        wget https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd_${FD_VERSION}_amd64.deb
        dpkg -i fd_${FD_VERSION}_amd64.deb

        # alter filefind to fd
        echo "export FZF_DEFAULT_COMMAND='fd --type file'" >>${ZDOTDIR:-$HOME}/.zshrc
        echo "export FZF_CTRL_T_COMMAND=\$FZF_DEFAULT_COMMAND" >>${ZDOTDIR:-$HOME}/.zshrc
        echo "export FZF_ALT_C_COMMAND='fd -t d . '" >>${ZDOTDIR:-$HOME}/.zshrc

        # Ctrl+R History command; Ctrl+R file catalog
        # if you want to DIY key of like 'Atl + C'
        # maybe line-num is not 64, but must nearby
        sed -i 's/\\ec/^\\/' ${ZDOTDIR:-$HOME}/.fzf/shell/key-bindings.zsh
    fi

    echo_color red 'Warning: If you only execute ·bash zsh_linux.sh·. You need ·source ${ZDOTDIR:-$HOME}/.zshrc· After running this shell.'
    echo_color blue 'Zsh deploy finish. Now you can enjoy it💂'
    echo_color yellow 'More Info Can Find in https://wyydsb.xin/other/terminal.html & https://github.com/iofu728/zsh.sh 😶'
fi
