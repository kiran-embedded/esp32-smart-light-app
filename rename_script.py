import os

base_dir = '/home/kirancybergrid/Documents/esp32-smart-light-app-1.2.0-15/lib'

# 1. Rename files
for root, dirs, files in os.walk(base_dir):
    for file in files:
        if 'nebula' in file:
            old_path = os.path.join(root, file)
            new_name = file.replace('nebula', 'aurexa')
            new_path = os.path.join(root, new_name)
            os.rename(old_path, new_path)
            print(f"Renamed {old_path} to {new_path}")

# 2. Search and replace inside files
for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r') as f:
                content = f.read()
            
            if 'Nebula' in content or 'nebula' in content or 'NEBULA' in content:
                content = content.replace('Nebula', 'Aurexa')
                content = content.replace('nebula', 'aurexa')
                content = content.replace('NEBULA', 'AUREXA')
                with open(path, 'w') as f:
                    f.write(content)
                print(f"Updated content in {path}")
