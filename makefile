RM=rm
PORT=/dev/ttyUSB0
SUDO=sudo

ifdef WIN
RM=del
PORT=COM3
SUDO= 
endif

all: f256_2048

f256_2048: *.asm
	64tass --nostart -o f256_2048 main.asm

clean: 
	$(RM) f256_2048

upload: f256_2048
	$(SUDO) python fnxmgr.zip --port $(PORT) --binary f256_2048 --address 2500

test:
	6502profiler verifyall -c config.json
