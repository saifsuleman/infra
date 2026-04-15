# nixos-config — Architecture & Specification

## Overview

This repository manages the NixOS, nix-darwin, and home-manager configurations
for all of Saif's personal machines using the **Dendritic Pattern** with
**flake-parts** and **import-tree**. The goal is a single source of truth for
every machine — desktop, laptop, and server — where adding a new host, user, or
program never requires touching unrelated files.

---

## The Dendritic Pattern

The Dendritic Pattern is a design approach for Nix configurations where **every
`.nix` file is a flake-parts module**. There are no NixOS modules, home-manager
modules, or packages at the file level — every file contributes to a single
top-level flake-parts evaluation, and declares lower-level configurations
(NixOS, home-manager, nix-darwin) as option values within that evaluation.

### Why this matters

In a conventional Nix config, files have different types — some are NixOS
modules, some are home-manager modules, some are packages. You need to know
what a file *is* before you can import it, and imports are managed manually
across multiple `default.nix` files.

In the Dendritic Pattern:

- Every file is the same type (a flake-parts module)
- Files are loaded automatically via `import-tree` — no manual imports
- A single file can declare both NixOS and home-manager config for the same
  feature, keeping related concerns together
- Adding a new file is enough to include it — `flake.nix` never needs to change

### The core mechanic

Each file declares config on `flake.modules.nixos.*` or
`flake.modules.homeManager.*`. These are typed attrsets that flake-parts knows
how to evaluate in the correct context. Hosts and users compose by importing
those values.

```nix
# modules/core/ssh.nix — one file, two concerns
{ flake, ... }:
{
  flake.modules.nixos.core-ssh = {
    services.openssh.enable = true;
    services.openssh.settings.PasswordAuthentication = false;
  };

  flake.modules.homeManager.core-ssh = {
    programs.ssh.enable = true;
  };
}
```

### flake.nix

The entire `flake.nix` is just:

```nix
outputs = inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; }
    (inputs.import-tree ./modules);
```

`import-tree` recursively loads every `.nix` file under `modules/` as a
flake-parts module. Directories prefixed with `_` are ignored — used for
`_lib/`.

---

## Module Naming Convention

Module names mirror the file path, with path separators replaced by `-` and the
`modules/` prefix dropped. When a file declares config for multiple classes
(nixos, homeManager), the class is the attrset key, not part of the name.

```
modules/core/ssh.nix                        → flake.modules.nixos.core-ssh
                                              flake.modules.homeManager.core-ssh

modules/desktop/hyprland/system.nix         → flake.modules.nixos.desktop-hyprland-system
modules/desktop/hyprland/base.nix           → flake.modules.homeManager.desktop-hyprland-base

modules/services/k3s.nix                    → flake.modules.nixos.services-k3s

modules/users/saif/default.nix              → flake.modules.nixos.users-saif
                                              flake.modules.homeManager.users-saif
                                              flake.modules.homeManager.users-saif-darwin
                                              flake.modules.homeManager.users-saif-server

modules/users/saif/core/shell.nix           → flake.modules.homeManager.users-saif-core-shell
modules/users/saif/desktop/hyprland.nix     → flake.modules.homeManager.users-saif-desktop-hyprland
```

This means you can look at any module name and immediately know which file
defines it, and vice versa.

---

## nixos vs homeManager

The two classes map directly to privilege level:

| Class | When to use | Examples |
|---|---|---|
| `nixos` | Needs root, affects the whole system | `services.*`, `programs.<x>.enable`, `users.users.*`, `networking.*`, `fonts.packages` |
| `homeManager` | Only affects a user's home directory | `programs.<x>` config, `home.packages`, `wayland.windowManager.*`, `services.dunst`, dotfiles |

The classic gotcha is programs that need both. `zsh` is the canonical example —
NixOS must know about it so it appears in `/etc/shells` (login shell
requirement), and home-manager configures what's actually in `~/.zshrc`:

```nix
# nixos side
programs.zsh.enable = true;   # makes zsh a valid login shell system-wide

# homeManager side
programs.zsh = {
  enable = true;
  shellAliases = { ... };     # writes ~/.zshrc
};
```

---

## Ownership Model

A core principle of this config is that **ownership is explicit and
non-overlapping**. Each concern belongs to exactly one layer.

| Concern | Owner | Location |
|---|---|---|
| Which WM is installed | Host | `modules/hosts/<host>.nix` |
| WM system config (portals, polkit, greeter) | Host | `modules/desktop/<wm>/system.nix` |
| WM sane defaults (gaps, animations, base keybinds) | Shared | `modules/desktop/<wm>/base.nix` |
| WM rice (colours, keybinds, bar, terminal) | User | `modules/users/<n>/desktop/<wm>.nix` |
| System services | Host | `modules/services/*.nix` |
| CLI tools, shell config | User | `modules/users/<n>/core/*.nix` |
| User account declaration | User | `modules/users/<n>/default.nix` (nixos side) |
| Home-manager profile composition | User | `modules/users/<n>/default.nix` (homeManager side) |

