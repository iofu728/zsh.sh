FROM centos:7

LABEL maintaine gunjianpan '<iofu728@163.com>'

ENV OH_MY_ZSH_URL 'https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh'
ENV ZSH_LINUX_URL 'https://raw.github.com/iofu728/zsh.sh/master/zsh.sh'
ENV ZSH_SH_PATH 'zsh.sh'
ENV ZSH /root/.oh-my-zsh
ENV IS_DOCKER docker

RUN yum update -y && yum install zsh git curl wget which vim epel-release -y \
    && yum repolist \
    && yum install dpkg-devel dpkg-dev -y \
    && which zsh \
    && chsh -s $(which zsh)

RUN sh -c "$(curl -fsSL ${OH_MY_ZSH_URL})"

RUN curl -fsSL ${ZSH_LINUX_URL} >> ${ZDOTDIR:-$HOME}/${ZSH_SH_PATH}} \
    && bash ${ZDOTDIR:-$HOME}/${ZSH_SH_PATH}} \
    && /bin/zsh -c "source ${ZDOTDIR:-$HOME}/.zshrc"

CMD ["/bin/zsh"]