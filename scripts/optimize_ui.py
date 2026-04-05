import os
import re

def optimize_ui_performance(directory):
    print(f"🚀 Starting global UI optimization in: {directory}")
    
    # regex for Duration(milliseconds: X) where X > 200
    duration_regex = re.compile(r'const Duration\(milliseconds: ([3-9][0-9]{2}|[1-9][0-9]{3})\)')
    # regex for X.ms where X > 200
    ms_regex = re.compile(r'([3-9][0-9]{2}|[1-9][0-9]{3})\.ms')
    # regex for Duration(seconds: X) where X > 0 (for short animations)
    sec_regex = re.compile(r'const Duration\(seconds: [1-9]\)')
    
    modified_files = 0
    
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    content = f.read()
                
                original_content = content
                
                # 1. Speed up heavy animations to 150ms (snappy feel)
                content = duration_regex.sub('const Duration(milliseconds: 150)', content)
                content = ms_regex.sub('150.ms', content)
                
                # 2. Fix potential layout overflows (conservative adjustment)
                content = re.sub(r'Responsive\.paddingBottom \+ 20', 'Responsive.paddingBottom + 12', content)
                content = re.sub(r'Responsive\.paddingBottom \+ 24', 'Responsive.paddingBottom + 12', content)
                
                # 3. Clean up ghost shadows (potential bleeding sources)
                content = re.sub(r'boxShadow: \[.*BoxShadow\(.*spreadRadius: [1-9].*\]', 'boxShadow: []', content, flags=re.DOTALL)

                if content != original_content:
                    with open(filepath, 'w') as f:
                        f.write(content)
                    print(f"✅ Optimized: {file}")
                    modified_files += 1

    print(f"✨ DONE! Optimized {modified_files} files.")

if __name__ == "__main__":
    optimize_ui_performance('lib')
