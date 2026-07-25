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
          gsettingsDesktopSchemaDirectory =
            "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}/glib-2.0/schemas";
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              dbus
              glib
              glib.dev
              gsettings-desktop-schemas
              gnome-shell
              gnumake
              unzip
              zip
            ];

            shellHook = ''
              export GSETTINGS_SCHEMA_DIR="${gsettingsDesktopSchemaDirectory}"
            '';
          };
        });
    };
}
