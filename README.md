# About this project

I’m sharing my personal setup in the hope that it may be beneficial to others. This Bash configuration file
is designed to automate repetitive tasks (such as constantly executing `ls` after `cd`) and shorten lengthy commands. 
It contains functions and aliases that I regularly update based on my needs on Kubuntu 24 and Debian 12.

Contributions and feedbacks are welcome.

## Installation instructions

#### 1. Download the `.bash_aliases.sh` file or clone this repository
```
git clone https://github.com/Julien-Fischer/bash_aliases
```

#### 2. Copy `.bash_aliases.sh` to your home directory
```
cp bash_aliases/bash_aliases.sh ~
```

#### 3. Add the following lines in `~/.bashrc`:
```
if [ -f ~/.bash_aliases.sh ]; then
    . ~/.bash_aliases.sh
fi
```

#### 4. Reload your bash configuration
```
source ~/.bashrc
```

**Notes:** For further reloads, just open your CLI and type: `reload`

## Upgrades

If you already installed this project, you can upgrade it to the latest version by typing: 
```
upgrade_aliases 
```

This function will: 
- clone this repository in the current working directory
- create a backup of the current `~/.bash_aliases.sh` file
- copy the new `.bash_aliases.sh` file in `home`
- remove the cloned directory
- reload `.bashrc`.

## Requirements

This setup was primarily tested on Kubuntu 24 and Debian 12.

Most of the functions/aliases defined in this project should be compatible with Debian-based distributions.

## License

This project is released under the [MIT License](https://opensource.org/licenses/MIT).