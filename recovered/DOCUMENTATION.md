# VINNIX kit

Saved from the mail attachment `VINNIX.VDI.zip` (64877 bytes). The unzipped tree is `VINNIX.VDI/`. `__MACOSX` was not kept.

## What the zip actually contains

`VINNIX.AH`, `VINNIX.H`, `VINNIX.ASM`, `VINNIX.LST`, `VINNIX.DIR`, `#README`, `MAIN.C`, and `TICK.C` are not readable source. They are mixed line endings and S-record text. The S-record payloads are binary, not an assembler or C header.

Readable members are truncated listing fragments stored under historical names: `VINNIX.MAK` and `VINNIX.MAP` are C listing pieces, `VINNIX.MIK` and `VIOS.ASM` / `VIOS.AH` / `VIOS.LST` are assembly listing pieces, and several `.REL` files are S-record text. Do not copy any of these over the goldens in `2277-alt/` or `6001/`.

## Recovered include

`vinnix.ah` (this directory, and copies in `2277-alt/`, `6001/`, and `2277/`) is the include body from the two job listings. The 1992-09-23 and 1994-08-07 listings of that include are the same 74 source lines: `WDT` / `WDTMSK` / `STACKLEN`, the `TRAP`, `SEQ`, and `RETURN` macros, and the RTEX comment block. The page break between `SEQ START` and `SEQ STARTV` is listing pagination.

`vinnix.h` is not recovered. Every C listing, including `stdio.h` and `2277.h`, shows only `INFILE` / `END` for a `#include`. The zip's `VINNIX.H` is not C. xc9 still does not open includes, so a header placed beside `main.c` does not change the compile.

## Hand assemble (2026-10-24)

With the recovered include on the source path, Mimic `a9 -nh` wrote objects under `/tmp/fixcheck/vinnix-use`. Archived goldens were not modified.

| Job | File | Result |
|-----|------|--------|
| 2277-alt | `vinnix.rel` | 1448 bytes, miss 0, diff 0, extra 0 |
| 2277-alt | `vinnix.lst` | golden object bytes present; 48 extra rebuild listing bytes |
| 2277-alt | `pb.rel`, `irq.rel`, `2277.rel` | exact |
| 6001 | `VINNIX.REL` / `VINNIX.LST` | same as 2277-alt |
| 6001 | `PB.REL`, `IRQ.REL`, `2277.REL` | exact |
| 2277 | `2277.ASM` | still stops: that directory has no `2277.ah` and no `2277.LST` to recover it from |

`2216`, `2299`, and `2299-alt` include `vinnix.ah` only inside `IFNE _RTEX`, and those sources set `_RTEX` to 0. No header was added there. `2299/KP.REL` was reassembled after the assembler fix below and still matches (381 bytes).

Two a9 fixes were required before `vinnix.rel` matched. `STD [PBADR]` is indirect extended (`ED 9F` plus a 16-bit address). `3*4+TQ$` keeps the absolute 12 and adds it to `TQ$`. `make asm-test` passed. The catalog was not re-run. 2277-alt and 6001 are still not passes: the linked images differ, and xc9 does not compile the C sources.
