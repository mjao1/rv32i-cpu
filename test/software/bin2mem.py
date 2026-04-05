#!/usr/bin/env python3
"""Convert raw binary (little-endian) to Verilog $readmemh lines (one 32-bit word per line)."""
import sys

PAD_WORDS_DEFAULT = 1024


def main():
    if len(sys.argv) < 3:
        print("usage: bin2mem.py <input.bin> <output.mem> [pad_words]", file=sys.stderr)
        sys.exit(1)
    pad = PAD_WORDS_DEFAULT
    if len(sys.argv) >= 4:
        pad = int(sys.argv[3])
    with open(sys.argv[1], "rb") as f:
        data = f.read()
    padb = (4 - len(data) % 4) % 4
    data += b"\x00" * padb
    words = []
    for i in range(0, len(data), 4):
        w = (
            data[i]
            | (data[i + 1] << 8)
            | (data[i + 2] << 16)
            | (data[i + 3] << 24)
        )
        words.append(w)
    while len(words) < pad:
        words.append(0)
    with open(sys.argv[2], "w") as out:
        for w in words:
            out.write(f"{w:08x}\n")


if __name__ == "__main__":
    main()
