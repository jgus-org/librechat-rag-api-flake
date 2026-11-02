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

          # The names arrive read from upstream's requirements.lite.txt. Two depart from what the file asks: nixpkgs publishes psycopg2 without the -binary wheel spelling, and opencv-python-headless is pulled transitively by rapidocr-onnxruntime, where naming it too would collide on the cv2 module.
          pythonEnv = pkgs.python3.withPackages (
            ps:
            map (n: ps.${n}) (
              map (n: if n == "psycopg2-binary" then "psycopg2" else n) (
                builtins.filter (n: n != "opencv-python-headless") requirements
              )
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
        in
        {
          librechat-rag-api = pkgs.stdenv.mkDerivation {
            inherit src version;
            dontBuild = true;
            dontConfigure = true;
            dontStrip = true;
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/share/librechat-rag-api" "$out/bin"
              cp -r . "$out/share/librechat-rag-api"
              makeWrapper ${pythonEnv}/bin/python "$out/bin/librechat-rag-api" \
                --add-flags "$out/share/librechat-rag-api/main.py" \
                --chdir "$out/share/librechat-rag-api" \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.pandoc ]} \
                --prefix PYTHONPATH : ${dualStackHook} \
                --set-default NLTK_DATA "${nltkData}" \
                --set-default SCARF_NO_ANALYTICS "true"
              runHook postInstall
            '';
            meta.mainProgram = "librechat-rag-api";
            nativeBuildInputs = [ pkgs.makeWrapper ];
            pname = "librechat-rag-api";
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
