import sys

def generate_asm(in_file, out_file, col_label):
    with open(in_file, "r") as f:
        lines = f.readlines()

    col = col_label
    data = lines[5:]

    with open(out_file, "w") as f:
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

files = [("2.xpm", "C1"), ("4.xpm", "C2"), ("8.xpm", "C3"), ("16.xpm", "C4"), ("32.xpm", "C5"), 
         ("64.xpm", "C6"), ("128.xpm", "C7"), ("256.xpm", "C8"), ("512.xpm", "C9"), ("1024.xpm", "CA"), 
         ("2048.xpm", "CB"), ("4096.xpm", "CC"), ("8192.xpm", "CD")]

for i in files:
    asm_name = (i[0][0:-3]) + "asm"
    generate_asm(i[0], asm_name, i[1])
    