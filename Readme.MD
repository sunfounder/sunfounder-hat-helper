# SunFounder HAT+ helper

## EEPROM:

Create a eeprom file for a product
```
python3 create.py -i O1903V10 -n "Pironman U1" -d "sunfounder-pironmanu1.dtbo" -f
```
This command will create a eeprom file and a source txt file in the eeproms folder

`product_uuid` follows the format: `9daeea78-0000-<product-id>-<product-version>-582369ac3e02`
`product_id` is hex from SunFounder PCB ID `O<product-id>V<product-version>`
`product_version` is hex from SunFounder PCB ID `O<product-id>V<product-version>`
`vendor` is default to `SunFounder`, can be changed with `-v` option
`product` is the input parameter `-n`
`dt_blob` (optional) is the input parameter `-d`
`custom_data` (optional) is the input parameter `-c`
`-f` will force overwrite the eeprom file

## Device Tree Overlay:

python3 ./scripts/create_dtoverlay.py 

robothat eeprom:
./bin/eepmake eeproms/o1903v12_robot_hat_5.txt eeproms/o1903v12_robot_hat_5.eep overlays/

pironman u1:
python3 create.py -i O1903V10 -n "Pironman U1" -d "sunfounder-pironmanu1.dtbo" -f
cd overlays
dtc -@ -Hepapr -I dts -O dtb -o sunfounder-pironmanu1.dtbo sunfounder-pironmanu1-overlay.dts
cd ..
./bin/eepmake eeproms/o1903v10_pironman_u1.txt eeproms/o1903v12_pironman_u1.eep

Compile dtbo
dtc -@ -Hepapr -I dts -O dtb -o robot-hat-5.dtbo robot-hat-5-overlay.dts

Enable i2c-9
sudo dtoverlay i2c-gpio i2c_gpio_sda=0 i2c_gpio_scl=1 bus=9

