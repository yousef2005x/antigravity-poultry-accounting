import os

lib_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lib')
count = 0

for root, dirs, files in os.walk(lib_dir):
    for fname in files:
        if fname.endswith('.dart'):
            fpath = os.path.join(root, fname)
            try:
                with open(fpath, 'r', encoding='utf-8') as f:
                    content = f.read()
                if 'â‚ھ' in content:
                    content = content.replace('â‚ھ', '₪')
                    with open(fpath, 'w', encoding='utf-8', newline='') as f:
                        f.write(content)
                    count += 1
            except Exception as e:
                pass

print(f"Fixed {count} files with currency symbol")
