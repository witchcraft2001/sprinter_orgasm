# OrgAsm Repository

This repository contains the OrgAsm Sprinter/Z80 assembler source.
`README`, `README.eng`, `HISTORY`, and `docs/` are user-facing distribution
files. Build and repository maintenance notes live here.

## Build Requirements

- `sjasmplus`
- `tools/mhmt` for the packed executable
- `mtools`, `zip`, and `iconv` for distribution artifacts

## Build Targets

```sh
make
```

Builds the normal packed executable:

```text
out/orgasm.exe
```

The build first creates the raw OrgAsm core:

```text
out/core.bin
```

Then `tools/mhmt -hst -zxh` compresses it to:

```text
out/core.hst
```

Finally `orgload.asm` builds the Sprinter EXE. The loader uses the minimal
22-byte DSS EXE v1 header, loads its primary image at `#8200`, and enters the
loader code at `#8280` after a 128-byte PSP guard. At runtime it prints the
startup/help text, allocates and maps one page into win1, copies the DSS command
line to `#4000`, zero-terminates it for the historical parser, reads the packed
payload to `#8600` in the loader page, unpacks the core to `#4100`, and jumps to
it.

```sh
make unpacked
```

Builds the debug/self-hosting variant:

```text
out/orgunpk.exe
```

This uses the same loader, but the payload is the raw `core.bin`. At
runtime the loader allocates and maps win1, reads that payload directly to
`#4100`, and jumps to it.

`ORGSELF.ASM` is the target-side self-host wrapper. It includes
`ORGASM.ASM` and writes the unpacked core as `CORE.BIN` from `#4100`; the
complete packed `ORGASM.EXE` is still produced by the repository `make` flow.

```sh
make dist
```

Builds the packed executable and writes:

```text
distr/orgasm.img
distr/orgasm.zip
```

The floppy image does not include `DOCS/`. The zip distribution includes
CP866-converted user documentation under `DOCS/`.

## Memory Layout

The resident OrgAsm core starts at `#4100` in win1. The loader passes the
command line through `#4000`. DSS stores the command tail as a length-prefixed
PSP field and the current DSS `Execute.ASM` code uses a hard-coded `#80` byte
command-line limit, so `#4000..#40FF` is a conservative command-line area.
This keeps the EXE header, startup/help text, and 128-byte legacy EXE padding
out of the resident core and allows `MaxLoadFile` to stay at 64. The win1 page
is allocated via
`Dss.GetMem`; DSS releases pages owned by the task during `Dss.Exit`.

Current core layout should be checked with a symbol build when memory-sensitive
changes are made:

```sh
sjasmplus --sym=/tmp/orgasm.sym --raw=/tmp/core.bin orgasm.asm
```

Important symbols:

```text
Start       #4100
ComBuffer   near #7D00
TabLabel    #8000
```

## Notes

Do not try to run `ORGASM.EXE` locally. It is a Sprinter/DSS binary. Build
`distr/orgasm.img` and test it on the target Sprinter environment or emulator.
