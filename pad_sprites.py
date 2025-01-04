import sys

BLOCK_LEN = 8192

num_blocks = 2

with open(sys.argv[1], "rb") as f:
    data = f.read()

bytes_left = (num_blocks * BLOCK_LEN) - len(data)

if bytes_left < 0:
    print("Binary is too large. We need another 8K block. Adapt this program and the loader")
    sys.exit(42)

print(f"Bytes left in last 8K block: {bytes_left}")

end_pad = bytearray(BLOCK_LEN)
data = data + end_pad[0:(num_blocks * BLOCK_LEN) - len(data)]

with open("sprites.dat", "wb") as f:
    f.write(data)
    