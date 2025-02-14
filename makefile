RM=rm
PORT=/dev/ttyUSB0
SUDO=

BINARY=f256_2048
SPRBIN=sprdef.bin
FORCE=-f
PYTHON=python
CP=cp
DIST=dist

ifdef WIN
RM=del
PORT=COM3
SUDO=
FORCE=
endif

SPRITES=2.xpm 4.xpm 8.xpm 16.xpm 32.xpm 64.xpm 128.xpm 256.xpm 512.xpm 1024.xpm 2048.xpm 4096.xpm 8192.xpm
SPRASM=2.asm 4.asm 8.asm 16.asm 32.asm 64.asm 128.asm 256.asm 512.asm 1024.asm 2048.asm 4096.asm 8192.asm
LOADER=loader.bin
ONBOARDPREFIX=2048_
FLASHIMAGE=cart_2048.bin
SPRDAT=sprites.dat
PROGDAT=prog.dat

.PHONY: all
all: pgz

.PHONY: pgz
pgz: $(BINARY).pgz

.PHONY: dist
dist: clean pgz cartridge onboard
	$(RM) $(FORCE) $(DIST)/*
	$(CP) $(BINARY).pgz $(DIST)/
	$(CP) $(FLASHIMAGE) $(DIST)/
	$(CP) $(ONBOARDPREFIX)*.bin $(DIST)/


$(SPRASM): $(SPRITES)
	python xpm2t64.py

$(SPRBIN): $(SPRASM) sprdef.asm
	64tass --nostart -o $(SPRBIN) sprdef.asm

$(BINARY): *.asm
	64tass --nostart -o $(BINARY) main.asm

clean: 
	$(RM) $(FORCE) $(BINARY)
	$(RM) $(FORCE) $(SPRBIN)
	$(RM) $(FORCE) $(BINARY).pgz
	$(RM) $(FORCE) $(SPRASM)
	$(RM) $(FORCE) $(SPRDAT)
	$(RM) $(FORCE) $(PROGDAT)
	$(RM) $(FORCE) $(LOADER)
	$(RM) $(FORCE) $(FLASHIMAGE)
	$(RM) $(FORCE) $(ONBOARDPREFIX)*.bin
	$(RM) $(FORCE) $(DIST)/*


upload: $(BINARY).pgz
	$(SUDO) $(PYTHON) fnxmgr.zip --port $(PORT) --run-pgz $(BINARY).pgz

$(BINARY).pgz: $(BINARY) $(SPRBIN)
	$(PYTHON) make_pgz.py $(BINARY)

test:
	6502profiler verifyall -c config.json

$(LOADER): flashloader.asm
	64tass --nostart -o $(LOADER) flashloader.asm

.PHONY: cartridge
cartridge: $(FLASHIMAGE)

$(FLASHIMAGE): $(BINARY) $(LOADER) $(SPRBIN)
	$(PYTHON) pad_binary.py $(BINARY) $(LOADER) $(PROGDAT)
	$(PYTHON) pad_sprites.py $(SPRBIN)
	cat $(PROGDAT) $(SPRDAT) > $(FLASHIMAGE)

.PHONY: onboard
onboard: $(FLASHIMAGE)
	$(PYTHON) split8k.py $(FLASHIMAGE) $(ONBOARDPREFIX)