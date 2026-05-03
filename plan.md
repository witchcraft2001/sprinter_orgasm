# OrgAsm sjasmplus Compatibility Plan

This file tracks the staged work needed to add practical sjasmplus source compatibility to OrgAsm. Mark items as complete as they are implemented and verified.

## Stage 1: Self-Host Build Minimum

- [ ] Add `SAVE` and `SAVEBIN` directives compatible with the common sjasmplus form:
  - `SAVEBIN "file.bin", start, size`
  - `SAVE "file.bin", start, size`
- [ ] Defer `SAVE`/`SAVEBIN` writes until assembly succeeds, so failed builds do not leave partial output files.
- [ ] Add a source-driven output mode that disables the implicit command-line output file and writes only files requested by `SAVE`/`SAVEBIN`.
- [ ] Add a command-line switch for source-driven output mode, for example `/N`, and document that `/E` remains only for the legacy implicit EXE output path.
- [ ] Add data directive aliases used by sjasmplus/TASM-style sources:
  - `BYTE` as `DB`
  - `WORD` as `DW`
  - `BLOCK size[,fill]` as `DS size[,fill]`
- [ ] Update `orgasm.asm` or add a small compatibility include so OrgAsm can emit its own executable image explicitly.
- [ ] Verify self-host assembly: build OrgAsm with sjasmplus, then assemble the same source with OrgAsm and compare binaries.
- [ ] Document the self-host build procedure in `README`, `README.eng`, and `HISTORY`.

## Stage 2: Conditional Compilation

- [ ] Implement a preprocessor-level conditional stack before normal line parsing.
- [ ] Support `DEFINE name value` and `UNDEFINE name`.
- [ ] Support `IF expr`, `IFN expr`, `IFDEF name`, and `IFNDEF name`.
- [ ] Support `ELSEIF expr`, `ELSE`, and `ENDIF`.
- [ ] Ensure inactive branches are skipped without parsing labels, mnemonics, or invalid code.
- [ ] Support colon-separated conditional directives, for example:
  - `IFNDEF NEW_VERSION : DEFINE NEW_VERSION 1 : ENDIF`
- [ ] Add examples/tests for nested conditions and invalid code inside skipped branches.

## Stage 3: TASM Source Compatibility Subset

- [ ] Add `DISP` and `ENT`, mapping to `PHASE`/`DEPHASE` only if the semantics match.
- [ ] Add `DUP` and `EDUP` block repetition.
- [ ] Add `DEFD`/`DD` for little-endian 32-bit data.
- [ ] Add numeric compatibility where needed, including grouped binary literals such as `%0100'0000`.
- [ ] Review `/Users/dmitry/dev/zx/sprinter/sources/tasm_071/TASM` after each feature and add focused regression examples.

## Stage 4: Banked Project Output

- [ ] Introduce an output backend boundary so instruction/data emission goes through shared `EmitByte`/`EmitBlock` routines instead of directly assuming one linear output buffer.
- [ ] Keep the existing linear output backend for legacy builds.
- [ ] Add a virtual device memory backend with 16K pages suitable for Sprinter-style banked projects.
- [ ] Add minimal page mapping directives:
  - `DEVICE SPRINTER[,pages]`
  - `SLOT n|address`
  - `PAGE n`
  - `MMU slot,page[,address]`
- [ ] Make `ORG` in device mode write to the currently mapped virtual page while preserving the visible Z80 address.
- [ ] Extend regular label metadata with page number, keeping `EQU` labels as pure expression values unless an explicit page is provided.
- [ ] Add page-aware expression helpers compatible with sjasmplus where practical:
  - `$$` for current page
  - `$$label` or `PAGEOF(label)` for a label page
- [ ] Add `SAVEDEV "file", page, offset, size` for saving virtual memory across page boundaries.
- [ ] Ensure `SAVEBIN` in device mode saves from the currently mapped virtual memory, matching sjasmplus-style usage.
- [ ] Add regression examples that assemble one source into multiple 16K page `.bin` files.

## Stage 5: Symbol Export and Multi-Stage Builds

- [ ] Add `EXPORT label` for explicitly exported symbols.
- [ ] Add a text symbol export format that can be included by another source, for example:
  - `Label: EQU #C123`
  - `Label.PAGE: EQU 3`
- [ ] Add `IMPORT` or document `INCLUDE` usage for exported symbol files.
- [ ] Add a `LABELSLIST "file"` style output for debugger/emulator tooling, including page and address for regular labels.
- [ ] Add safeguards against stale symbol imports where feasible, such as optional source/version comments in generated symbol files.
- [ ] Document that banked single-project assembly is preferred for tightly coupled code, while exported symbols are intended for libraries or staged builds.

## Stage 6: Extended sjasmplus Subset

- [ ] Evaluate `OUTPUT`/`OUTEND` support or map it to the new output-range mechanism.
- [ ] Add useful diagnostics directives if needed: `DISPLAY`, `ASSERT`, `ERROR`, and `WARNING`.
- [ ] Decide whether `ALIGN` is needed separately from `BLOCK`.
- [ ] Consider macro support only after the previous stages are stable.

## Verification Checklist

- [ ] `make` builds `out/orgasm.exe`.
- [ ] `make dist` builds distribution artifacts.
- [ ] Existing examples still compile as expected.
- [ ] `examples/ERRORS` still produces useful `/L` diagnostics only when errors are present.
- [ ] Self-host output is byte-for-byte identical or differences are documented.
