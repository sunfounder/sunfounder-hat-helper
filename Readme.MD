# SunFounder HAT+ helper

## helper.sh

Helper script to automate the process of creating eeprom files and device tree overlays.

### Usage:

```
bash helper.sh
```

follow the instructions to create eeprom files and device tree overlays. Once the files are created, they will be under the `eeproms` and `overlays` folders. with their name.

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

```
python3 ./scripts/create_dtoverlay.py 
```

robothat eeprom:
```
./bin/eepmake eeproms/o1903v12_robot_hat_5.txt eeproms/o1903v12_robot_hat_5.eep overlays/
```

pironman u1:
```
python3 create.py -i O1903V10 -n "Pironman U1" -d "sunfounder-pironmanu1.dtbo" -f
cd overlays
dtc -@ -Hepapr -I dts -O dtb -o sunfounder-pironmanu1.dtbo sunfounder-pironmanu1-overlay.dts
cd ..
./bin/eepmake eeproms/o1903v10_pironman_u1.txt eeproms/o1903v12_pironman_u1.eep
```

Compile dtbo
```
dtc -@ -Hepapr -I dts -O dtb -o robot-hat-5.dtbo robot-hat-5-overlay.dts
```

Enable i2c-9

```
sudo dtoverlay i2c-gpio i2c_gpio_sda=0 i2c_gpio_scl=1 bus=9
```

## 上传dts文件到linux仓库

> 只适用于SunFounder员工。Only for SunFounder Employees。

### 确认活跃分支
1. 打开linux仓库SunFounder的分支：[`sunfounder/linux`](https://github.com/sunfounder/linux)
2. 打开原仓库的分支：[`raspberrypi/linux`](https://github.com/raspberrypi/linux)
3. 确认两个仓库的主分支是一致的，如果不一致，需要先同步。如果一致就可以跳过这一步了
4. 打开仓库的设置页面：[`sunfounder/linux/settings`](https://github.com/sunfounder/linux/settings)
5. 在General选项卡中，找到Default branch，确认是最新的活跃分支，如果不是，修改为最新的活跃分支。

### 同步原仓库
1. 回到SunFounder的linux仓库：[`sunfounder/linux`](https://github.com/sunfounder/linux)
2. 在仓库信息对比一栏钟点击Sync fork下拉，选择Update branch
3. 等待提醒更新完成即可

### 上传dts文件
4. 打开到overlay的存放位置：[`arch/arm/boot/dts/overlays`](https://github.com/sunfounder/linux/tree/rpi-6.6.y/arch/arm/boot/dts/overlays)
5. 点击Add file -> Upload files
6. 上传你的dts文件，注意是dts，不是dtbo。
7. 填写commit信息，注意使用英文，如`Add SunFounder Pironman 5 overlay`
8. 点击**Commit changes...**，修改提交标题和详情，可以都写一样的，如：`Add SunFounder PiPower 3 overlay`
9. 点击**Commit**

### 修改Makefile
1. 打开这个Makefile：[`arch\arm\boot\dts\overlays\Makefile`](https://github.com/sunfounder/linux/blob/rpi-6.6.y/arch/arm/boot/dts/overlays/Makefile)
2. 选择编辑这个文件。
3. 找到文件中其他sunfounder的overlay，按照字母顺序排列，添加你的overlay的文件名。
    > 注意末尾要添加空格反斜杠。
    > 一定要注意按照字母顺序，提交审查会很严格

    ```diff
        ...
        ssd1306-spi.dtbo \
        ssd1331-spi.dtbo \
        ssd1351-spi.dtbo \
    +   sunfounder-pipower3 \
    	sunfounder-pironman5.dtbo \
        superaudioboard.dtbo \
        sx150x.dtbo \
        tc358743.dtbo \
        tc358743-audio.dtbo \
        ...
    ```
4. 点击**Commit changes...**，修改提交标题和详情，可以都写一样的，如：`Add SunFounder PiPower 3 overlay to Makefile`
5. 点击**Commit**

### 修改README

1. 打开这个README文件：[`arch\arm\boot\dts\overlays\README`](https://github.com/sunfounder/linux/blob/rpi-6.6.y/arch/arm/boot/dts/overlays/README)
2. 选择编辑这个文件。
3. 找到文件中其他sunfounder的overlay，按照字母顺序排列，添加你的overlay的说明。注意只能使用空格，不能用TAB，格式要完全和其他的一样。每一段要和上下之间各隔两行。

    ```diff
        ...
        
        
        Name:   ssd1351-spi
        Info:   Overlay for SSD1351 OLED via SPI using fbtft staging driver.
        Load:   dtoverlay=ssd1351-spi,<param>=<val>
        Params: speed                   SPI bus speed (default 4500000)
                rotate                  Display rotation (0, 90, 180 or 270; default 0)
                fps                     Delay between frame updates (default 25)
                debug                   Debug output level (0-7; default 0)
                dc_pin                  GPIO pin for D/C (default 24)
                reset_pin               GPIO pin for RESET (default 25)
         
         
        Name:   sunfounder-pironman5
        Info:   Overlay for SunFounder Pironman 5
        Load:   dtoverlay=sunfounder-pironman5,<param>=<val>
        Params: ir                      Enable IR or not (on or off, default on)
                ir_pins                 Change IR receiver pin (default 12)
        
    +   Name:   sunfounder-pipower3
    +   Info:   Overlay for SunFounder PiPower 3
    +   Load:   dtoverlay=sunfounder-pipower3,<param>=<val>
    +   Params: poweroff_pin            Change poweroff pin (default 26)
        
        
        Name:   superaudioboard
        Info:   Configures the SuperAudioBoard sound card
        Load:   dtoverlay=superaudioboard,<param>=<val>
        Params: gpiopin                 GPIO pin for codec reset
        
        
        ...
    ```
4. 点击**Commit changes...**，修改提交标题和详情，可以都写一样的，如：`Add SunFounder PiPower 3 overlay to README`
5. 点击**Commit**

### 提交Pull Request
1. 转到[仓库的Pull requests页面](https://github.com/sunfounder/linux/pulls)
2. 点击 **New pull requests**。
3. 在 **Comparing changes** 页面，确认自己要上传的修改有没有问题，点击 **Create pull request**。
4. 在 **Open a pull request** 页面，填写标题和描述，如：
    - 标题：Add SunFounder PiPower 3 dtoverlay
    - 描述：Add SunFounder PiPower 3 dtoverlay
    - 然后点击**Create pull request**。
5. 等待审核通过，可以留意自己的邮箱，或者到[树莓派Linux仓库的Pull requests页面](https://github.com/raspberrypi/linux/pulls)找到自己提交的PR，确认情况。可能会有不合规的情况，需要修改后再次提交。

如果PR被拒绝了，一般是有什么问题没有解决，可以根据反馈修改，重新push到自己的分支，PR会自动更新。在PR页面可以看到更新的情况。

提交完成后，最好重新按照上面[同步原仓库](#同步原仓库)的步骤，保持自己的分支是最新的。

这样就完成啦