![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/fish-shell-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/fish-shell-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/fish-shell-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/fish-shell-debian?display_date=published_at)

<h1>
   <p align="center">
     <a href="https://fishshell.com/"><img src="https://github.com/dariogriffo/fish-shell-debian/blob/main/fish-logo.png" alt="fish Logo" width="128" style="margin-right: 20px"></a>
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/fish-shell-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104" style="margin-left: 20px"></a>
     <br>fish for Debian
   </p>
</h1>
<p align="center">
 The friendly interactive shell.
</p>

# fish for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for [fish](https://github.com/fish-shell/fish-shell/) hosted at [deb.griffo.io](https://deb.griffo.io)

Currently supported Debian distros are:
- Bookworm (v12)
- Trixie (v13)
- Forky (v14)
- Sid (testing)

Supported architectures:
- amd64 (x86_64) - All distributions
- arm64 (aarch64) - All distributions

These are the only Linux targets upstream publishes binaries for. Both are
statically linked musl builds.

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the fish source code, see
[fish-shell](https://github.com/fish-shell/fish-shell/).

Each package installs:
- `/usr/bin/fish`, plus `fish_indent` and `fish_key_reader`
- the `fish.1`, `fish_indent.1`, `fish_key_reader.1` and `fish-*` man pages
- man pages for fish's builtins, under `/usr/share/fish/man`
- upstream and Debian changelogs, the copyright file and the upstream README

## No dependencies

The Debian archive splits fish into `fish` and a `fish-common` data package,
and the binary links against `libc6`, `libgcc-s1`, `libpcre2-8-0` and
`libpcre2-32-0`. This package needs none of that:

- Since fish 4.0 the functions and completions that used to live in
  `/usr/share/fish` are **embedded in the executable**, so there is no
  `fish-common` to depend on.
- The upstream binary is **statically linked against musl** with PCRE2 built
  in, so there are no shared library dependencies.
- `add-shell`/`remove-shell` come from `debianutils`, which is Essential.

`xsel`, `python3` and `man-db` are listed under `Suggests` — they enable the
clipboard integration, the browser-based `fish_config`, and `man`/`help`
respectively, and nothing breaks without them.

### A note on man pages

fish's builtins include `echo`, `test`, `kill`, `printf`, `true` and `false`.
Installing their man pages into `/usr/share/man` would clash with coreutils, so
— exactly as Debian's `fish-common` does — they go into a private
`/usr/share/fish/man` instead. A snippet in `vendor_conf.d` appends that
directory to `MANPATH`, after the system path, so `man echo` still shows the
coreutils page while `man string` finds fish's.

## Install/Update

### The Debian way

> ⚠️ **From 1 October 2026, apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/fish-shell-debian/releases) page
> and install it manually (see below).

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y fish
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/fish-shell-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo dpkg -i <filename>.deb
```

### Making fish your login shell

The package registers `/usr/bin/fish` in `/etc/shells` on install and removes
it again on uninstall, so:

```sh
chsh -s /usr/bin/fish
```

## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Building

### Build for single architecture
```sh
./build.sh <fish_version> <build_version> <architecture>
# Example: ./build.sh 4.8.1 1 arm64
```

### Build for all architectures
```sh
./build.sh <fish_version> <build_version> all
# Example: ./build.sh 4.8.1 1 all
```

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates

## Disclaimer

- This repo is not open for issues related to fish. This repo is only for _unofficial_ Debian packaging.
