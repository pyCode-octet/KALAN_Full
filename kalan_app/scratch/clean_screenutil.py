import os
import re

def clean_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove import
    content = re.sub(r"import 'package:flutter_screenutil/flutter_screenutil.dart';\n?", "", content)
    
    # Replace .w, .h, .sp, .r, .v, .u
    # Regex looks for digits followed by one of these suffixes
    content = re.sub(r'(\d+)\.(w|h|sp|r|v|u)', r'\1', content)
    # Also handle decimals like 1.5.w
    content = re.sub(r'(\d+\.\d+)\.(w|h|sp|r|v|u)', r'\1', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    lib_path = r'c:\Users\angen\Documents\kalan\kalan_app\lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                clean_file(os.path.join(root, file))
                print(f'Cleaned: {file}')

if __name__ == '__main__':
    main()
