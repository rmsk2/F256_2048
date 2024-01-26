RM=rm
PORT=/dev/ttyUSB0
SUDO=sudo

BINARY=f256_2048
SPRBIN=sprdef.bin
FORCE=-f

ifdef WIN
RM=del
PORT=COM3
SUDO=
FORCE=
endif

SPRITES=2.xpm 4.xpm 8.xpm 16.xpm 32.xpm 64.xpm 128.xpm 256.xpm 512.xpm 1024.xpm 2048.xpm 4096.xpm 8192.xpm
SPRASM=2.asm 4.asm 8.asm 16.asm 32.asm 64.asm 128.asm 256.asm 512.asm 1024.asm 2048.asm 4096.asm 8192.asm

all: pgz
pgz: $(BINARY).pgz

$(SPRASM): $(SPRITES)
	python xpm2t64.py

$(SPRBIN): $(SPRASM) sprdef.asm
	64tass --nostart -o $(SPRBIN) sprdef.asm

$(BINARY): *.asm
	64tass --nostart -o $(BINARY) main.asm

clean: 
	$(RM) $(FORCE) $(BINARY)
	$(RM) $(FORCE) $(BINARY).pgz
	$(RM) $(FORCE) $(SPRASM)

upload: $(BINARY).pgz
	$(SUDO) python fnxmgr.zip --port $(PORT) --run-pgz $(BINARY).pgz

$(BINARY).pgz: $(BINARY) $(SPRBIN)
	python make_pgz.py $(BINARY)

test:
	6502profiler verifyall -c config.json
