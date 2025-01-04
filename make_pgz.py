import sys
import os

sprdef_name = "sprdef.bin"
start_address = 0x0300
sprite_address = 0x20000

def make_24bit_address(addr):
    help, lo = divmod(addr, 256)
    higher, hi = divmod(help, 256)
    return (lo, hi, higher)


l, h, hh = make_24bit_address(os.path.getsize(sys.argv[1]))
sl, sh, shh = make_24bit_address(start_address)

sp_l, sp_h, sp_hh = make_24bit_address(os.path.getsize(sprdef_name))
sp_sl, sp_sh, sp_shh = make_24bit_address(sprite_address)

pgz_header = bytes([90, sl, sh, shh, l, h, hh])
sp_header = bytes([sp_sl, sp_sh, sp_shh, sp_l, sp_h, sp_hh])
pgz_footer = bytes([sl, sh, shh, 0, 0, 0])

with open(sys.argv[1], "rb") as f:
    data = f.read()

with open(sprdef_name, "rb") as f:
    sp_data = f.read()

with open(sys.argv[1]+".pgz", "wb") as f:
    f.write(pgz_header)
    f.write(data)
    f.write(sp_header)
    f.write(sp_data)
    f.write(pgz_footer)


