## Installation

```
git clone git@github.com:201-created/pear.git ~/.pear
echo "source ~/.pear/bash.sh" >> ~/.bash_profile
echo "source-file ~/.pear/tmux.conf" >> ~/.tmux.conf
echo "so ~/.pear/vimrc" >> ~/.vimrc
git clone git@github.com:gmarik/Vundle.vim.git ~/.pear/vim/bundle/Vundle.vim
vim +PluginInstall +qall
```

### Git Config

Add this section to your global gitconfig at `~/.gitconfig`:

```
[include]
  path = ~/.pear/gitconfig
```
