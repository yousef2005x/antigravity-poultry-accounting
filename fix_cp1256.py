"""
Fix double-encoded Arabic text in Dart files.

The text was originally UTF-8 bytes but was incorrectly read as Windows-1256 (cp1256)
and then saved as UTF-8.

For example:
"ا" (alef) = UTF-8 bytes d8 a7. 
In cp1256: d8 = "ط", a7 = "§". 
So it became "ط§".

This script reverses the process for all Dart files.
"""

import os
import sys

def fix_cp1256_double_encoding(text):
    """
    Reverses the cp1256 -> utf8 double encoding.
    """
    try:
        # Step 1: Encode the garbled string back to cp1256 bytes
        # Some characters might not map cleanly if they were modified by the editor,
        # so we use a safe approach by handling exceptions or replacing.
        raw_bytes = text.encode('cp1256')
        
        # Step 2: Decode the recovered bytes as UTF-8
        fixed_text = raw_bytes.decode('utf-8')
        return fixed_text
    except Exception as e:
        return None

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
                
                try:
                    with open(fpath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Check if the file has typical garbled text like "ط§ظ„" (al-)
                    if 'ط§' in content or 'ظ„' in content or 'ط¨' in content:
                        
                        # We shouldn't convert the whole file at once because English text and code 
                        # will throw errors if they contain characters not in cp1256, or valid utf8 
                        # that isn't part of the double-encoded mess.
                        # Wait, cp1256 covers English (ASCII is 0-127). It's safe for ASCII!
                        # What if there are valid Arabic characters that were entered *after* the corruption?
                        # Let's try to convert line by line or string by string.
                        
                        fixed_lines = []
                        changed = False
                        
                        # Process line by line
                        for line in content.split('\n'):
                            # Only attempt fix if line has garbled indicators
                            if 'ط§' in line or 'ظ„' in line or 'ط¨' in line or 'ظ…' in line:
                                try:
                                    # This might fail if the line has mixed valid Arabic and garbled text
                                    # Or characters not in cp1256
                                    fixed_line = line.encode('cp1256').decode('utf-8')
                                    # Verify the fix produced valid Arabic
                                    if any('\u0600' <= c <= '\u06FF' for c in fixed_line):
                                        fixed_lines.append(fixed_line)
                                        changed = True
                                    else:
                                        fixed_lines.append(line)
                                except Exception:
                                    # Fall back to word-by-word replacement
                                    words = []
                                    line_changed = False
                                    for word in line.split(' '):
                                        if 'ط§' in word or 'ظ„' in word or 'ط¨' in word or 'ظ…' in word:
                                            try:
                                                fixed_w = word.encode('cp1256').decode('utf-8')
                                                words.append(fixed_w)
                                                line_changed = True
                                                changed = True
                                            except:
                                                words.append(word)
                                        else:
                                            words.append(word)
                                    fixed_lines.append(' '.join(words) if line_changed else line)
                            else:
                                fixed_lines.append(line)
                        
                        if changed:
                            # Reconstruct file content
                            new_content = '\n'.join(fixed_lines)
                            with open(fpath, 'w', encoding='utf-8', newline='') as f:
                                f.write(new_content)
                            fixed_count += 1
                            print(f"  FIXED: {os.path.relpath(fpath, lib_dir)}")
                except Exception as e:
                    print(f"  Error processing {fname}: {e}")
    
    print(f"\nDone! Scanned {scanned_count} files, fixed {fixed_count} files.")

if __name__ == '__main__':
    main()
