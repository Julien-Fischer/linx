# Linx (Link for Linux)

Linx is a streamlined and opinionated Bash configuration developped for power users who prioritize
speed and efficiency over graphical user interfaces. It provides a curated set of functions, aliases, and terminal configurations aimed at maximizing
efficiency and minimizing keystrokes.

Once installed, Linx offers seamless synchronization of your setup across multiple devices, effectively
creating a unified environment across your Linux systems.

To sync your configuration, simply type `linx sync`, and Linx will handle the rest.

## Features

Version `1.0.0-alpha` of Linx offers the following features:

- A comprehensive set of functions and aliases that minimize the time and effort required for directory navigation, file management, and common task execution
- Shortcuts for frequently accessed directories such as home, desktop, and dev, allowing users to quickly jump to desired locations
- Functions that streamline version control tasks and enhance log viewing capabilities
- For Terminator users, Linx offers preconfigured shortcuts, layouts, and the ability to install multiple native and third-party themes. Users can list and switch Terminator themes at runtime directly from the command line without additional Python installations or plugins

![Live Demo](./demo.gif)


## Examples

### Vanilla Bash VS Linx

- **(Navigation) Navigate to the home directory and pretty print its content**


| Scope         | Task                                              | :rocket: Using Linx | :sleepy: Without Linx                                                                                                                                |
|:--------------|:--------------------------------------------------|:--------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
| Navigation    | Go to Desktop                                     | desk                | cd $(xdg-user-dir DESKTOP) && pwd && ls -AF --group-directories-first --color                                                                        |
| Navigation    | Go to development projects directory              | dev                 | cd "${DEV}" && pwd && ls -AF --group-directories-first --color                                                                                       |
| Navigation    | Go to root directory                              | ,                   | cd / && pwd && ls -AF --group-directories-first --color                                                                                              |
| Navigation    | Go to home directory                              | ~                   | cd ~ && pwd && ls -AF --group-directories-first --color                                                                                              |
| Navigation    | Go to previous directory                          | -                   | cd - && pwd && ls -AF --group-directories-first --color                                                                                              |
| Navigation    | Go one directory up                               | ..                  | cd ..                                                                                                                                                |
| Navigation    | Go two directories up                             | ...                 | cd ../..                                                                                                                                             |
| Navigation    | Go six directories up                             | .......             | cd ../../../../../../                                                                                                                                |
| Navigation    | Go six directories up                             | u6                  | cd ../../../../../../                                                                                                                                |
| Visualization | Inspect current dir, sorted by alphabetical order | ll                  | ls -lhAF                                                                                                                                             |
| Visualization | Inspect current dir, sorted by modification date  | lt                  | ls -lhAFt -1                                                                                                                                         |
| Visualization | Inspect current dir, grouping directories first   | ld                  | ls -lhAF --group-directories-first                                                                                                                   |
| Visualization | Inspect current dir, in short format              | la                  | ls -AF --group-directories-first                                                                                                                     |
| Git           | Commit & push                                     | gap "msg"           | git add . && git commit -m "msg" && git push                                                                                                         |
| Git           | View releases                                     | glor                | git log --no-walk --tags --pretty=format:"%h %ad %d% %an% %s" --date=format:"%Y-%m-%d %H:%M" --abbrev-commit                                         |
| Git           | Pretty print log in ascending order               | glot asc            | git log --reverse --pretty=format:"%C(yellow)%h%C(reset) %C(red)%ad%C(reset) %C(cyan)%an%C(reset) %s" --date=format:"%Y-%m-%d %H:%M" --abbrev-commit |
| Git           | Stash all changes                                 | gas                 | git add . && git stash                                                                                                                               |
| Git           | Force push all changes                            | gapf "msg"          | git add . && git commit -m "msg" && git push --force origin                                                                                          |
| System        | Fully upgrade your packages                       | sup                 | sudo apt update && sudo apt full-upgrade -y                                                                                                          |


### Linx-specific features

- **(Terminator) List themes and profiles**
```
profiles
```

- **(Terminator) Apply and persist the `contrast` theme to Terminator**
```
profiles contrast
```

- **(Linx) Securely backup your files and directories**
```
backup <filepath|dirpath> [prefix] [-nqrtz]
# example:
backup mydir -t -r
# result:
2022-10-22_19-35-54_mydir.bak
```

- **(Linx) Synchronize your setup on this device**
```
linx sync
```

### Wrap up

Linx provides many more features. But here's the real kicker: you can finally bid your terminal a proper farewell
when shutting down your system. Who said tech can't have manners?

- **(System) Lock session**
```
bye
```

- **(System) Shutdown**
```
byebye
```

## Installation instructions

#### 1. Download `install.sh` or clone this repository
```
git clone https://github.com/Julien-Fischer/linx
```

#### 2. Run the installation wizard
```
linx/install.sh
```

#### 3. Restart your terminal


## Upgrades

If you already installed this project and wish to upgrade, simply type `linx sync` and let Linx synchronize
your setup with the remote.

Note that you may need to restart your terminal for all changes to be applied.

## Dependencies

#### Required
- Bash
- Git (for executing upgrade and synchronization commands)

#### Optional (but recommended)
- Terminator
- Tree
- Neofetch
- mkf (Make File)

## Requirements

This project is designed to run on Debian-based distributions, including (but not limited to) Debian, Ubuntu,
and Kubuntu.
Primary testing has been conducted on Kubuntu 24 and Debian 12.

While the majority of functions and aliases in this project should work out-of-the box for Debian-based systems,
some features may require additional work to achieve full cross-platform compatibility.

If you encounter any issues or have suggestions for improving Linx, feel free to open an issue or
submit a pull request.
We welcome community contributions to make this project more versatile and user-friendly across different
Linux environments.

## Contributing

As Linx is a new project, we're still in the process of developing our contribution guidelines.
We expect these to evolve over time as the scope and codebase of Linx grows.

In the meantime, we welcome all contributions and feedback!
Whether you're interested in submitting code, reporting bugs, or suggesting new features, your input helps us
improve Linx.

## Acknowledgments

We would like to extend our gratitude to Eliver Lara and their contributors for their outstanding work
on Terminator themes.

While the `contrast`, `dark_gold`, `fiddle`, and `playful` themes are native to Linx, all third-party themes 
are credited to [Eliver Lara's Terminator Themes](https://github.com/EliverLara/terminator-themes)

The `native` theme is the default theme for Terminator.

## License

Linx entire source code is released under the
[MIT License](https://opensource.org/licenses/MIT).

During installation, Linx will ask you if you wish to install additional, third-party themes for Terminator.
These themes are open-source and licensed under
[GPL 3](https://www.gnu.org/licenses/gpl-3.0.fr.html#license-text).