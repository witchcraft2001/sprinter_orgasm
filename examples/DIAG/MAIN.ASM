	        org #6400

	        display "DIAG example"
	        warning "DIAG warning"
	        assert 1,"DIAG assert"

Start:  byte #3e,#2a
	        word Start
End:
        savebin "DIAG.BIN",#6400,End-#6400
