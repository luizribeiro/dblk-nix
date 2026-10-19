# dblk-nix

Nix packaging for [dblk](https://cache.dblk.dev), a distributed build cache
for Rust. This flake provides:

- `packages.<system>.dblk`: the upstream release binaries, pinned by hash
- `darwinModules.default`: a nix-darwin module
- `nixosModules.default`: a NixOS module

Supported systems are `aarch64-darwin` and `x86_64-linux`, the platforms
upstream publishes stable releases for.

## Usage

Add the input:

```nix
inputs.dblk = {
  url = "github:luizribeiro/dblk-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Import the module for your platform and enable it:

```nix
# nix-darwin
modules = [ inputs.dblk.darwinModules.default ];

# NixOS
modules = [ inputs.dblk.nixosModules.default ];

# either
services.dblk.enable = true;
```

After switching, open a new shell and check the daemon:

```console
$ dblkc stat
```

To try the binaries without installing anything:

```console
$ nix shell github:luizribeiro/dblk-nix
```

## What the module does

- **Runs one daemon per user.** On macOS, a launchd user agent starts
  `dblkc cached` for each user who logs in. On NixOS, a systemd user service
  does the same for every non-system user. Each daemon keeps its own cache in
  that user's `~/.cache/dblk`, and its socket is readable only by that user.
- **Points cargo at the cache.** It sets `CARGO_BUILD_RUSTC_WRAPPER`
  system-wide, so every shell picks it up, including `nix develop` and direnv
  shells. Projects need no changes.
- **Leaves out upstream's auto-update agent.** The version is pinned here
  instead.

If no daemon is running, the wrapper passes straight through to `rustc`, so
builds keep working. `nix build` is unaffected, because the sandbox drops the
variable.

macOS logs go to `~/Library/Logs/dblk-cached.log`. On NixOS, use
`journalctl --user -u dblk-cached`.

## Options

| Option | Default | Description |
|---|---|---|
| `services.dblk.enable` | `false` | Run the daemon and set the cargo wrapper |
| `services.dblk.package` | this flake's package | The dblk package to use |
| `services.dblk.environment` | `{ }` | `DBLK_*` settings for the daemon, e.g. `{ DBLK_STORE_MAX_BYTES = "50G"; }` |

See `dblkc cached --help` for all `DBLK_*` settings: store size, peers,
relays and so on.

## `dblk-rustc-wrapper`

When `RUSTC` is unset, which is the norm in Nix dev shells, cargo calls the
wrapper with a bare `rustc`. `dblk-rustc` 0.1.0 can only build a cache key from
a full compiler path, so every crate fails with `key-unavailable`. The package
adds `dblk-rustc-wrapper`, which looks up a bare `rustc` on `PATH` and then runs
the upstream `dblk-rustc`. The module uses it. Once upstream fixes this, the
wrapper can go away.

## Caveats

- **Incremental builds aren't cached.** dblk skips incremental compilation
  units. Dependencies are always built non-incrementally, so they get cached
  even in debug builds, but workspace crates only get cached in release builds
  or with `CARGO_INCREMENTAL=0`.
- **Toolchains don't share entries.** The cache key includes the compiler, so
  different Rust versions never share entries, and two builds of the same
  version (say nixpkgs vs rust-overlay) likely don't either. Machines using
  the same `flake.lock` get the same toolchain, so they can share.
- **The mesh is opt-in.** Joining with `dblkc login` stays manual. It writes an
  identity under `~/.config/dblk`, which the daemon picks up on its own.

## Updating to a new release

A bump only touches `package.nix`. For each system, read the latest stamp,
then hash both binaries:

```console
$ target=aarch64-apple-darwin   # or x86_64-unknown-linux-gnu
$ base=https://cache.dblk.dev/api/releases/stable/$target
$ stamp=$(curl -sSf $base/latest)
$ for bin in dblkc dblk-rustc; do nix store prefetch-file --json "$base/$stamp/$bin" | jq -r .hash; done
```

Then update `version`, `buildId`, and each system's `stamp` and `hashes` in
`package.nix`. The build's install check fails if the binaries don't report
the expected version.
