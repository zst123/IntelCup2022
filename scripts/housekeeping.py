import os
import shutil

# Check the current working directory
directory = os.getcwd()
print("Current directory:", directory)

# Remove preprocessing (new_data)
try:
    shutil.rmtree('./new_data')
except OSError as e:
    print("Error:", e.strerror)

# Remove old model (16kv_2.h5)
try:
    os.remove('16kv_2.h5')
except OSError as e:
    print("Error:", e.strerror)

# Remove old keywords (keywords.txt)
try:
    os.remove('../flutter_app/keywords.txt')
except OSError as e:
    print("Error:", e.strerror)

try:
    os.remove('./keywords.txt')
except OSError as e:
    print("Error:", e.strerror)

print("Done")