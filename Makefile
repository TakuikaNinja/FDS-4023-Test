GAME=4023-test
ASSEMBLER=ca65
LINKER=ld65

OBJ_FILES=$(GAME).o

all: $(GAME).fds

$(GAME).fds: $(OBJ_FILES) fds.cfg
	$(LINKER) -o $(GAME).fds -C fds.cfg $(OBJ_FILES) -m $(GAME).map.txt -Ln $(GAME).labels.txt --dbgfile $(GAME).dbg

.PHONY: clean

clean:
	rm -f *.o *.fds *.dbg *.nl *.map.txt *.labels.txt

$(GAME).o: $(wildcard *.asm) Jroatch-chr-sheet.chr

%.o:%.asm
	$(ASSEMBLER) $< -g -o $@
