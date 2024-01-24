import sys

if len(sys.argv) < 4:
    print("usage: xpm2t64.py <infile> <outfile> <col_label> <skip_empty>")
    print()
    print("if <skip_empty> is present only the lines cotaining data are")
    print("written to the output file.")
    sys.exit()

with open(sys.argv[1], "r") as f:
    lines = f.readlines()

col = sys.argv[3]
data = lines[5:]

if len(sys.argv) >= 5:
    data = data[8:]
    data = data[:15]

with open(sys.argv[2], "w") as f:
    for l in data:
        res = ".byte "
        d = list(filter(lambda x: (x == ' ') or (x == '.'), l.rstrip()))
        
        for c in d:
            if c != '.':
                res += f"{col}, "
            else:
                res += f"$00, "
        
        res = res[:len(res)-2] + '\n'
        f.write(res)
    