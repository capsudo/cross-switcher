{
  description = "Cross Switcher GNOME Shell extension development shell";

  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              dbus
              glib
              glib.dev
              gnome-shell
              gnumake
              unzip
              zip
            ];
          };
        });
    };
}
