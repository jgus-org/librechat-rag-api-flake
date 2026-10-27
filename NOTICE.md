# Upstream and distributed artifacts

| Artifact                                                                        | Licence & Notifications                                                                                                               |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| This flake: the Nix, the `sitecustomize` dual-stack hook, these documents       | [MIT](LICENSE.md)                                                                                                                     |
| [rag_api](https://github.com/danny-avila/rag_api) at the commit `pin.nix` names | [MIT](https://github.com/danny-avila/rag_api/blob/c4e5cbf79fcece1df9adfff5dfed983a5990ca9f/LICENSE), `Copyright (c) 2024 Danny Avila` |
| The `punkt` and `stopwords` corpora, the default `NLTK_DATA`                    | [Apache-2.0](https://github.com/nltk/nltk_data/blob/gh-pages/LICENSE)                                                                 |
| The nixpkgs runtime closure: `python3` and its packages, `pandoc`               | As the consumer's nixpkgs records each one in `meta.license`, where `free` and `redistributable` are separate properties              |

The install phase copies the fetched source tree verbatim into `$out/share/librechat-rag-api` and runs upstream's `main.py` from there, so upstream's `LICENSE` travels inside `$out` to whoever the built output is served to; the pinned tarball is fetched only when a derivation is built, so evaluating or promoting this repository conveys nothing. Nothing here patches upstream: the dual-stack behaviour is a `sitecustomize.py` added to `PYTHONPATH`, not an edit to upstream's files, so there is no patch of ours for upstream's terms to govern.
