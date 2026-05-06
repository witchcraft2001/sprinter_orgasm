; OrgAsm self-host wrapper. It builds the unpacked core image.

        define ORGASM_WITH_OVERLAY 1
        include "orgasm.asm"

        savebin "CORE.BIN",#4100,CoreEnd-#4100
