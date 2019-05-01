> A oh-my-zsh configure auto deploy shell
>
> by a lazy man @gunjianpan

- When you login a new servicer or use new docker container,
- Do you feel **depressed**🙉, because of the write code interface?
- Do you feel **manic**😡, because there are no coding suggestion?
- Do you feel **tired**😷, because you have to use so many service that you can't deploy zsh env every service.

**Now**, Everything you can use **zsh.sh** to solve this problem.

This shell include

- zsh, curl, git
- oh-my-zsh, zsh-syntax-highlighting, zsh-autosuggestions
- fzf, fd
- vimrc

## Support Linux Distribution

Now: support **Ubuntu** + **CentOS** + **MacOS**(I can't find a test machine, hhh, maybe have some bugs.)

- Test in docker & host version, in AiliYun, TencentCloud and huaweicloud
- Support amb64 & i386.
- Support docker version for Ubuntu, CentOS, Ubuntu/32bit

## Quick Start

### zsh.sh

PS: you need execute `bash zsh.sh && source ${ZDOTDIR:-$HOME}/.zshrc` by twice

```bash
wget https://raw.github.com/iofu728/zsh.sh/master/zsh.sh
bash zsh.sh && source ${ZDOTDIR:-$HOME}/.zshrc
bash zsh.sh && source ${ZDOTDIR:-$HOME}/.zshrc
```

### Docker

**Notice**: Docker version need execute `vim +'PlugInstall --sync' +qall &> /dev/null < /dev/tty` after docker exec to ima, if you want to use vim plug function。

- Ubuntu:18.04

```bash
docker pull gunjianpan/zsh.sh.ubuntu
docker run -it -d --name zsh_ubuntu gunjianpan/zsh.sh.ubuntu
docker exec -it zsh_ubuntu /bin/zsh
vim +'PlugInstall --sync' +qall &> /dev/null < /dev/tty
```

- Ubuntu32:16.04

```bash
docker pull gunjianpan/zsh.sh.ubuntu32
docker run -it -d --name zsh_ubuntu32 gunjianpan/zsh.sh.ubuntu32
docker exec -it zsh_ubuntu32 /bin/zsh
vim +'PlugInstall --sync' +qall &> /dev/null < /dev/tty
```

- CentOS:7

```bash
docker pull gunjianpan/zsh.sh.centos
docker run -it -d --name zsh_centos gunjianpan/zsh.sh.centos
docker exec -it zsh_centos /bin/zsh
vim +'PlugInstall --sync' +qall &> /dev/null < /dev/tty
```

![image](https://cdn.nlark.com/yuque/0/2019/gif/104214/1556732721406-9e47831f-b6a0-406d-b9f5-813d89233a01.gif)

![image](https://cdn.nlark.com/yuque/0/2019/png/104214/1556732743655-597b39cb-d38d-4431-a4a2-776f029af6ca.png)

## Document

- [zhihu](https://zhuanlan.zhihu.com/p/53380250)
- [blog](https://wyydsb.xin/other/terminal.html)

## QA

> 1.Q: Apt install error, like `HASH MISMATCH`
>
> A: Hash mismatch is cause by Communication Service Provider, CSP crash clash.
>
> You can change Internet source, like `Personal Hotspot`
>
> 2.Q: I pull your docker image and run exec, but I can't enter oh-my-zsh interface.
>
> A: You must exec by /bin/zsh. It means your local OS must have zsh.
>
> `docker exec -it zsh_ubuntu /bin/zsh`
>
> 3.: When exit ssh connect or docker exec, terminal show lots of error, like `bash: autoload: command not found`
>
> A: It causing by change default shell from `/bin/zsh` -> `/bin/bash`.
>
> If you exec docker by `/bin/bash` and install zsh with our shell, It will show this error,
> because of default shell change to your enter set `/bin/bash`
>
> So, you must enter docker by `docker exec -it zsh_ubuntu /bin/zsh`
>
> 4.Q: why don't you execute `vim +'PlugInstall --sync' +qall &> /dev/null < /dev/tty` in Docker build progress
>
> A: In build progress, There are no /dev/tty can be used. I also explore to find a way reduce user operation.
> In the same way, we also need user to execute `bash zsh.sh && source ${ZDOTDIR:-$HOME}/.zshrc` by twice.
> It cause by `source` & `env` mechanism.
