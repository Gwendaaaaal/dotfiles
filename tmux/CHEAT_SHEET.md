# tmux Cheat Sheet


Current shell alias:

```zsh
alias t='tmux new -As'
```

Current tmux prefix:

```text
Ctrl-b
```

When this file says:

```text
Prefix + c
```

it means:

```text
Ctrl-b
release
c
```

---

## 1. tmux mental model

tmux is organized like this:

```text
tmux server
└── session
    ├── window 1
    │   ├── pane 1
    │   └── pane 2
    ├── window 2
    │   └── pane 1
    └── window 3
        └── pane 1
```

Think of it as:

| tmux concept | Mental model |
|---|---|
| Session | A workspace / project |
| Window | A tab |
| Pane | A terminal split |

Example:

```text
session: ft_linear_regression

1:nvim
2:tests
3:shell
4:git
```

---

# 2. Starting and reattaching to sessions

Your alias:

```zsh
alias t='tmux new -As'
```

Usage:

```bash
t linear
```

Equivalent to:

```bash
tmux new -A -s linear
```

Meaning:

```text
new     create a new session
-s      give the session a name
-A      attach to it if it already exists
```

So:

```bash
t linear
```

does both:

```text
session does not exist
        ↓
create session "linear"
```

and:

```text
session already exists
        ↓
reattach to "linear"
```

`t` should normally be followed by a session name because `-s` expects one.

---

# 3. Detach vs exit

## Detach from tmux

```text
Prefix + d
```

This leaves the tmux session running.

Programs keep running:

```text
Neovim
servers
tests
SSH sessions
shells
long-running commands
```

Later:

```bash
t linear
```

and you recover the same session.

This is one of the most important tmux concepts.

---

## Exit a pane

Inside a shell:

```bash
exit
```

or:

```text
Ctrl-d
```

If it is the last pane in a window, the window disappears.

If it is the last window in the session, the session ends.

---

# 4. Session commands

## List sessions

```bash
tmux ls
```

or:

```bash
tmux list-sessions
```

Example:

```text
linear: 3 windows
dotfiles: 1 windows
server: 2 windows
```

---

## Attach manually

```bash
tmux attach -t linear
```

Short form:

```bash
tmux a -t linear
```

Your alias usually makes this unnecessary:

```bash
t linear
```

---

## Create a named session manually

```bash
tmux new -s linear
```

---

## Rename the current session

```text
Prefix + $
```

---

## Kill one session

```bash
tmux kill-session -t linear
```

---

## Kill all tmux sessions

```bash
tmux kill-server
```

Be careful: this destroys every tmux session on that machine.

---

# 5. Windows

Windows behave like terminal tabs.

## Create a new window

```text
Prefix + c
```

Your config opens the new window in the current pane's working directory.

For example, if the current pane is in:

```text
~/Projects/ft_linear_regression
```

then:

```text
Prefix + c
```

opens the new window there too.

---

## Navigate windows

```text
Prefix + n
```

Next window.

```text
Prefix + p
```

Previous window.

Direct access:

```text
Prefix + 1
Prefix + 2
Prefix + 3
...
```

Your config starts window numbering at `1`, not `0`.

---

## Show window/session chooser

```text
Prefix + w
```

---

## Rename current window

```text
Prefix + ,
```

Example names:

```text
nvim
tests
shell
server
git
logs
```

---

## Kill current window

```text
Prefix + &
```

tmux asks for confirmation.

You can also simply exit every pane in that window.

---

## Window numbering behavior

Your config contains:

```tmux
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
```

Meaning:

- windows start at `1`;
- panes start at `1`;
- window numbering is automatically compacted when a window disappears.

Example:

```text
1:nvim
2:tests
3:shell
```

Delete window `2`:

```text
1:nvim
2:shell
```

---

# 6. Panes

Panes are terminal splits inside one window.

Your configuration intentionally replaces tmux's default split shortcuts.

## Horizontal layout: left / right

```text
Prefix + s
```

Result:

