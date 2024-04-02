#!/usr/bin/env python3

# usage: create -i O1903V12 -n 'Robot Hat 5" -d "hifiberry-dac" -c "custom data"

import argparse
import os
import shutil
import stat

script_directory = os.path.dirname(os.path.abspath(__file__))
EEPMAKE = os.path.join(script_directory, "eepmake")
EEPROM_DIR = os.path.join(script_directory, "../eeproms")

parser = argparse.ArgumentParser(description='Create a new hat+ eeprom')
parser.add_argument('-i', '--id', help='Product ID, ie: P1903V12')
parser.add_argument('-n', '--name', help='Hat name')
parser.add_argument('-v', '--vendor', default="SunFounder", help='Hat vendor')
parser.add_argument('-d', '--device-tree', help='Device tree overlay, ie: hifiberry-dac')
parser.add_argument('-c', '--custom-data', help='Custom data')
parser.add_argument('-f', '--force', action='store_true', help='Force overwrite')
parser.add_argument('-l', '--less', action='store_true', help='Less output')

args = parser.parse_args()

def read_arg(arg, prompt, allow_empty=False):
    while True:
        if arg != None and (allow_empty or len(arg) > 0):
            return arg
        arg = input(prompt)

id = read_arg(args.id, "Enter Product ID(ie P1903V12): ")
name = read_arg(args.name, "Enter Hat name: ")
if args.id == None:
    device_tree = read_arg(args.device_tree, "Enter device tree overlay: ", allow_empty=True)
    custom_data = read_arg(args.custom_data, "Enter custom data: ", allow_empty=True)
else:
    device_tree = args.device_tree
    custom_data = args.custom_data
if device_tree == None:
    device_tree = ""
if custom_data == None:
    custom_data = ""

filename = f"{id.lower()}_{name.replace(' ', '_').lower()}"
txt_filename = filename + ".txt"
product_id = int(id[1:5])
product_ver = int(id[6:])
product_uuid = f"9daeea78-0000-{product_id:04x}-{product_ver:04x}-582369ac3e02"

eeprom_data = f"""product_uuid {product_uuid}
product_id 0x{product_id:04x}
product_ver 0x{product_ver:04x}
vendor "{args.vendor}"
product "{name}"
"""

if device_tree != None and len(device_tree) > 0:
    eeprom_data += f'dt_blob "{device_tree}"\n'
if custom_data != None and len(custom_data) > 0:
    eeprom_data += f'custom_data "{custom_data}"\n'

if not args.less:
    print(eeprom_data)

if os.path.exists(txt_filename) and not args.force:
    force = input(f"File {txt_filename} exists, overwrite? (y/N): ")
    if force != "y":
        exit(1)
with open(txt_filename, 'w') as f:
    f.write(eeprom_data)

if not os.access(EEPMAKE, os.X_OK):
    if not args.less:
        print(f"{EEPMAKE} is not executable, adding execute permission.")
    # 添加可执行权限
    st = os.stat(EEPMAKE)
    os.chmod(EEPMAKE, st.st_mode | stat.S_IEXEC)

eep_filename = filename + ".eep"
make_command = f"{EEPMAKE} {txt_filename} {eep_filename}"

os.system(make_command)

shutil.move(eep_filename, f"{EEPROM_DIR}/{eep_filename}")
shutil.move(txt_filename, f"{EEPROM_DIR}/{txt_filename}")

if not args.less:
    print(f"Created :\n  {EEPROM_DIR}/{eep_filename}\n  {EEPROM_DIR}/{txt_filename}")
else:
    print(eep_filename)