{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "electron-node-python-dev";

  nativeBuildInputs = [
    # Python
    pkgs.python3
    pkgs.python3Packages.pip

    # Node & package managers
    pkgs.nodejs_24
    pkgs.nodePackages.npm
    pkgs.yarn

    # Electron native libs (Linux)
    pkgs.nss
    pkgs.nspr
    pkgs.atk
    pkgs.cups
    pkgs.libdrm
    pkgs.mesa
    pkgs.gtk3
    pkgs.alsa-lib
  ];

  shellHook = ''
    export NODE_ENV=development

    echo "Electron / Node / Python Development Environment"
    echo ""
    echo "  Python: $(python3 --version)"
    echo "  Node:   $(node --version)"
    echo "  npm:    $(npm --version)"
    echo "  yarn:   $(yarn --version)"
    echo ""
  '';
}