```text
┌────────────────┬────────────────┐
│                │                │
│     pane 1     │     pane 2     │
│                │                │
└────────────────┴────────────────┘
```

The command behind it is:

```tmux
bind s split-window -h -c "#{pane_current_path}"
```

---

## Vertical layout: top / bottom

```text
Prefix + v
```

Result:

```text
┌─────────────────────────────────┐
│             pane 1              │
├─────────────────────────────────┤
│             pane 2              │
└─────────────────────────────────┘
```

The command behind it is:

```tmux
bind v split-window -v -c "#{pane_current_path}"
```

---

## New panes inherit the current directory

This is especially useful for project work.

If the current pane is in:

```text
~/Projects/dslr
```

then both:

```text
Prefix + s
```

and:

```text
Prefix + v
```

create the new pane inside:

```text
~/Projects/dslr
```

---

# 7. Pane navigation

Your config uses Vim-style navigation.

```text
                   Prefix + k
                       ↑
                       │
Prefix + h   ←      current      →   Prefix + l
                       │
                       ↓
                   Prefix + j
```

So:

```text
Prefix + h    left
Prefix + j    down
Prefix + k    up
Prefix + l    right
```

This is one of the key customizations in your config.

---

# 8. Pane actions

## Close pane

```text
Prefix + x
```

tmux asks for confirmation.

Usually you can simply use:

```bash
exit
```

---

## Zoom current pane

```text
Prefix + z
```

Useful when working with Neovim or reading logs.

Press again to restore the layout.

---

## Show pane numbers

```text
Prefix + q
```

tmux overlays numbers on the panes.

Press the corresponding number to jump to one.

---

## Resize panes

Default tmux resize shortcuts can be used from command mode, but with your config the easiest option is usually the mouse.

Because you have:

```tmux
set -g mouse on
```

you can drag pane borders directly.

You can also enter tmux command mode:

```text
Prefix + :
```

Then run commands such as:

```text
resize-pane -L 5
resize-pane -R 5
resize-pane -U 5
resize-pane -D 5
```

---

# 9. Mouse support

Your config enables:

```tmux
set -g mouse on
```

This lets you:

- click panes;
- click windows in the status bar;
- resize panes by dragging borders;
- scroll through terminal history;
- interact with tmux more naturally while learning keyboard shortcuts.

---

# 10. Scrollback and copy mode

Your config stores:

```tmux
set -g history-limit 100000
```

So tmux keeps up to:

```text
100,000 lines
```

of scrollback history per pane.

---

## Enter copy mode

```text
Prefix + [
```

Your config enables Vim-style copy mode:

```tmux
setw -g mode-keys vi
```

So navigation feels similar to Vim.

Useful keys:

```text
h j k l     move
/           search forward
?           search backward
n           next search result
N           previous search result
g           top
G           bottom
q           quit copy mode
Esc         quit / cancel
```

Mouse scrolling may automatically enter copy mode depending on the terminal/tmux state.

---

# 11. Clipboard / OSC 52

Your config contains:

```tmux
set -g set-clipboard on
set -as terminal-features ',xterm-256color:clipboard'
```

This allows compatible terminal applications such as Neovim to communicate with the local clipboard through OSC 52.

This is particularly useful for:

```text
local terminal
    ↓
SSH
    ↓
tmux
    ↓
Neovim
```

when the local terminal supports OSC 52.

---

# 12. Status bar

Toggle tmux's status bar:

```text
Prefix + b
```

Your custom config:

```tmux
bind b set -g status
```

So:

```text
Ctrl-b
b
```

shows or hides the tmux status line.

---

# 13. Reload tmux configuration

After editing:

```text
~/.tmux.conf
```

reload it with:

```text
Prefix + r
```

Your config executes:

```tmux
source-file ~/.tmux.conf
```

and displays:

```text
tmux.conf reloaded
```

No need to kill or recreate your tmux sessions.

---

# 14. tmux command mode

Open tmux command mode:

```text
Prefix + :
```

Then type a tmux command.

Examples:

