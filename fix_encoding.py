"""
Fix double-encoded UTF-8 Arabic text in Dart files.

The issue: Arabic text was encoded as UTF-8, then the bytes were
misinterpreted as Windows-1252 (Latin-1) and re-encoded as UTF-8.
This script reverses the process: decode as UTF-8, encode as Latin-1
(to get back the original UTF-8 bytes), then decode as UTF-8 again.
"""

import os
import sys

def fix_double_encoded_utf8(text):
    """
    Fix double-encoded UTF-8 text.
    The text was: Arabic -> UTF-8 bytes -> misread as cp1252 -> re-encoded as UTF-8
    To fix: UTF-8 decode -> encode as cp1252 -> decode as UTF-8
    """
    result = []
    i = 0
    chars = list(text)
    
    while i < len(chars):
        # Try to find sequences of characters that look like double-encoded UTF-8
        # These will be characters in the range U+0080 to U+00FF (Latin-1 supplement)
        # and some Windows-1252 specific characters
        
        # Collect a run of potentially double-encoded characters
        run_start = i
        run_chars = []
        
        while i < len(chars):
            cp = ord(chars[i])
            # Characters that are part of double-encoded UTF-8:
            # - U+0080 to U+00FF (Latin-1 supplement range)
            # - Some Windows-1252 specific chars (U+2013, U+2014, U+2018, etc)
            # - Arabic characters in Windows-1252 mapped range
            cp1252_chars = {
                0x2013: 0x96, 0x2014: 0x97, 0x2018: 0x91, 0x2019: 0x92,
                0x201A: 0x82, 0x201C: 0x93, 0x201D: 0x94, 0x201E: 0x84,
                0x2020: 0x86, 0x2021: 0x87, 0x2022: 0x95, 0x2026: 0x85,
                0x2030: 0x89, 0x2039: 0x8B, 0x203A: 0x9B, 0x20AC: 0x80,
                0x0152: 0x8C, 0x0153: 0x9C, 0x0160: 0x8A, 0x0161: 0x9A,
                0x0178: 0x9F, 0x0192: 0x83, 0x02C6: 0x88, 0x02DC: 0x98,
                0x0679: 0x8F, 0x067E: 0x9D, 0x06BE: 0x9E, 0x061B: 0x9A,
                0x060C: 0x8D,
            }
            
            if 0x00A0 <= cp <= 0x00FF:
                run_chars.append(cp)
                i += 1
            elif cp in cp1252_chars:
                run_chars.append(cp1252_chars[cp])
                i += 1
            else:
                break
        
        if run_chars and len(run_chars) >= 2:
            # Try to decode the run as UTF-8
            try:
                byte_seq = bytes(run_chars)
                decoded = byte_seq.decode('utf-8')
                # Check if the result contains actual Arabic or meaningful chars
                has_arabic = any(0x0600 <= ord(c) <= 0x06FF for c in decoded)
                if has_arabic:
                    result.append(decoded)
                else:
                    # Not Arabic, keep original
                    result.append(text[run_start:i])
            except (UnicodeDecodeError, ValueError):
                # Can't decode as UTF-8, keep original
                result.append(text[run_start:i])
        elif run_chars:
            # Too short to be double-encoded, keep original
            result.append(text[run_start:i])
        else:
            result.append(chars[i])
            i += 1
    
    return ''.join(result)


def process_file(filepath):
    """Process a single file and fix double-encoded text."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except UnicodeDecodeError:
        print(f"  SKIP (not valid UTF-8): {filepath}")
        return False
    
    # Quick check: does the file contain potential double-encoded chars?
    # Look for the telltale pattern of Arabic double-encoding
    has_suspect = False
    for ch in content:
        cp = ord(ch)
        if 0x00A0 <= cp <= 0x00FF:
            has_suspect = True
            break
        if cp in (0x2013, 0x2014, 0x2018, 0x2019, 0x201A, 0x201C, 0x201D, 
                  0x201E, 0x2020, 0x2021, 0x2022, 0x2026, 0x2030, 0x2039, 
                  0x203A, 0x20AC, 0x0152, 0x0153, 0x0160, 0x0161, 0x0178,
                  0x0192, 0x02C6, 0x02DC, 0x0679, 0x067E, 0x06BE, 0x061B, 0x060C):
            has_suspect = True
            break
    
    if not has_suspect:
        return False
    
    fixed = fix_double_encoded_utf8(content)
    
    if fixed != content:
        with open(filepath, 'w', encoding='utf-8', newline='') as f:
            f.write(fixed)
        return True
    return False


def main():
    lib_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lib')
    
    fixed_count = 0
    scanned_count = 0
    
    for root, dirs, files in os.walk(lib_dir):
        # Skip hidden directories
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        for fname in files:
            if fname.endswith('.dart'):
                fpath = os.path.join(root, fname)
                scanned_count += 1
                if process_file(fpath):
                    fixed_count += 1
                    print(f"  FIXED: {os.path.relpath(fpath, lib_dir)}")
    
    print(f"\nDone! Scanned {scanned_count} files, fixed {fixed_count} files.")


if __name__ == '__main__':
    main()
