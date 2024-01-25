RM=rm
PORT=/dev/ttyUSB0
SUDO=sudo

BINARY=f256_2048

ifdef WIN
RM=del
PORT=COM3
SUDO= 
endif

all: $(BINARY)
pgz: $(BINARY).pgz

$(BINARY): *.asm
	64tass --nostart -o $(BINARY) main.asm

clean: 
	$(RM) $(BINARY)
	$(RM) $(BINARY).pgz

upload: $(BINARY).pgz
	$(SUDO) python fnxmgr.zip --port $(PORT) --run-pgz $(BINARY).pgz

$(BINARY).pgz: $(BINARY)
	python make_pgz.py $(BINARY)

test:
	6502profiler verifyall -c config.json
