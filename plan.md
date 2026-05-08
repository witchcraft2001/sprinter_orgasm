# OrgAsm sjasmplus Compatibility Plan

This file tracks the staged work needed to add practical sjasmplus source compatibility to OrgAsm. Mark items as complete as they are implemented and verified.

## Priority 1: Resident Memory Relief

- [x] Move fatal DSS error handling (`Error`, `ErrorDSS`, `ErrorDSS1`) out of resident win1 into the win2 overlay page.
- [x] Move startup/exit memory service code (`MemInfoTotal`, `MemInfoFree`, `FrMem*`) out of resident win1 into the win2 overlay page.
- [x] Split win2 overlay implementation into `overlay.asm` and resolve overlay entry labels directly from the shared project assembly, without a fixed `jp` table at `OverlayStart`.
- [x] Move remaining text resources that can be addressed outside hot parser paths:
  startup/load/save/include/continue/scanning/pause/abort messages, memory totals, error-count
  summary, and compile-time summary now live in the win2 overlay; resident code prints overlay
  strings through one shared wrapper.
- [ ] Analyze risks for moving final output code (`SaveOutF`, `CreateSub`, `SaveDirectiveFiles`, `SaveRangeFile`, `ClampSaveLen`), `/L` error-log code (`OpenErrLog`, `WriteErrLog`, `CloseErrLog`, `MakeDefaultErrName`, `ErrGetFileName`), include path helpers (`SaveCurPath`, `RestoreCurPath`, `CurSpec`), selected `LoadFile` parts, and remaining UI/formatting helpers (`Hex2Dec`, hot progress-line printing).

## Priority 2: Correct Relative Branch Expressions

- [ ] Fix OrgAsm expression handling for `JR`/`DJNZ` operands, including both current-program-counter forms (`jr $+3`, `jr z,$+5`, `jr $-4`) and ordinary label expressions (`jr z,NumHex1`). The self-hosting failure shows the common relative-offset path is wrong, not only the `$` token. This must be fixed in the calculator/PC accounting and `_jrdjnz` range calculation instead of masking failures by rewriting sources to labels or absolute `JP`. Add regression examples that prove `$+N`/`$-N` and label targets are calculated relative to the Z80 displacement base (`PC+2`).
  - Added `examples/RELJMP` to exercise `$+N`, `$-N`, forward/backward label targets, `DJNZ`, and regular `$` expressions such as `ld ($+5),a`.
  - `_jrdjnz` now performs range validation only on pass 2, after labels and PC accounting are stable. It reads the saved relative operand from the correct operand slot (`JR` uses operand 1, conditional `JR` uses operand 2, `DJNZ` uses operand 1); `$+N`/`$-N` use a local decimal displacement parser, while label operands support direct label targets and short decimal `Label+N`/`Label-N` offsets.

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
- [x] Add sjasmplus-compatible command-line defines so OrgAsm can build conditional sources without wrapper files during self-hosting:
  - [x] accept `-DNAME` and `/DNAME` as command-line defines with value `1`;
  - [x] accept `-DNAME=value` and `/DNAME=value` where `value` is stored as the same text/value form used by the existing source-level `DEFINE`;
  - [x] install these symbols before pass 1, before the first source line is parsed, so `IFDEF`, `IFNDEF`, `IF`, and normal expression evaluation see them exactly like source-level `DEFINE`;
  - [x] keep source-level `DEFINE`/`UNDEFINE` behavior unchanged after startup, so a source can intentionally override or remove a command-line define if it already can do that for any other define;
  - [x] duplicate `-DNAME -DNAME` is a fatal error ("Duplicate command-line define") — explicit, no silent override.
  - [x] add `examples/CMDDEF/` with `MAIN.ASM` + `build.bat` exercising 4 scenarios.
  - [x] support `ORGASM_UNPACKED` use case: `orgasm orgload.asm /N -DORGASM_UNPACKED -DORGASM_SELF_BUILD`. Wrappers `ORGSELF.ASM`/`ORGLDUP.ASM` removed; `savebin` for `OUT\CORE.BIN`/`OUT\OVERLAY.BIN`/`OUT\ORGASM.EXE` now lives in `orgasm.asm`/`orgload.asm` under `ifdef ORGASM_SELF_BUILD` blocks.
  - [x] document the option in both manuals.
- [x] Verify OrgAsm-on-OrgAsm assembly: build OrgAsm with sjasmplus, then assemble the same source with OrgAsm and compare binaries. Target self-build (`SELFBLD.BAT`) produces byte-identical `CORE.BIN` (13945), `OVERLAY.BIN` (2224), and `ORGASM.EXE` (16814) versus the host `make` artifacts.
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
- [ ] Keep the existing linear output backend for current single-buffer builds.
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
- [x] Add `DISPLAY "text"` as a useful assembly-time diagnostic directive.
- [x] Add remaining useful diagnostics directives if needed: `ASSERT`, `ERROR`, and `WARNING`.
- [x] Split the Sprinter executable into a small EXE loader and a resident OrgAsm core, with packed and unpacked build modes, to reduce low-memory pressure while restoring `MaxLoadFile` to 64.
- [ ] Decide whether `ALIGN` is needed separately from `BLOCK`.
- [ ] Define a deliberate boundary for unsupported sjasmplus features, especially `LUA`, `ENDLUA`, and `INCLUDELUA`.
- [ ] Consider macro support only after the previous stages are stable.
- [ ] Revisit low-memory workspace pressure before adding more parser features; the loader/core split restored `MaxLoadFile` to 64, but `ComBuffer` and the stack still share the top of the resident core workspace.
- [x] Add ASM examples for every newly supported extended sjasmplus directive.
- [ ] Document the supported sjasmplus subset and explicitly unsupported features in `docs/` in Russian and English.

