
import struct, os

max_current = None
product = None
product_id = None
product_ver = None
pcb_id = None
vendor = None
product_uuid = None

if not os.path.exists("/proc/device-tree/hat"):
    print("Hat is not detected")
    exit(1)
if not os.path.exists("/proc/device-tree/chosen/power/max_current"):
    print("Max Current is not set")
else:
    with open("/proc/device-tree/chosen/power/max_current", "rb") as f:
        max_current = f.read()
        max_current = struct.unpack(">I", max_current)[0]

with open("/proc/device-tree/hat/product", "r") as f:
    product = f.read()
    print(f"product: {product}")

with open("/proc/device-tree/hat/product_id", "r") as f:
    product_id = f.read()[:-1]
    product_id = int(product_id, 16)

with open("/proc/device-tree/hat/product_ver", "r") as f:
    product_ver = f.read()[:-1]
    product_ver = int(product_ver, 16)

pcb_id = f"P{product_id:04d}V{product_ver:02d}"
print(f"pcb_id: {pcb_id}")
    
with open("/proc/device-tree/hat/vendor", "r") as f:
    vendor = f.read()
print(f"vendor: {vendor}")

with open("/proc/device-tree/hat/uuid", "r") as f:
    product_uuid = f.read()
print(f"product_uuid: {product_uuid}")

