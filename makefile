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
pgx: $(BINARY).pgx

$(BINARY): *.asm
	64tass --nostart -o $(BINARY) main.asm

clean: 
	$(RM) $(BINARY)
	$(RM) $(BINARY).pgx

upload: f256_2048
	$(SUDO) python fnxmgr.zip --port $(PORT) --binary $(BINARY) --address 2500

$(BINARY).pgx: $(BINARY)
	python make_pgx.py f256_2048

test:
	6502profiler verifyall -c config.json
