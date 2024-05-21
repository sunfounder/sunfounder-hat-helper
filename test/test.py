
import struct, os

hat_current_supply = None
max_current = None
product = None
product_id = None
product_ver = None
pcb_id = None
vendor = None
product_uuid = None
hat_path = None
for file in os.listdir('/proc/device-tree/'):
    if file.startswith('hat'):
        hat_path = f"/proc/device-tree/{file}"
        hat_type = 0
        if 'type' in file:
            hat_type = file.split('_type')[1]
        print(f"Hat is detected. type: {hat_type}")
        break

else:
    print("Hat is not detected")
    exit(1)
hat_current_supply_path="/proc/device-tree/chosen/power/hat_current_supply"
if not os.path.exists(hat_current_supply_path):
    print("Hat Current Supply is not set")
else:
    with open(hat_current_supply_path, "rb") as f:
        hat_current_supply = f.read()
        hat_current_supply = struct.unpack(">I", hat_current_supply)[0]
        print(f"Hat Current Supply: {hat_current_supply}mA")

if not os.path.exists("/proc/device-tree/chosen/power/max_current"):
    print("Max Current is not set")
else:
    with open("/proc/device-tree/chosen/power/max_current", "rb") as f:
        max_current = f.read()
        max_current = struct.unpack(">I", max_current)[0]
        print(f"Max Current: {max_current}mA")

with open(f"{hat_path}/product", "r") as f:
    product = f.read()
    print(f"Product: {product}")

with open(f"{hat_path}/product_id", "r") as f:
    product_id = f.read()[:-1]
    product_id = int(product_id, 16)

with open(f"{hat_path}/product_ver", "r") as f:
    product_ver = f.read()[:-1]
    product_ver = int(product_ver, 16)

pcb_id = f"P{product_id:04d}V{product_ver:02d}"
print(f"Product ID: {pcb_id}")
    
with open(f"{hat_path}/vendor", "r") as f:
    vendor = f.read()
print(f"Vendor: {vendor}")

with open(f"{hat_path}/uuid", "r") as f:
    product_uuid = f.read()
print(f"Product UUID: {product_uuid}")

