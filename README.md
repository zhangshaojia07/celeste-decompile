# celeste-decompile

A read-only reference copy of decompiled vanilla Celeste, kept in one place so
mod repos (like [ShaojiaHelper](https://github.com/zhangshaojia07/ShaojiaHelper))
can point at it instead of each keeping their own decompile.

> **Important:** `source/` is decompiled Celeste code. It is read-only and is
> **not** committed or pushed to GitHub (see `.gitignore`). Do not redistribute it.

## Requirements

- [ilspycmd](https://github.com/icsharpcode/ILSpy): `dotnet tool install -g ilspycmd`
- A local Celeste + [Everest](https://everestapi.github.io/) install — Everest
  keeps the vanilla Windows build at `orig/Celeste.exe`.

## Usage

Tell the script where Celeste lives (via the `CELESTE_DIR` env var, a
`.celeste-path` file, or the default Debian Steam path — see `AGENT.md`), then
run:

```sh
./refresh.sh
```

The script hashes `orig/Celeste.exe` and only re-decompiles when the game
binary changed. It prints the path to `source/` on its last line, so other
tooling can capture it:

```sh
SOURCE_DIR="$(./refresh.sh | tail -n 1)"
```

`source/` is made read-only on purpose — treat it as reference material only.

## Agent rules

See [`AGENT.md`](AGENT.md). Enable the pre-commit guard on a fresh clone with:

```sh
git config core.hooksPath .githooks
```

## Legal

The decompiled output is Celeste's code. It is kept locally for modding
reference only and is never committed or shared. If you need certainty about a
specific use, check Celeste's terms or ask the developers.