### Why the host decides the WM

A window manager is a property of the machine, not the person. The host knows
its hardware, GPU drivers, display server, and whether a display exists at all.
A user running Hyprland on a headless server makes no sense — the host prevents
it by simply not importing `desktop-hyprland-system`.

When multiple users share a host and prefer different WMs, the host enables all
of them. Both `desktop-hyprland-system` and `desktop-i3-system` can coexist —
the display manager (greetd/SDDM) will offer both as sessions. Each user then
configures only the WM they use.

---

## File Structure

```
nixos-config/
├── flake.nix                        # import-tree ./modules — never changes
├── README.md
├── .gitignore
│
├── docs/
│   └── architecture.md
│
├── scripts/
│   ├── update.sh                    # sudo nixos-rebuild switch --flake .#$(hostname)
│   ├── hm-switch.sh                 # home-manager switch --flake .#<user>
│   └── fmt.sh                       # nixfmt all .nix files
│
└── modules/
    │
    ├── _lib/                        # ignored by import-tree
    │   └── default.nix              # mkHost / mkUser convenience helpers
    │
    ├── hosts/                       # one file per machine
    │   ├── pc.nix                   # NixOS · x86_64 · Hyprland · saif
    │   ├── macbook.nix              # nix-darwin · aarch64 · no WM · saif
    │   ├── server.nix               # NixOS · x86_64 · headless · saif
    │   └── hardware/
    │       ├── pc.nix               # nixos-generate-config output
    │       └── server.nix           # nixos-generate-config output
    │
    ├── core/                        # imported by every host
    │   ├── nix-settings.nix         # experimental-features, gc, store optimisation
    │   ├── locale.nix               # timezone (Europe/London), keyboard (gb), locale
    │   ├── ssh.nix                  # nixos: openssh server · hm: ssh client config
    │   └── home-manager.nix         # home-manager input, useGlobalPkgs, backupFileExtension
    │
    ├── desktop/                     # imported by hosts with a display only
    │   ├── fonts.nix                # nerd fonts, noto
    │   ├── pipewire.nix             # audio, rtkit
    │   ├── hyprland/
    │   │   ├── system.nix           # nixos: programs.hyprland, portals, polkit, greetd, uwsm
    │   │   └── base.nix             # hm: shared defaults — gaps, animations, input, base keybinds
    │   └── i3/
    │       ├── system.nix           # nixos: xserver, i3 enable
    │       └── base.nix             # hm: shared defaults — modifier, gaps
    │
    ├── services/                    # imported by server host only
    │   ├── k3s.nix                  # k3s server, ip forwarding
    │   ├── nginx.nix                # nginx, ports 80/443
    │   └── tailscale.nix            # tailscale, firewall
    │
    ├── devShells/                   # nix develop .#rust / .#go
    │   ├── rust.nix                 # rustc, cargo, rust-analyzer
    │   └── go.nix                   # go, gopls, delve
    │
    └── users/
        └── saif/
            ├── default.nix          # nixos: user account
            │                        # hm: three profiles — users-saif (pc),
            │                        #     users-saif-darwin (macbook),
            │                        #     users-saif-server (headless)
            ├── core/
            │   ├── shell.nix        # zsh, starship, zoxide, fzf, bat, eza, ripgrep
            │   └── git.nix          # git, delta, gh cli
            └── desktop/
                └── hyprland.nix     # saif's rice: monitor layout, keybinds,
                                     # waybar, kitty, rofi, dunst, hyprpaper
```

---

## Hosts

### pc

Desktop workstation. NixOS on x86_64. Primary machine.

- Imports `core-nix-settings`, `core-locale`, `core-ssh`, `core-home-manager`
- Imports `desktop-fonts`, `desktop-pipewire`, `desktop-hyprland-system`
- Users: `saif` → profile `users-saif` (full desktop)

### macbook

MacBook laptop. nix-darwin on aarch64. No window manager — macOS handles that.

- Imports `core-nix-settings`, `core-ssh`, `core-home-manager`
- Users: `saif` → profile `users-saif-darwin` (CLI only)

### server

Home server. NixOS on x86_64. Headless — no display, no desktop packages.

- Imports `core-nix-settings`, `core-locale`, `core-ssh`, `core-home-manager`
- Imports `services-k3s`, `services-nginx`, `services-tailscale`
- Users: `saif` → profile `users-saif-server` (minimal, CLI only)

---

## Users

### Profile system

Each user declares a `flake.modules.nixos.users-<n>` for their system account
and one or more `flake.modules.homeManager.users-<n>[-variant]` profiles for
their home-manager config. Different profiles are used for different hosts —
the desktop profile includes the WM rice, the darwin and server profiles do not.

### saif

```
users-saif          desktop profile — imports hyprland-base + all core modules
users-saif-darwin   macbook profile — imports core modules only
users-saif-server   server profile  — imports core modules only
```

All three profiles share `users-saif-core-shell` and `users-saif-core-git`,
meaning any package added to `shell.nix` is available on all three machines
after running `hm-switch.sh` on each.

### Adding a new user

