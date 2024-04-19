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

## 上传dts文件到linux仓库

> 只适用于SunFounder员工。Only for SunFounder Employees。

```bash
# 克隆SunFounder的linux仓库
git clone git@github.com:sunfounder/linux.git
cd linux
# 增加Raspberry Pi的linux仓库为上游
git remote add upstream https://github.com/raspberrypi/linux.git
```

确认当前分支是最新的活跃分支。直接访问https://github.com/raspberrypi/linux，看分支是哪个，哪个就是活跃分支。确定了活跃分之后，你可能需要先切换到活跃分支。如rpi-6.6.y
```bash
# 切换到活跃分支 （你可能需要修改分支名）
git checkout rpi-6.6.y
# 拉取上游的最新代码 （你可能需要修改分支名）
git pull upstream rpi-6.6.y
```

现在你需要复制你的dts文件到linux仓库中，把dts文件放到`arch/arm/boot/dts/overlays/`目录下。

修改Makefile（`arch\arm\boot\dts\overlays\Makefile`）, 让他可以被一起编译，注意要严格按照字母顺序排列。并且，写入的应该是输出的dtbo文件名。

```diff
    ...
	ssd1306-spi.dtbo \
	ssd1331-spi.dtbo \
	ssd1351-spi.dtbo \
+	sunfounder-pironman5.dtbo \
	superaudioboard.dtbo \
	sx150x.dtbo \
	tc358743.dtbo \
	tc358743-audio.dtbo \
    ...
```

修改Readme文件（`arch\arm\boot\dts\overlays\README`），添加你的overlay的说明。注意只能使用空格，不能用TAB，格式要完全和其他的一样。每一段要和上下之间各隔两行。

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
+    
+    
+    Name:   sunfounder-pironman5
+    Info:   Overlay for SunFounder Pironman 5
+    Load:   dtoverlay=sunfounder-pironman5,<param>=<val>
+    Params: ir                      Enable IR or not (on or off, default on)
+            ir_pins                 Change IR receiver pin (default 12)
+    
+    
    Name:   superaudioboard
    Info:   Configures the SuperAudioBoard sound card
    Load:   dtoverlay=superaudioboard,<param>=<val>
    Params: gpiopin                 GPIO pin for codec reset
    
    
    ...
```

修改完了以后，提交到SunFounder的linux仓库。

> [!IMPORTANT]
> 注意，再Windows下可能会产生一些莫名的变更，这些变更可能会无法取消，**请务必不要提交这些变更**。只需要提交dts， Makefile以及README文件的变更。

```bash
# 添加你的dts文件到git （你可能需要修改文件名）
git add arch/arm/boot/dts/overlays/sunfounder-pironman5-overlay.dts arch/arm/boot/dts/overlays/Makefile arch/arm/boot/dts/overlays/README
# 提交你的dts文件 （你可能需要修改提交信息）
git commit -m "Add SunFounder Pironman 5 overlay"
# 推送你的dts文件到SunFounder的linux仓库 （你可能需要修改分支名）
git push origin rpi-6.1.y
```

提交Pull Request
1. 转到[仓库的Pull requests页面](https://github.com/sunfounder/linux/pulls)
2. 点击 **New pull requests**。
3. 在 **Comparing changes** 页面，确认自己要上传的修改有没有问题，点击 **Create pull request**。
4. 在 **Open a pull request** 页面，填写标题和描述，然后点击 提交。
5. 等待审核通过，可以留意自己的邮箱，或者到[树莓派Linux仓库的Pull requests页面](https://github.com/raspberrypi/linux/pulls)找到自己提交的PR，确认情况。可能会有不合规的情况，需要修改后再次提交。

如果PR被拒绝了，一般是有什么问题没有解决，可以根据反馈修改，重新push到自己的分支，PR会自动更新。在PR页面可以看到更新的情况。

提交完成后，你最好把我们叉过来的分支也同步一下，这样以后再提交PR的时候就不会有冲突了。

```bash
# 同步远程仓库（你可能需要修改分支名）
git pull upstream rpi-6.6.y
# 推送到自己的分支（你可能需要修改分支名）
git push origin rpi-6.6.y
```

这样就完成啦