```text
new-window
split-window
kill-pane
kill-window
rename-window nvim
rename-session project
resize-pane -L 5
```

This is useful when you know the tmux command but not its shortcut.

---

# 15. Useful shell commands

## List sessions

```bash
tmux ls
```

---

## Show clients

```bash
tmux list-clients
```

---

## List windows

```bash
tmux list-windows
```

For one session:

```bash
tmux list-windows -t linear
```

---

## List panes

```bash
tmux list-panes
```

Show all panes across all sessions:

```bash
tmux list-panes -a
```

---

## Kill pane

```bash
tmux kill-pane
```

Specific pane:

```bash
tmux kill-pane -t linear:1.2
```

tmux targets generally follow:

```text
session:window.pane
```

Example:

```text
linear:2.1
```

means:

```text
session = linear
window  = 2
pane    = 1
```

---

## Kill window

```bash
tmux kill-window -t linear:2
```

---

## Rename session from the shell

```bash
tmux rename-session -t old-name new-name
```

---

# 16. Useful targets

tmux frequently uses this notation:

```text
session:window.pane
```

Examples:

```text
linear
linear:1
linear:1.2
```

Meaning:

```text
linear       session
linear:1     window 1
linear:1.2   pane 2 of window 1
```

Useful with commands such as:

```bash
tmux kill-pane -t linear:1.2
tmux kill-window -t linear:2
tmux send-keys -t linear:1.1 'ls' Enter
```

---

# 17. Useful commands for scripts / automation

Send text to a pane:

```bash
tmux send-keys -t linear:1.1 'pytest' Enter
```

Capture pane content:

```bash
tmux capture-pane -p -t linear:1.1
```

Create a detached session:

```bash
tmux new-session -d -s server
```

Create a detached session running a command:

```bash
tmux new-session -d -s server 'python3 server.py'
```

Create a window in an existing session:

```bash
tmux new-window -t linear -n tests
```

Split a pane from the shell:

```bash
tmux split-window -t linear:1
```

These commands are especially useful for scripts and development environments.

---

# 18. Useful default shortcuts still available

Unless overridden by your config:

| Shortcut | Action |
|---|---|
| `Prefix + d` | Detach |
| `Prefix + c` | New window |
| `Prefix + n` | Next window |
| `Prefix + p` | Previous window |
| `Prefix + 1..9` | Jump to window |
| `Prefix + ,` | Rename window |
| `Prefix + &` | Kill window |
| `Prefix + x` | Kill pane |
| `Prefix + z` | Zoom pane |
| `Prefix + q` | Show pane numbers |
| `Prefix + [` | Copy mode |
| `Prefix + ]` | Paste tmux buffer |
| `Prefix + :` | tmux command mode |
| `Prefix + ?` | Show key bindings |
| `Prefix + $` | Rename session |

Some default bindings are unavailable because your configuration replaces them.

---

# 19. Custom bindings in this config

These are the most important ones to memorize:

| Shortcut | Action |
|---|---|
| `Prefix + s` | Left/right split |
| `Prefix + v` | Top/bottom split |
| `Prefix + h` | Pane left |
| `Prefix + j` | Pane down |
| `Prefix + k` | Pane up |
| `Prefix + l` | Pane right |
| `Prefix + c` | New window in current directory |
| `Prefix + b` | Toggle status bar |
| `Prefix + r` | Reload `.tmux.conf` |

---

# 20. Default bindings intentionally removed

Your config contains:

```tmux
unbind '"'
unbind %
```

So the default tmux split bindings:

```text
Prefix + "
Prefix + %
```

do not work.

Use:

```text
Prefix + s
Prefix + v
```

instead.

---

# 21. Important config detail: comments vs actual bindings

The config comments currently say:

```text
Prefix + | -> vertical split
Prefix + - -> horizontal split
```

but the actual bindings are:

```tmux
bind s split-window -h
bind v split-window -v
```

Therefore the real shortcuts are:

```text
Prefix + s
Prefix + v
```

The comments should ideally be updated to avoid confusion.

---

# 22. Default shell

