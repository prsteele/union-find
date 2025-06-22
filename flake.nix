{
  description = "Union-find algorithm";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems }:
    let
      forAllSystems = nixpkgs.lib.genAttrs (import systems);
      mkPkgs = system: import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
    in
    {
      packages = forAllSystems
        (system:
          let
            pkgs = mkPkgs system;
          in
          {
            default = pkgs.haskellPackages.union-find;
          });

      devShells = forAllSystems (system:
        let
          pkgs = mkPkgs system;
        in
        {
          default = pkgs.haskellPackages.shellFor {
            packages = hpkgs: [ hpkgs.union-find ];

            buildInputs = [
              pkgs.haskellPackages.haskell-language-server
              pkgs.ormolu
              pkgs.cabal-install
            ];

            withHoogle = true;
          };
        }
      );

      overlays = {
        default = final: prev: {
          haskellPackages = prev.haskellPackages.override {
            overrides = hfinal: hprev: {
              union-find = hfinal.callCabal2nix "union-find" ./. { };
            };
          };
        };
      };
    };
}
