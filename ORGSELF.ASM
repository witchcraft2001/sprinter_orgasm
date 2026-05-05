; OrgAsm self-host wrapper. It builds the unpacked core image.

        include "orgasm.asm"

CoreEnd:
        savebin "CORE.BIN",#4100,CoreEnd-#4100