Your config contains:

```tmux
set -g default-command "exec zsh"
```

Every new tmux pane/window starts:

```text
zsh
```

even if another shell launched tmux.

---

# 23. Neovim-related setting

Your config contains:

```tmux
set -sg escape-time 10
```

This reduces tmux's escape-key delay.

It is useful with Vim/Neovim because exiting insert mode with:

```text
Esc
```

feels more immediate.

---

# 24. Recommended project workflow

Example:

```bash
cd ~/Projects/own_repos/ft_linear_regression
t linear
```

Then organize:

```text
session: linear

1:nvim
2:tests
3:shell
4:git
```

Example layout:

```text
window 1: nvim

┌───────────────────────────┬─────────────────┐
│                           │                 │
│                           │     shell       │
│          Neovim           │                 │
│                           ├─────────────────┤
│                           │     tests       │
│                           │                 │
└───────────────────────────┴─────────────────┘
```

Typical creation flow:

```text
Prefix + c       create another window
Prefix + ,       rename it

Prefix + s       split left/right
Prefix + v       split top/bottom

Prefix + h/j/k/l
                 move between panes
```

When finished working:

```text
Prefix + d
```

Next day:

```bash
t linear
```

Everything is still there.

---

# 25. SSH workflow

tmux is especially useful on remote servers.

Example:

```bash
ssh server
t minecraft
```

Start something:

```bash
./start.sh
```

Then detach:

```text
Prefix + d
```

You can safely close SSH.

Later:

```bash
ssh server
t minecraft
```

and recover the terminal.

This is ideal for:

```text
Minecraft servers
development servers
builds
logs
bots
agents
long scripts
```

---

# 26. When to use windows vs panes

Use a **pane** when two terminals belong together visually.

Example:

```text
Neovim | tests
```

Use a **window** when it is another task/context.

Example:

```text
1:nvim
2:server
3:git
4:logs
```

A good rule:

```text
same task/context     → pane
different task        → window
different project     → session
```

---

# 27. Quick reference

```text
SESSION
────────────────────────────────
t NAME          create / reattach
tmux ls         list sessions
Prefix + d      detach
Prefix + $      rename session

WINDOWS
────────────────────────────────
Prefix + c      new window
Prefix + n      next window
Prefix + p      previous window
Prefix + 1..9   jump to window
Prefix + ,      rename window
Prefix + &      kill window
Prefix + w      window chooser

PANES
────────────────────────────────
Prefix + s      split left/right
Prefix + v      split top/bottom

Prefix + h      left
Prefix + j      down
Prefix + k      up
Prefix + l      right

Prefix + z      zoom pane
Prefix + x      kill pane
Prefix + q      show pane numbers

COPY / HISTORY
────────────────────────────────
Prefix + [      copy mode
/               search
n / N           next / previous result
q               leave copy mode

CONFIG
────────────────────────────────
Prefix + b      toggle status bar
Prefix + r      reload config
Prefix + :      tmux command mode
Prefix + ?      show key bindings
```

---

# 28. The 10 shortcuts to memorize first

```text
t NAME
Prefix + d

Prefix + c

Prefix + s
Prefix + v

Prefix + h
Prefix + j
Prefix + k
Prefix + l

Prefix + z
```

With only those, you can already use tmux comfortably for most development workflows.

---

# 29. Current relevant `.tmux.conf`

For reference, the important behavior in the current configuration is:

```tmux
set -g default-command "exec zsh"

set -g mouse on
set -g history-limit 100000
set -sg escape-time 10

set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

setw -g mode-keys vi

set -g set-clipboard on
set -as terminal-features ',xterm-256color:clipboard'

unbind '"'
unbind %

bind s split-window -h -c "#{pane_current_path}"
bind v split-window -v -c "#{pane_current_path}"

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

bind c new-window -c "#{pane_current_path}"

bind b set -g status

bind r source-file ~/.tmux.conf \; display-message "tmux.conf reloaded"
```

And the shell alias is:

```zsh
alias t='tmux new -As'
```
