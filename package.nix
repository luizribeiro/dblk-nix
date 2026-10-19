{ lib, stdenvNoCC, fetchurl, runtimeShell }:

let
  version = "0.1.0";
  buildId = "f9909ea";

  releases = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      stamp = "20261019T040041Z-${buildId}";
      hashes = {
        dblkc = "sha256-m7mZx1BZiuw3SNWqeROs89s3Dd3lKWjBcI/i0MJlEQQ=";
        dblk-rustc = "sha256-YWRGBgQXTMJekXfQ781J6OTDFh9e0Yv9u3RB4DaPyGw=";
      };
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      stamp = "20261019T035959Z-${buildId}";
      hashes = {
        dblkc = "sha256-J+ot3pVhEdFNeHX/+OhmI0Rm+UvNKZtvCgXA41m2JsQ=";
        dblk-rustc = "sha256-hs5603i5sm8Jtct9HfvQ7WA7st4F5VWaMv8weVXUGaA=";
      };
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;
  release = releases.${system} or (throw "dblk: no release for ${system}");

  fetchBin = name: fetchurl {
    url = "https://cache.dblk.dev/api/releases/stable/${release.target}/${release.stamp}/${name}";
    hash = release.hashes.${name};
  };

  installRustcWrapper = dest: dblkRustc: ''
    substitute ${./rustc-wrapper.sh} ${dest} \
      --subst-var-by shell ${runtimeShell} \
      --subst-var-by dblkRustc ${dblkRustc}
    chmod 755 ${dest}
  '';
in
stdenvNoCC.mkDerivation {
  pname = "dblk";
  inherit version;

  dontUnpack = true;

  installPhase = ''
    install -Dm755 ${fetchBin "dblkc"} $out/bin/dblkc
    install -Dm755 ${fetchBin "dblk-rustc"} $out/bin/dblk-rustc
    ${installRustcWrapper "$out/bin/dblk-rustc-wrapper" "$out/bin/dblk-rustc"}
  '';

  # Same check install.sh makes: both binaries are the build the release names.
  doInstallCheck = true;
  installCheckPhase = ''
    for bin in dblkc dblk-rustc; do
      [ "$($out/bin/$bin --version)" = "$bin ${version}+${buildId}" ]
    done

    ${installRustcWrapper "echo-wrapper" "echo"}
    mkdir toolchain
    touch toolchain/rustc
    chmod +x toolchain/rustc

    wraps() {
      expected=$1
      shift
      [ "$(PATH=$PWD/toolchain:$PATH ./echo-wrapper "$@")" = "$expected" ]
    }
    wraps "$PWD/toolchain/rustc --crate-name foo" rustc --crate-name foo
    wraps "/opt/rust/bin/rustc --crate-name foo" /opt/rust/bin/rustc --crate-name foo
    wraps "missing-rustc --crate-name foo" missing-rustc --crate-name foo
    wraps ""
  '';

  meta = {
    description = "Distributed Rust build cache";
    homepage = "https://cache.dblk.dev";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames releases;
    mainProgram = "dblkc";
  };
}
