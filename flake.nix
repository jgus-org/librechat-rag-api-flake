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
          requirements = flake-lib.lib.readPythonRequirements (sourcePath + "/requirements.lite.txt");

          dependencies =
            ps:
            map (n: ps.${n}) (
              map (n: if n == "psycopg2-binary" then "psycopg2" else n) (
                builtins.filter (n: n != "opencv-python-headless") requirements
              )
            );

          # unstructured/nltk resolve corpora under NLTK_DATA; ship what nixpkgs packages.
          nltkData = pkgs.symlinkJoin {
            name = "librechat-rag-api-nltk-data";
            paths = with pkgs.nltk-data; [
              punkt
              stopwords
            ];
          };

          # asyncio sets IPV6_V6ONLY=1 when binding `::`, making it IPv6-only; drop that setsockopt so a `::` bind is dual-stack and reachable over IPv4. sitecustomize is auto-imported before main.py / uvicorn.
          dualStackHook = pkgs.writeTextDir "sitecustomize.py" ''
            import socket
            _orig = socket.socket.setsockopt
            def setsockopt(self, level, optname, value, *a, **kw):
                if level == socket.IPPROTO_IPV6 and optname == socket.IPV6_V6ONLY and value:
                    return
                return _orig(self, level, optname, value, *a, **kw)
            socket.socket.setsockopt = setsockopt
          '';

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
              NLTK_DATA = "${nltkData}";
              SCARF_NO_ANALYTICS = "true";
            };
            name = "librechat-rag-api";
            pythonPath = [ dualStackHook ];
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
