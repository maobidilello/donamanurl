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
_, _, symoff, nsyms, stroff, strsize = symtab
if symoff + nsyms * 16 > len(executable) or stroff + strsize > len(executable):
    raise SystemExit("Mach-O symbol data exceeds the executable size")

local_symbols = 0
debug_symbols = 0
linker_markers = 0
remaining = []
for index in range(nsyms):
    entry_offset = symoff + index * 16
    n_strx, n_type, _, _, _ = struct.unpack_from("<IBBHQ", executable, entry_offset)
    if n_strx < strsize:
        end = executable.find(b"\0", stroff + n_strx, stroff + strsize)
        name = bytes(executable[stroff + n_strx:end]).decode("utf-8", "replace")
    else:
        name = "<invalid string index>"

    # Apple's strip preserves this ld64 compatibility marker at symbol index zero.
    is_linker_marker = (
        index == 0
        and n_type == 0x3C
        and name.startswith("radr://")
        and name[7:].isdigit()
    )
    if is_linker_marker:
        linker_markers += 1
        continue

    is_debug = bool(n_type & 0xE0)  # N_STAB debugging symbols
    is_local = not n_type & 0x01  # N_EXT external/dynamic symbols must remain
    if is_debug:
        debug_symbols += 1
    if is_local:
        local_symbols += 1
    if is_debug or is_local:
        remaining.append(f"index={index},type=0x{n_type:02X},name={name!r}")

if debug_symbols or local_symbols:
    details = "; ".join(remaining[:10])
    raise SystemExit(
        f"Symbols were not stripped as expected: debug={debug_symbols}, "
        f"local={local_symbols}; {details}"
    )

print(
    f"Release verification passed: no plain API URL; no app debug/local symbols; "
    f"{linker_markers} Apple linker marker and {nsyms - linker_markers} dynamic symbols retained"
)