1. Create `modules/users/<name>/default.nix` — declare the nixos account and
   compose home-manager profiles
2. Add `modules/users/<name>/core/` for shell, git, and other CLI config
3. Add `modules/users/<name>/desktop/<wm>.nix` for per-WM rice if needed
4. Import `flake.modules.nixos.users-<name>` in the relevant host file(s)
5. Wire up `home-manager.users.<name>` in the host's inline config block

Nothing outside the user's own directory needs to change.

---

## Desktop / WM Architecture

### System vs base vs rice

Hyprland config is split across three layers:

**`desktop/hyprland/system.nix`** — NixOS side only. Enables the compositor,
sets up portals, polkit, the display manager (greetd + uwsm). This is what
makes Hyprland available on the machine at all. Only hosts import this.

**`desktop/hyprland/base.nix`** — home-manager side. Shared defaults that every
Hyprland user gets: gaps, border size, blur, animations, input settings,
touchpad config, media keys, window management keybinds (hjkl focus/move,
workspace switching). These are universal and have no user preference baked in.
Users import this explicitly in their `default.nix` profile.

**`users/<n>/desktop/hyprland.nix`** — home-manager side. The user's personal
rice: monitor layout, colour scheme, app launcher keybinds (`$mod, Return →
kitty`), waybar config and CSS, kitty colours, rofi, dunst, hyprpaper, window
rules. This file knows nothing about the system — it only sets user preferences.

### Keybind ownership

Base keybinds are universal window management actions that every user needs and
that have no app preference baked in: `killactive`, `fullscreen`,
`togglefloating`, hjkl focus/move, workspace numbers, media/brightness keys.

User keybinds are anything that launches a specific application: terminal,
browser, launcher, screenshot tool. These live in the user rice file only.

Because `bind` is a list and NixOS module system merges lists by concatenation,
user binds append to base binds cleanly. Users cannot remove a base bind — if
that is needed, `lib.mkForce` on the whole `bind` list replaces it entirely.

### Multi-user, multi-WM hosts

A host can enable multiple WMs simultaneously. Each is a separate system module
(`desktop-hyprland-system`, `desktop-i3-system`) and they do not conflict.
The display manager presents both as available sessions. Each user configures
only the WM they use — a user with no `desktop/i3.nix` simply never uses i3,
but its presence on the system costs nothing meaningful.

---

## Package Cross-machine Sharing

Packages declared in `users/<n>/core/shell.nix` under `home.packages` are
available on every machine that uses a profile importing `users-<n>-core-shell`.
For saif this means all three machines — pc, macbook, and server.

Platform-specific packages are gated with `lib.optionals`:

```nix
home.packages = with pkgs; [
  ripgrep fd bat eza          # cross-platform, always included

] ++ lib.optionals pkgs.stdenv.isLinux [
  wl-clipboard                # Linux / Wayland only

] ++ lib.optionals pkgs.stdenv.isDarwin [
  mas                         # Mac App Store CLI, Darwin only
];
```

This is the only place platform checks appear. Everything else is unconditional.

---

## Inputs

| Input | Pin | Purpose |
|---|---|---|
| `nixpkgs` | `nixos-unstable` | Primary package set |
| `flake-parts` | `main` | Flake composition framework |
| `home-manager` | `master` | User environment management |
| `nix-darwin` | `master` | macOS system management |
| `import-tree` | `main` | Auto-imports all modules |
| `hyprland` | `main` | Hyprland compositor (follows nixpkgs-unstable) |

All inputs follow `nixpkgs` to prevent multiple versions of nixpkgs in the
closure.

---

## Common Operations

### Rebuild current host

```bash
./scripts/update.sh
# expands to: sudo nixos-rebuild switch --flake .#$(hostname)
```

### Switch home-manager

```bash
./scripts/hm-switch.sh saif
# expands to: home-manager switch --flake .#saif
```

### Enter a dev shell

```bash
nix develop .#rust
nix develop .#go
```

### Add a new package (available on all machines)

Edit `modules/users/saif/core/shell.nix`, add to `home.packages`. Commit, pull
on each machine, run `hm-switch.sh`.

### Add a new host

1. Create `modules/hosts/<hostname>.nix`
2. Create `modules/hosts/hardware/<hostname>.nix` (from `nixos-generate-config`)
3. Compose the desired modules and user profiles in the host file
4. Run `sudo nixos-rebuild switch --flake .#<hostname>` on the machine

### Add a new service to the server

1. Create `modules/services/<service>.nix`
2. Declare `flake.modules.nixos.services-<service>` with the NixOS config
3. Import it in `modules/hosts/server.nix`

---

## Conventions

- A single file may declare both nixos and homeManager modules when they are two
  sides of the same feature (e.g. `core/ssh.nix`)
- Virtual hosts, server-specific secrets, and per-service port assignments are
  declared in `modules/hosts/server.nix` directly rather than in the service
  module, keeping service modules generic and reusable
- `system.stateVersion` and `home.stateVersion` are set to `"24.11"` and should
  not be changed after initial install on each machine
