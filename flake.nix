{
  description = "ihaveacreditcard - 3DS SD install toolkit (Linux PC). TUI wrapper + dev shell (runtime deps like custominstall/save3ds_fuse/decryptor-tui/boot9/movable handled per README/install.sh).";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
    in {
      packages = forAll (pkgs: {
        default = pkgs.writeShellApplication {
          name = "ihaveacreditcard";
          runtimeInputs = [ pkgs.python3 pkgs.git pkgs.curl pkgs.coreutils pkgs.findutils ];
          text = ''
            # runs from the flake source so repo-relative scripts/assets resolve
            exec python3 "${self}/scripts/tui.py" "$@"
          '';
        };
        tui = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      });

      apps = forAll (pkgs: {
        default = { type = "app"; program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ihaveacreditcard"; };
        tui = self.apps.${pkgs.stdenv.hostPlatform.system}.default;
      });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ python3 python3Packages.pip git curl cargo rustc pkg-config fuse3 gnumake gcc ];
          shellHook = ''
            echo "ihaveacreditcard dev shell (source: ${self})"
            echo "Run: python3 ${self}/scripts/tui.py  (or ./install.sh from a checkout for full bootstrap)"
            echo "Runtime deps still needed per README: custominstall venv, save3ds_fuse, decryptor-tui/makerom/ctrtool, boot9.bin/movable.sed."
          '';
        };
      });
    };
}
