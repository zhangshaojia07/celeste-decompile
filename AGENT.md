# AGENT.md — rules for AI agents working in this repo

This repository is a read-only *reference* copy of decompiled vanilla Celeste.
It exists so modding repos (e.g. ShaojiaHelper) can look up Celeste's code
without each keeping their own decompile.

## The golden rule

`source/` is decompiled vanilla Celeste code (from `orig/Celeste.exe`). It is:

- **read-only** — never edit, move, rename, or write anything inside it.
- **never committed** — never `git add`, stage, commit, or push anything under `source/`.
- **never shared** — do not copy it out, upload it, or post it anywhere.

A pre-commit hook rejects any staged path under `source/`, but do not rely on it:
simply never stage it in the first place.

## How to read the code

1. Run `./refresh.sh` first (idempotent — instant when the game binary is
   unchanged). It prints the path to `source/` on its last line:
   ```sh
   ./refresh.sh
   ```
2. Read from `source/`. Prefer targeted lookups over reading whole files:
   ```sh
   ilspycmd -t Celeste.Player "$CELESTE_DIR/orig/Celeste.exe"
   # or grep inside source/
   grep -rn "class Player" source/Celeste/
   ```

Do **not** run `chmod` on `source/` or write anywhere inside it. Put notes and
scratch work in a separate location (e.g. another repo or `~/scratch`).

## Celeste install path

Resolved in this order:
1. `CELESTE_DIR` environment variable
2. `.celeste-path` file in this repo's root (gitignored)
3. default: `~/.steam/debian-installation/steamapps/common/Celeste`

The vanilla assembly is `orig/Celeste.exe` (preserved by Everest). The
Everest-patched assembly at the top level (`Celeste.dll`) is *not* the vanilla
source — do not decompile that one.

## If `source/` is ever committed by mistake

Do not just delete it in a follow-up commit — the bytes remain in history.
Rewrite history with `git filter-repo` and force-push **before anyone clones**:

```sh
git filter-repo --path source/ --invert-paths
git push --force
```

(`pipx install git-filter-repo` if needed.)

## Pre-commit hook

The repo ships `.githooks/pre-commit`. Enable it on a fresh clone with:

```sh
git config core.hooksPath .githooks
```
