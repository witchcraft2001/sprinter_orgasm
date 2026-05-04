# OrgAsm sjasmplus Compatibility Plan

This file tracks the staged work needed to add practical sjasmplus source compatibility to OrgAsm. Mark items as complete as they are implemented and verified.

## Stage 1: Documentation Baseline

- [x] Create `docs/ru/` and `docs/en/` for the full OrgAsm manual.
- [x] Use `README` and `README.eng` as source material, but verify all behavior against the current assembler before copying it into the manual.
- [x] Document the current implemented assembler before adding new compatibility features:
  - command-line usage and options
  - legacy output modes, including `/E` and `/L`
  - diagnostics and error log behavior
  - supported directives
  - expressions
  - labels and local labels
  - `INCLUDE` and `INCBIN`
  - examples
  - build, image, and distribution workflow
- [x] Keep README files concise after the full manual exists, with links or pointers to the complete documentation.
- [x] Require every new feature or compatibility addition to update both Russian and English docs in the same change set.
- [x] Store source documentation as UTF-8 in the repository, then convert it to CP866 when copying into the distribution archive.
- [x] Copy documentation into the distribution archive under `DOCS/`, but do not include `DOCS/` in the floppy image.
- [x] Add documentation review to the verification checklist for each completed stage.

## Stage 2: Source-Driven Output Minimum

- [x] Add `SAVE` and `SAVEBIN` directives compatible with the common sjasmplus form:
  - `SAVEBIN "file.bin", start, size`
  - `SAVE "file.bin", start, size`
- [x] Add `OUTPUT "file.bin"` / `OUTEND` as a deferred range output form.
- [x] Defer `SAVE`/`SAVEBIN` writes until assembly succeeds, so failed builds do not leave partial output files.
- [x] Clamp directive output ranges to generated object code, so oversized lengths do not save stale memory or directory data.
- [x] Add a source-driven output mode that disables the implicit command-line output file and writes only files requested by `SAVE`/`SAVEBIN`.
- [x] Add a command-line switch for source-driven output mode, for example `/N`, and document that `/E` remains only for the legacy implicit EXE output path.
- [x] Add data directive aliases used by sjasmplus/TASM-style sources:
  - `BYTE` as `DB`
  - `WORD` as `DW`
  - `BLOCK size[,fill]` as `DS size[,fill]`
- [x] Add ASM examples that verify `SAVE`/`SAVEBIN`, `OUTPUT`/`OUTEND`, source-driven output, and the new data directive aliases.
- [x] Update `orgasm.asm` or add a small compatibility include so OrgAsm can emit executable images explicitly.
- [ ] Verify OrgAsm-on-OrgAsm assembly: build OrgAsm with sjasmplus, then assemble the same source with OrgAsm and compare binaries.
- [x] Document `SAVE`/`SAVEBIN`, `OUTPUT`/`OUTEND`, `/N`, and data aliases in `docs/` in Russian and English, then update `README`, `README.eng`, and `HISTORY` as summaries/pointers.

## Stage 3: Conditional Compilation

- [x] Implement a preprocessor-level conditional stack before normal line parsing.
- [x] Support `DEFINE name value`.
- [x] Support `UNDEFINE name`.
- [x] Support `IF expr`, `IFN expr`, `IFDEF name`, and `IFNDEF name`.
- [ ] Add symbol-usage conditionals such as `IFUSED label` and `IFNUSED label` after label reference tracking exists.
- [x] Support `ELSEIF expr`, `ELSE`, and `ENDIF`.
- [x] Ensure inactive branches are skipped without parsing labels, mnemonics, or invalid code.
- [x] Support colon-separated conditional directives, for example:
  - `IFNDEF NEW_VERSION : DEFINE NEW_VERSION 1 : ENDIF`
- [x] Add examples/tests for nested conditions beyond line-oriented inactive branch skipping.
- [x] Add an ASM example that verifies the implemented conditional compilation directives.
- [x] Document conditional compilation syntax and examples in `docs/` in Russian and English.

## Stage 4: TASM Source Compatibility Subset

- [x] Add `DISP` and `ENT`, mapping to `PHASE`/`DEPHASE` after checking TASM relocation semantics.
- [x] Add `DUP` and `EDUP` block repetition.
- [x] Add `DEFD`/`DD`/`DWORD` for little-endian 32-bit data.
- [x] Add numeric compatibility where needed, including grouped binary literals such as `%0100'0000`.
- [ ] Review `/Users/dmitry/dev/zx/sprinter/sources/tasm_071/TASM` after each feature and add focused regression examples. `DISP`/`ENT`, `DD`/`DEFD`/`DWORD`, `DUP`/`EDUP`, `OUTPUT`/`OUTEND`, and grouped binary literals are covered by `examples/TASM`.
- [ ] Add ASM examples that verify every new TASM compatibility directive or syntax form.
- [ ] Document every newly supported compatibility directive and numeric format in `docs/` in Russian and English.

## Stage 5: Banked Project Output

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
- [ ] Add an ASM example that verifies banked output, page mapping, and multi-file binary saving.
- [ ] Document the banked memory model, page mapping, page-aware labels, and output directives in `docs/` in Russian and English.

## Stage 6: Symbol Export and Multi-Stage Builds

- [ ] Add `EXPORT label` for explicitly exported symbols.
- [ ] Add a text symbol export format that can be included by another source, for example:
  - `Label: EQU #C123`
  - `Label.PAGE: EQU 3`
- [ ] Add `IMPORT` or document `INCLUDE` usage for exported symbol files.
- [ ] Add a `LABELSLIST "file"` style output for debugger/emulator tooling, including page and address for regular labels.
- [ ] Add safeguards against stale symbol imports where feasible, such as optional source/version comments in generated symbol files.
- [ ] Document that banked single-project assembly is preferred for tightly coupled code, while exported symbols are intended for libraries or staged builds.
- [ ] Add ASM examples that verify exported symbols and imported/generated symbol files.
- [ ] Document export/import workflows and symbol file formats in `docs/` in Russian and English.

## Stage 7: Extended sjasmplus Subset

- [x] Evaluate `OUTPUT`/`OUTEND` support or map it to the new output-range mechanism.
- [ ] Add useful diagnostics directives if needed: `DISPLAY`, `ASSERT`, `ERROR`, and `WARNING`.
- [ ] Decide whether `ALIGN` is needed separately from `BLOCK`.
- [ ] Define a deliberate boundary for unsupported sjasmplus features, especially `LUA`, `ENDLUA`, and `INCLUDELUA`.
- [ ] Consider macro support only after the previous stages are stable.
- [ ] Add ASM examples for every newly supported extended sjasmplus directive.
- [ ] Document the supported sjasmplus subset and explicitly unsupported features in `docs/` in Russian and English.

## Verification Checklist

- [ ] `make` builds `out/orgasm.exe`.
- [ ] `make dist` builds distribution artifacts.
- [ ] Existing examples still compile as expected.
- [ ] Every stage with compiler behavior changes includes at least one ASM example that exercises the new behavior.
- [ ] `examples/ERRORS` still produces useful `/L` diagnostics only when errors are present.
- [ ] OrgAsm-on-OrgAsm output is byte-for-byte identical or differences are documented.
- [ ] Russian and English documentation in `docs/` is updated for every changed user-visible feature.
- [ ] Distribution archive includes CP866-converted `DOCS/`; floppy image does not include `DOCS/`.
