{
  description = "LibreChat RAG API (danny-avila/rag_api): document-embedding/retrieval service.";

  inputs = {
    flake-lib = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:jgus-org/flake-lib/v1";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      flake-lib,
      nixpkgs,
    }:
    flake-lib.lib.mkPythonFlake {
      inherit nixpkgs self;
      branches = false;

      payload.packages =
        {
          pkgs,
          sourcePath,
          src,
          version,
          ...
        }:
        let
          requirements = [
            "psycopg2"
          ]
          ++ pkgs.lib.lists.subtractLists [
            "opencv-python-headless"
            "psycopg2-binary"
          ] (flake-lib.lib.readPythonRequirements (sourcePath + "/requirements.lite.txt"));

          dependencies = ps: map (n: ps.${n}) requirements;

          tree = pkgs.stdenv.mkDerivation {
            inherit src version;
            dontBuild = true;
            dontConfigure = true;
            dontStrip = true;
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/share/librechat-rag-api"
              cp -r . "$out/share/librechat-rag-api"
              runHook postInstall
            '';
            pname = "librechat-rag-api";
          };
        in
        {
          librechat-rag-api = flake-lib.lib.mkPythonApplication {
            inherit dependencies pkgs;
            envDefaults = {
              # unstructured/nltk resolve corpora under NLTK_DATA; ship what nixpkgs packages.
              NLTK_DATA = "${pkgs.symlinkJoin {
                name = "librechat-rag-api-nltk-data";
                paths = with pkgs.nltk-data; [
                  punkt
                  stopwords
                ];
              }}";
              SCARF_NO_ANALYTICS = "true";
            };
            name = "librechat-rag-api";
            pythonPath = [ (flake-lib.lib.pythonDualStackIPv6.site pkgs) ];
            runtimeInputs = [ pkgs.pandoc ];
            script = "${tree}/share/librechat-rag-api/main.py";
            workDir = "${tree}/share/librechat-rag-api";
          };
        };

      upstream = {
        owner = "danny-avila";
        pin = import ./pin.nix;
        repo = "rag_api";
        # Upstream publishes named releases; this producer follows main by commit, so update-branches has no release branch to follow.
        track = "commit";
        type = "github";
      };
    };
}
