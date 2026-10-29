#!/usr/bin/env python3
"""Obfuscate sensitive Swift string literals in the CI working copy."""

from pathlib import Path
import re


source_path = Path("JMComic/AppConfig.swift")
source = source_path.read_text(encoding="utf-8")
pattern = re.compile(r'static let apiBaseURL = "([^"]+)"')
match = pattern.search(source)
if match is None:
    raise SystemExit("AppConfig.apiBaseURL string literal was not found")

plain_value = match.group(1)
key = 0xA7
encoded_bytes = ", ".join(f"0x{byte ^ key:02X}" for byte in plain_value.encode("utf-8"))
replacement = f"""private static let apiObfuscationKey: UInt8 = 0x{key:02X}
    private static let apiBaseURLBytes: [UInt8] = [
        {encoded_bytes}
    ]

    static var apiBaseURL: String {{
        String(decoding: apiBaseURLBytes.map {{ $0 ^ apiObfuscationKey }}, as: UTF8.self)
    }}"""

obfuscated, replacements = pattern.subn(lambda _: replacement, source, count=1)
if replacements != 1 or plain_value in obfuscated:
    raise SystemExit("API string obfuscation did not produce the expected source")

source_path.write_text(obfuscated, encoding="utf-8")
artifacts = Path("artifacts")
artifacts.mkdir(exist_ok=True)
(artifacts / "obfuscation-report.txt").write_text(
    "Obfuscation scope\n"
    "- AppConfig.apiBaseURL: XOR byte encoding with runtime restoration\n"
    "- Release binary: symbol stripping and dead-code stripping\n"
    "- Swift class, method, and property identifiers are not renamed\n",
    encoding="utf-8",
)
print("Sensitive API string obfuscated; original source value removed from AppConfig.swift")
