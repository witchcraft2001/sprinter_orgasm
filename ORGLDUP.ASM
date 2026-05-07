; Build unpacked OrgAsm EXE on the target system from OUT\CORE.BIN and
; OUT\OVERLAY.BIN.

        ifdef ORGASM_HOST_BUILD
        device zxspectrum128
        endif

        define ORGASM_UNPACKED 1
        include "orgload.asm"

        ifdef ORGASM_HOST_BUILD
        savebin "out/orgunpk.exe",ExeHeader,OverlayPayloadEnd-ExeHeader
        else
        display "DBG: orgldup pre-savebin"
        savebin "out\ORGASM.EXE",ExeHeader,OverlayPayloadEnd-ExeHeader
        display "DBG: orgldup post-savebin"
        endif
