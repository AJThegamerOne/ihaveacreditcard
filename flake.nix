{
  description = "ihaveacreditcard - Linux-side 3DS SD install toolkit (TUI, doctor, helpers)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));

      # Every app runs from the flake source so repo-relative scripts and assets resolve
      # regardless of the caller's current directory.
      mkPyApp =
        {
          pkgs,
          name,
          script,
          description,
        }:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = with pkgs; [
            python3
            coreutils
            findutils
            gnused
          ];
          text = ''
            exec python3 "${self}/scripts/${script}" "$@"
          '';
          meta = {
            inherit description;
            mainProgram = name;
          };
        };
    in
    {
      packages = forAll (pkgs: rec {
        default = tui;
        tui = mkPyApp {
          inherit pkgs;
          name = "ihaveacreditcard";
          script = "tui.py";
          description = "Guided 3DS SD install TUI";
        };
        doctor = mkPyApp {
          inherit pkgs;
          name = "ihaveacreditcard-doctor";
          script = "doctor.py";
          description = "Non-interactive setup check";
        };
        make-cifinish = mkPyApp {
          inherit pkgs;
          name = "make-cifinish";
          script = "make_cifinish.py";
          description = "Write a fresh cifinish.bin for one or more title IDs";
        };
        inspect-title-db = mkPyApp {
          inherit pkgs;
          name = "inspect-title-db";
          script = "inspect_title_db.py";
          description = "Decode save3ds title.db entries";
        };
        all = pkgs.buildEnv {
          name = "ihaveacreditcard-all";
          paths = [
            tui
            doctor
            make-cifinish
            inspect-title-db
          ];
          meta.description = "All ihaveacreditcard command-line helpers";
        };
      });

      apps = forAll (pkgs: rec {
        default = tui;
        tui = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.tui}/bin/ihaveacreditcard";
          meta.description = "Guided 3DS SD install TUI";
        };
        doctor = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.doctor}/bin/ihaveacreditcard-doctor";
          meta.description = "Non-interactive setup check";
        };
        make-cifinish = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.make-cifinish}/bin/make-cifinish";
          meta.description = "Write a fresh cifinish.bin for one or more title IDs";
        };
        inspect-title-db = {
          type = "app";
          program = "${
            self.packages.${pkgs.stdenv.hostPlatform.system}.inspect-title-db
          }/bin/inspect-title-db";
          meta.description = "Decode save3ds title.db entries";
        };
      });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            python3
            python3Packages.pip
            git
            curl
            cargo
            rustc
            rustfmt
            clippy
            pkg-config
            fuse3
            gnumake
            gcc
          ];
          shellHook = ''
            echo "ihaveacreditcard dev shell"
            echo "source: ${self}"
            echo
            echo "  python3 ${self}/scripts/tui.py           # guided TUI"
            echo "  python3 ${self}/scripts/tui.py --check   # setup check"
            echo "  ./install.sh                            # full Linux bootstrap"
            echo
            echo "Runtime tools still needed per README: custominstall, save3ds_fuse,"
            echo "decryptor-tui, makerom/ctrtool and your own boot9.bin/movable.sed."
          '';
        };
      });

      formatter = forAll (pkgs: pkgs.nixfmt);
    };
}
