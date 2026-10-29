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
symtab_nsyms = None
for _ in range(ncmds):
    if offset + 8 > len(executable):
        raise SystemExit("Mach-O load commands exceed the executable size")
    cmd, cmdsize = struct.unpack_from("<II", executable, offset)
    if cmdsize < 8 or offset + cmdsize > len(executable):
        raise SystemExit("Invalid Mach-O load command size")
    if cmd == 0x2:  # LC_SYMTAB
        _, _, _, symtab_nsyms, _, _ = struct.unpack_from("<IIIIII", executable, offset)
    offset += cmdsize

if symtab_nsyms is None or symtab_nsyms != 0:
    raise SystemExit(f"Symbol table was not fully stripped: nsyms={symtab_nsyms}")

print("Release verification passed: no plain API URL; Mach-O symbol table is empty")
