# ==============================================================================
# Makefile for Cosmic Particle Swarm (ZX Spectrum Next)
# ==============================================================================

ASM = sjasmplus
MAIN_SRC = main.asm
NEX_OUT = rnddots.nex
TEST_SRC = Libraries/test/test_main.asm
TEST_OUT = Libraries/test/libtest.nex

.PHONY: all clean test release

all: $(NEX_OUT)

$(NEX_OUT): $(MAIN_SRC) ClExit.asm Libraries/lib/*.asm Libraries/lib/*.inc Libraries/inc/*.inc
	$(ASM) $(MAIN_SRC)

test: $(TEST_SRC)
	cd Libraries/test && $(ASM) test_main.asm

clean:
	rm -f $(NEX_OUT) $(TEST_OUT) *.lst *.tmp *.bak Libraries/test/*.lst
