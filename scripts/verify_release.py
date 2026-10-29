#!/usr/bin/env python3
"""Verify release-string obfuscation and Mach-O symbol stripping."""

from pathlib import Path
import struct
import sys


if len(sys.argv) != 2:
    raise SystemExit("Usage: verify_release.py <app-executable>")

executable = Path(sys.argv[1]).read_bytes()
plain_url = b"https://dm.kingome.shop/api"
if plain_url in executable:
    raise SystemExit("Plain API URL is still present in the executable")

if len(executable) < 32:
    raise SystemExit("Executable is too small to be a Mach-O file")
magic, _, _, _, ncmds, _, _, _ = struct.unpack_from("<IiiIIIII", executable, 0)
if magic != 0xFEEDFACF:
    raise SystemExit("Expected a 64-bit little-endian Mach-O executable")

offset = 32
symtab = None
for _ in range(ncmds):
    if offset + 8 > len(executable):
        raise SystemExit("Mach-O load commands exceed the executable size")
    cmd, cmdsize = struct.unpack_from("<II", executable, offset)
    if cmdsize < 8 or offset + cmdsize > len(executable):
        raise SystemExit("Invalid Mach-O load command size")
    if cmd == 0x2:  # LC_SYMTAB
        symtab = struct.unpack_from("<IIIIII", executable, offset)
    offset += cmdsize

if symtab is None:
    raise SystemExit("Mach-O symbol table is missing")
_, _, symoff, nsyms, _, _ = symtab
if symoff + nsyms * 16 > len(executable):
    raise SystemExit("Mach-O symbol entries exceed the executable size")

local_symbols = 0
debug_symbols = 0
for index in range(nsyms):
    entry_offset = symoff + index * 16
    _, n_type, _, _, _ = struct.unpack_from("<IBBHQ", executable, entry_offset)
    if n_type & 0xE0:  # N_STAB debugging symbols
        debug_symbols += 1
    if not n_type & 0x01:  # N_EXT external/dynamic symbols must remain
        local_symbols += 1

if debug_symbols or local_symbols:
    raise SystemExit(
        f"Symbols were not stripped as expected: debug={debug_symbols}, local={local_symbols}"
    )

print(
    f"Release verification passed: no plain API URL; no debug/local symbols; "
    f"{nsyms} required dynamic symbols retained"
)
