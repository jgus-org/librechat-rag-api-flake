# librechat-rag-api-flake

A Nix flake that provides [rag_api](https://github.com/danny-avila/rag_api), the document-embedding and retrieval sidecar for [LibreChat](https://github.com/danny-avila/LibreChat). Upstream publishes no releases, so the pin tracks a commit of its `main` branch.

## Outputs

- `packages.<system>.librechat-rag-api` — the service, exposing `librechat-rag-api` on `PATH`. `packages.<system>.default` is the same derivation.
- `packages.<system>.update-version` — maintenance output that re-pins the tracked commit and its source hash; not needed to consume the flake.

There are no overlays, devShells, or apps. The package is built and run on Linux; on Darwin, evaluation fails as an unsupported platform.

## Consuming it

```nix
inputs.librechat-rag-api = {
  url = "github:jgus-org/librechat-rag-api-flake";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.flake-utils.follows = "flake-utils";
};
```

then install or run `inputs.librechat-rag-api.packages.${system}.librechat-rag-api`. Following `nixpkgs` is safe: the only hash this flake carries is the upstream source tarball's. The Python environment is nixpkgs packages mapped from upstream's `requirements.lite.txt` rather than upstream's lockfile, so dependency versions follow whichever nixpkgs you resolve against, not upstream's tested set.

## Running it

The launcher runs upstream's `main.py` under uvicorn, bound to `RAG_HOST`/`RAG_PORT` (`0.0.0.0:8000` by default), and takes all configuration from the environment.

- **`RAG_UPLOAD_DIR` must point somewhere writable.** It defaults to `./uploads/` and upstream creates it at import time; the launcher runs the app from its own directory inside the Nix store, where that cannot succeed.
- **It needs a vector store.** `VECTOR_DB_TYPE` defaults to `pgvector`, so it expects a reachable PostgreSQL with pgvector (`POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `DB_HOST`, `DB_PORT`); `VECTOR_DB_TYPE=atlas-mongo` with `ATLAS_MONGO_DB_URI` is the alternative. Neither is configured for you.
- Setting `RAG_HOST=::` yields a dual-stack listener: the package ships a `sitecustomize` hook that drops the `IPV6_V6ONLY` request, so a `::` bind stays reachable over IPv4.

## Versions

`version` is a datestamp (`0-unstable-2026-09-24` style) because upstream has no releases; `pin.nix` carries the commit it resolves to.

## Licence

Upstream rag_api is MIT. This flake evaluates nixpkgs with `allowUnfree` enabled, so an unfree dependency entering the Python closure is built rather than refused.
