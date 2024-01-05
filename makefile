all: f256_2048

f256_2048: *.asm
	64tass --nostart -o f256_2048 main.asm

clean: 
	rm f256_2048

upload: f256_2048
	sudo python3 fnxmgr.zip --port /dev/ttyUSB0 --binary f256_2048 --address 2500

test:
	6502profiler verifyall -c config.json
