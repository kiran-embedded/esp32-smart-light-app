import os
import re

def polish_nebula_core():
    print("🌌 Initializing Nebula Polish Engine v5.0 (Definitive Purity Mode)...")
    
    # 1. Target MainScreen background blobs
    main_screen_path = 'lib/screens/main/main_screen.dart'
    if os.path.exists(main_screen_path):
        with open(main_screen_path, 'r') as f:
            content = f.read()
        
        # Remove the top and bottom Positioned blobs inside the Stack
        # We look for the comment-like patterns or the specific container structures
        content = re.sub(r'Positioned\(\s*top: -80,[\s\S]*?duration: 12\.seconds,[\s\S]*?\),[\s\S]*?\),', 'const SizedBox.shrink(),', content)
        content = re.sub(r'Positioned\(\s*bottom: -50,[\s\S]*?duration: 15\.seconds,[\s\S]*?\),[\s\S]*?\),', 'const SizedBox.shrink(),', content)
        
        # Fallback for the iOS-ish blobs if they exist
        content = re.sub(r'Positioned\(\s*top: -100,[\s\S]*?RadialGradient[\s\S]*?\),', 'const SizedBox.shrink(),', content)
        content = re.sub(r'Positioned\(\s*bottom: -150,[\s\S]*?RadialGradient[\s\S]*?\),', 'const SizedBox.shrink(),', content)

        with open(main_screen_path, 'w') as f:
            f.write(content)
        print(f"✨ Purified MainScreen: {main_screen_path}")

    # 2. Target Global Shadows in lib/widgets and lib/screens
    # We use a very broad regex to replace any 'boxShadow: [ ... ]' even with complex nested logic
    # We'll use a simple approach: find the start and then the closing bracket on the same level.
    
    def remove_box_shadows(file_content):
        # This regex matches the common patterns of boxShadow assignments
        # Use a non-greedy catch-all for the list structure, but we'll try to be safe.
        # Target: boxShadow: [ ... ], or boxShadow: someCondition ? ... : ...,
        # We replace with BoxDecoration's boxShadow: const [],
        modified = re.sub(r'boxShadow: (?:ref\.watch\(performanceProvider\)\s*\?\s*\[\]\s*:\s*)?\[[\s\S]*?\]\s*(?=\s*[,\)])', 'boxShadow: const []', file_content)
        return modified

    modified_count = 0
    for root, _, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                
                new_content = remove_box_shadows(content)
                
                if new_content != content:
                    with open(path, 'w') as f:
                        f.write(new_content)
                    print(f"✨ Purified: {path}")
                    modified_count += 1
                    
    print(f"🏁 System Purification Complete! {modified_count} files reached Absolute Purity.")

if __name__ == "__main__":
    polish_nebula_core()
