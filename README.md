# Linx (Link for Linux)

Linx provides an opinionated set of commands and configurations designed for power users who prioritize speed
and efficiency over graphical user interfaces.
Among other things, linx aims to make navigation easier, automate grunt tasks such as managing git repositories,
backups, files and directories, docker processes, text anonymization, and much more.

It also enhances Terminator with additional features, integrates AI tools like GPT-4 for in-terminal prompts, and
provides commands to configure and sync your local Linx setup with a remote environment.

## Features

Version `1.0.0-alpha` of Linx offers the following features:

- A comprehensive set of functions and aliases that minimize the time and effort required for directory navigation, file management, and common task execution
- Shortcuts for frequently accessed directories such as home, desktop, and dev, allowing users to quickly jump to desired locations
- Functions that streamline version control tasks and enhance log viewing capabilities
- For Terminator users, Linx offers preconfigured shortcuts, themes, and layouts (no python required)
- GPT 4 integration so you can prompt it directly from your terminal

![Live Demo](./demo.gif)


## Examples

### Vanilla Bash VS Linx

| Scope         | Task                                              | :rocket: Using Linx | :sleepy: Without Linx                                                                                                                                                   |
|:--------------|:--------------------------------------------------|:--------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Navigation    | Go to Desktop                                     | desk                | cd $(xdg-user-dir DESKTOP) && pwd && ls -AF --group-directories-first --color                                                                                           |
| Navigation    | Go to root directory                              | ,                   | cd / && pwd && ls -AF --group-directories-first --color                                                                                                                 |
| Navigation    | Go to home directory                              | ~                   | cd ~ && pwd && ls -AF --group-directories-first --color                                                                                                                 |
| Navigation    | Toggle the current and previous directories       | -                   | cd - && pwd && ls -AF --group-directories-first --color                                                                                                                 |
| Navigation    | Cycle through your navigation history             | --                  | N/A                                                                                                                                                                     |
| Navigation    | Go one directory up                               | ..                  | cd ..                                                                                                                                                                   |
| Navigation    | Go two directories up                             | ...                 | cd ../..                                                                                                                                                                |
| Navigation    | Go six directories up                             | up 6                | cd ../../../../../../                                                                                                                                                   |
| Visualization | Inspect current dir, sorted by alphabetical order | ll                  | ls -lhAF                                                                                                                                                                |
| Visualization | Inspect current dir, sorted by modification date  | lt                  | ls -lhAFt -1                                                                                                                                                            |
| Visualization | Inspect current dir, grouping directories first   | ld                  | ls -lhAF --group-directories-first                                                                                                                                      |
| Visualization | Inspect current dir, in short format              | la                  | ls -AF --group-directories-first                                                                                                                                        |
| Git           | Commit & push                                     | gap "msg"           | git add . && git commit -m "msg" && git push                                                                                                                            |
| Git           | Force push all changes                            | gapf "msg"          | git add . && git commit -m "msg" && git push --force origin                                                                                                             |
| Git           | View releases                                     | glor                | git log --no-walk --tags --pretty=format:"%h %ad %d% %an% %s" --date=format:"%Y-%m-%d %H:%M" --abbrev-commit                                                            |
| Git           | Pretty print git log in ascending order           | glot asc            | git log --reverse --pretty=format:"%C(yellow)%h%C(reset) %C(red)%ad%C(reset) %C(cyan)%an%C(reset) %s" --date=format:"%Y-%m-%d %H:%M" --abbrev-commit                    |
| Git           | Print today's commits                             | glot -t             | git log --reverse --pretty=format:"%C(yellow)%h%C(reset) %C(red)%ad%C(reset) %C(cyan)%an%C(reset) %s" --date=format:"%Y-%m-%d %H:%M" --abbrev-commit --since "00:00:00" |
| Git           | List all contributors with their stats            | gcount -a           | N/A                                                                                                                                                                     |


### Linx-specific features

- **(AI) Prompt an AI provider from your terminal**

Quick one-line prompt:
```
ask "Generate a funny Java-related ASCII art"
```
Multiline prompt:
```
john@Doe:~/foss$ ask
Please enter your input (type 'END' to finish):
Describe the following ASCII art:
   ( (
    ) )
  ........
  |      |]
  |      |
  `------'
END
Thinking...
The ASCII art depicts a simple representation of a cup or mug.
```

- **(Terminator) List themes and profiles**
```
term p
```

- **(Terminator) Apply and persist the `contrast` theme to Terminator**
```
term p --set contrast
```

- **(Linx) Securely backup your files and directories**
```
backup mydir -t -r   # Produces: 2022-10-22_19-35-54_mydir.bak
```

- **(Linx) Synchronize your setup on this device**
```
linx sync
```

- **(Linx) Configure linx locally**
```
linx config
```

- **(System) Execute your last command with sudo**
```
pls
```

## Installation instructions

Install linx using **curl**:

```bash
curl -o install.sh https://raw.githubusercontent.com/Julien-Fischer/linx/main/install.sh && chmod +x install.sh && ./install.sh && rm install.sh
```

Or **git**:

```bash
git clone https://github.com/Julien-Fischer/linx && linx/install.sh
```

Note: You may need to restart your terminal for some changes to be applied, especially for Terminator 
configurations.

## Upgrades

If you already installed this project and wish to upgrade, simply type `linx sync` and let Linx synchronize
your setup with the remote.

Note that you may need to restart your terminal for all changes to be applied.

## Dependencies

#### Required
- Bash (or zsh)
- Git (for executing upgrade and synchronization commands)

#### Optional (but recommended)
- Terminator
- Tree
- curl (for browsing the web from the terminal)
- jq (for JSON parsing)
- Neofetch
- simplescreenrecorder
- rsync
- Node.js (when / if using the `ask` command)

## Requirements

This project is designed to run on Debian-based distributions, including (but not limited to) Debian, Ubuntu,
and Kubuntu.
Primary testing has been conducted on Kubuntu 24 and Debian 12.

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

Please refer to the draft of [Contributing to linx](https://github.com/Julien-Fischer/linx/blob/master/CONTRIBUTING.md) for
more details.

## Acknowledgments

We would like to extend our gratitude to Eliver Lara and their contributors for their outstanding work
on Terminator themes.

While the `contrast`, `dark_gold`, `fiddle`, and `playful` themes are native to Linx, all third-party themes
are credited to [Eliver Lara's Terminator Themes](https://github.com/EliverLara/terminator-themes)

The `native` theme is the default theme for Terminator.

## License

Linx is released under the [MIT License](https://opensource.org/licenses/MIT).

During installation, Linx will ask if you wish to install additional, third-party themes for Terminator.
These themes are open-source and licensed under
[GPL 3](https://www.gnu.org/licenses/gpl-3.0.fr.html#license-text).
