#!@shell@
# Cargo hands RUSTC_WRAPPER a bare `rustc` when RUSTC is unset, which is the
# norm in nix devShells. dblk-rustc 0.1.0 can only key a compiler given by
# path (every such unit fails with key-unavailable), so resolve it on PATH.

if [ $# -gt 0 ]; then
  case $1 in
    */*) ;;
    *)
      if resolved=$(command -v -- "$1"); then
        shift
        set -- "$resolved" "$@"
      fi
      ;;
  esac
fi

exec @dblkRustc@ "$@"
