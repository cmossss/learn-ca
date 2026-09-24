#!/usr/bin/env python3
"""把 objcopy 出来的裸二进制转成 $readmemh 能吃的 hex 文件。

$readmemh 按「每行一个 16 进制数」读，数的位宽由目标数组的元素位宽决定
（tb 里 imem 是 logic [31:0]，所以每行 8 个 hex 字符）。

RISC-V 是小端：二进制文件里每个 32-bit 字是低字节在前。
打印时按字反转字节序，是因为 $readmemh 把每行的 hex 当成一个「数」，
而数的数值 = 大端读法。两者叠加正好还原。

用法：
    python3 bin2hex.py prog.bin prog.hex
"""

import argparse
import pathlib
import sys


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src", help="objcopy -O binary 产出的 .bin")
    ap.add_argument("dst", help="要写出的 .hex")
    ap.add_argument("--word-bytes", type=int, default=4,
                    help="每个字的字节数，默认 4（RV32）")
    args = ap.parse_args()

    data = pathlib.Path(args.src).read_bytes()
    if not data:
        print(f"ERROR: {args.src} 是空文件", file=sys.stderr)
        return 1

    # 补齐到整字
    pad = (-len(data)) % args.word_bytes
    if pad:
        data += b"\x00" * pad

    lines = []
    for i in range(0, len(data), args.word_bytes):
        word = data[i:i + args.word_bytes]
        lines.append("".join(f"{b:02x}" for b in reversed(word)))

    pathlib.Path(args.dst).write_text("\n".join(lines) + "\n")
    print(f"  bin2hex: {len(lines)} words ({len(data)} bytes) -> {args.dst}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
