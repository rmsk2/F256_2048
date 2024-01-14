import sys

pgx_header = bytes([80, 71, 88, 3, 00, 0x25, 0, 0])

with open(sys.argv[1], "rb") as f:
    data = f.read()

with open(sys.argv[1]+".pgx", "wb") as f:
    f.write(pgx_header)
    f.write(data)


