; OrgAsm self-host wrapper. Use sjasmplus with Makefile for host builds.

        include "orgasm.asm"

        savebin "ORGASM.EXE",#4000,$-#4000
