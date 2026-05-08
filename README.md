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
out/overlay.bin
```

`orgasm.asm` and `overlay.asm` are assembled as one sjasmplus project with
`ORGASM_HOST_BUILD` and `ORGASM_WITH_OVERLAY` defined. This keeps overlay
labels resolved normally and avoids a fixed jump table at the start of the
overlay block.

Then `tools/mhmt -hst -zxh` compresses it to:

```text
out/core.hst
```

Finally `orgload.asm` builds the Sprinter EXE. The loader uses the minimal
22-byte DSS EXE v1 header, loads its primary image at `#8200`, and enters the
loader code at `#8280` after a 128-byte PSP guard. At runtime it prints the
startup/help text, allocates and maps one page into win1, allocates a separate
overlay page for cold OrgAsm routines, copies the DSS command line to `#4000`,
zero-terminates it for the historical parser, reads the packed payload to
`#8600` in the loader page, reads the overlay through win3, unpacks the core to
`#4100`, passes the overlay block ID in `A`, and jumps to the core.

```sh
make unpacked
```

Builds the debug/self-hosting variant:

```text
out/orgunpk.exe
```

This uses the same loader, but the payload is the raw `core.bin`. At
runtime the loader allocates and maps win1, allocates the overlay page, reads
the raw core directly to `#4100`, reads the overlay through win3, passes the
overlay block ID in `A`, and jumps to the core.

Target-side self-hosting reuses the regular `orgasm.asm` and `orgload.asm`
sources via OrgAsm command-line defines (`-DNAME[=value]` / `/DNAME[=value]`),
so no wrapper files are needed. `SELFBLD.BAT` runs the two steps:

```
..\ORGASM.EXE orgasm.asm /N /L=ORGSELF.ERR -DORGASM_WITH_OVERLAY -DORGASM_SELF_BUILD
..\ORGASM.EXE orgload.asm /N /L=ORGLDUP.ERR -DORGASM_UNPACKED -DORGASM_SELF_BUILD
```

The first call writes `OUT\CORE.BIN` and `OUT\OVERLAY.BIN`; the second
assembles those into an unpacked `OUT\ORGASM.EXE`.

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
This keeps the EXE header, startup/help text, 128-byte legacy EXE padding, and
cold fatal-error/memory-service routines out of the resident core and allows
`MaxLoadFile` to stay at 64. The win1 and overlay pages are allocated via
`Dss.GetMem`; DSS releases pages owned by the task during `Dss.Exit`. The
overlay is assembled for `#8000` and is temporarily mapped into win2 only while
its cold routines run.

Current core layout should be checked with a symbol build when memory-sensitive
changes are made:

```sh
sjasmplus -DORGASM_HOST_BUILD -DORGASM_WITH_OVERLAY --sym=/tmp/orgasm.sym orgasm.asm
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