## Stage 8: Relocatable Object Output (REL)

Goal: emit linker-ready object modules so OrgAsm sources can be linked together with units produced by other toolchains. Target format is the SDCC/ASxxxx text REL accepted by `sdldz80` (the Sprinter SDK linker), because it is text, documented, and pipeline-relevant. MS REL (M80/L80) is out of scope for the first cut.

- [ ] Decide and document the supported REL flavor and its limits (areas, relocation kinds, expression contexts) before implementation; explicitly call out what we do not support.
- [ ] Add a build mode switch (e.g. `/REL` or directive `MODULE name`) that selects relocatable output instead of absolute `SAVE`/`SAVEBIN`/EXE flow. In REL mode, `ORG` and the implicit output are disabled or redefined.
- [ ] Add symbol visibility directives:
  - `PUBLIC name` / `GLOBAL name` — mark a defined symbol as exported.
  - `EXTERN name` / `EXTRN name` — declare a symbol resolved by the linker; references are allowed without producing an undefined-symbol error.
- [ ] Add area/section directives:
  - `AREA name [(flags)]` — switch the current emission area; flags map to ASxxxx semantics (REL/CON/OVR/ABS/PAG) on a minimal supported subset.
  - Default areas `_CODE`, `_DATA`, `_BSS` available out of the box.
- [ ] Track per-area emission with its own offset counter and per-area object buffer; replace single-buffer assumptions in the emit path with an area-aware backend (overlaps with Stage 5 backend boundary work — share infrastructure).
- [ ] Extend the calc engine to flag expressions that reference an `EXTERN` or area-relative symbol, and restrict where such expressions may appear (allowed contexts only): `dw <sym>`, `ld rr,<sym>`, `jp/call <sym>`, `db <sym>`/`<sym`/`>sym`, with optional `+const`/`-const`. Reject externals in any other expression context with a clear diagnostic.
- [ ] Build a relocation table during pass 2: for every emission that references an area-relative or external symbol, record `(area, offset, fixup-kind, symbol-index, addend)`. Allocate the reloc buffer through `Dss.GetMem` (mirror what the label table already does).
- [ ] Implement the REL writer (cold code, lives in overlay): emit `XL2`/`H`/`M`/`S`/`A`/`T`/`R`/`P` records in the documented order; produce one `.rel` per module; deferred-write at end of compilation like `SAVE`.
- [ ] Add a regression example that produces a `.rel`, links it with `sdldz80` against a stub from the SDCC SDK, and compares the linked binary to a pre-recorded reference. Place sources under `examples/REL/`.
- [ ] Document REL mode in `docs/ru/manual.md` and `docs/en/manual.md`: supported directives, area/visibility model, allowed expression contexts for externals, command-line/mode switch, and limitations vs. full ASxxxx.
- [ ] Add `HISTORY` entry once shipped.

Open questions to resolve before starting implementation:

- Whether to require an explicit mode switch (`/REL`) or auto-detect mode from the presence of `MODULE`/`AREA` directives.
- Whether to support multi-area `.rel` (one module, multiple areas) in MVP, or limit MVP to a single `_CODE` area.
- Memory budget for the reloc table: prefer dynamic page allocation over a fixed buffer, so reloc-heavy modules do not OOM.
- Whether MS REL (M80/L80) joins this stage as a second writer or stays out of scope until requested.

## Long-Term Memory Model

- [ ] Reserve `win2` as a permanent OrgAsm data page to stop resident-code growth in `win1` from competing with the stack and command-line buffers:
  - `win1 #4000..#7FFF`: resident code
  - `win2 #8000..#BFFF`: permanent OrgAsm data, including stack, `ComBuffer`, `SaveReqTable`, `TblLoadFile`, and large temporary buffers
  - `win3 #C000..#FFFF`: the only bank-switched data window for source text, labels, object code, and report/log data
- [ ] Before changing the memory model, introduce a small access layer for bank-switched source/object/label/report blocks so code no longer assumes a contiguous `win2+win3` 32K data window.
- [ ] Audit and rewrite all direct `SetWin2`/`SetWin3`, `Page2`/`Page3`, `#8000`/`#C000`, and `bit 6,h` boundary assumptions as part of the memory-model migration.

## Verification Checklist

- [ ] `make` builds `out/orgasm.exe`.
- [ ] `make dist` builds distribution artifacts.
- [ ] Existing examples still compile as expected.
- [ ] Every stage with compiler behavior changes includes at least one ASM example that exercises the new behavior.
- [ ] `examples/ERRORS` still produces useful `/L` diagnostics only when errors are present.
- [ ] OrgAsm-on-OrgAsm output is byte-for-byte identical or differences are documented.
- [ ] Russian and English documentation in `docs/` is updated for every changed user-visible feature.
- [ ] Distribution archive includes CP866-converted `DOCS/`; floppy image does not include `DOCS/`.
