#!/bin/bash

CONFIG_FILE="config.sh"
DEFAULT_EEPROM_FILE=""
DEFAULT_EEPROM_I2C_BUS="i2c-9"
DEFAULT_EEPROM_CHIP_TYPE="24c64"
DEFAULT_EEPROM_CHIP_ADDRESS="50"
DEFAULT_EEPROM_PCB_CODE=""
DEFAULT_PRODUCT_NAME=""
DEFAULT_VENDOR="SunFounder"
DEFAULT_DT_BLOB=""
DEFAULT_EEPROM_CUSTOM_DATA=""

DEFAULT_DTO_HAT_CURRENT_SUPPLY=0
DEFAULT_I2C_ENABLE="-"
DEFAULT_SPI_ENABLE="-"
DEFAULT_IR_ENABLE="-"
DEFAULT_IR_PIN=0
DEFAULT_I2S_DAC_ENABLE="-"
DEFAULT_GPIO_POWEROFF=0

# 检查是否存在配置文件
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    touch "$CONFIG_FILE"
fi

check_config() {
    if [ -z "${!1}" ]; then
        sed -i "/^$1=/d" "$CONFIG_FILE" # 删除配置文件中的变量
        echo "$1=$2" >> "$CONFIG_FILE"
        eval "$1=$2"
    fi
}
check_config "eeprom_file" "$DEFAULT_EEPROM_FILE"
check_config "eeprom_i2c_bus" "$DEFAULT_EEPROM_I2C_BUS"
check_config "eeprom_chip_type" "$DEFAULT_EEPROM_CHIP_TYPE"
check_config "eeprom_chip_address" "$DEFAULT_EEPROM_CHIP_ADDRESS"
check_config "eeprom_pcb_code" "$DEFAULT_EEPROM_PCB_CODE"
check_config "product_name" "$DEFAULT_PRODUCT_NAME"
check_config "vendor" "$DEFAULT_VENDOR"
check_config "dt_blob" "$DEFAULT_DT_BLOB"
check_config "eeprom_custom_data" "$DEFAULT_EEPROM_CUSTOM_DATA"
check_config "dto_hat_current_supply" "$DEFAULT_DTO_HAT_CURRENT_SUPPLY"
check_config "dto_i2c_enable" "$DEFAULT_I2C_ENABLE"
check_config "dto_spi_enable" "$DEFAULT_SPI_ENABLE"
check_config "dto_ir_enable" "$DEFAULT_IR_ENABLE"
check_config "dto_ir_pin" "$DEFAULT_IR_PIN"
check_config "dto_i2s_dac_enable" "$DEFAULT_I2S_DAC_ENABLE"
check_config "dto_gpio_poweroff" "$DEFAULT_GPIO_POWEROFF"

CHIP_TYPES=(
    "24c32"
    "24c64"
    "24c128"
    "24c256"
    "24c512"
    "24c1024"
)

ENABLE_TYPE=(
    "-" "未设置"
    "1" "开启"
    "0" "关闭"
)

declare -A CHIP_ADDRESS
CHIP_ADDRESS["50"]="标准HAT"
CHIP_ADDRESS["51"]="可层叠HAT"
CHIP_ADDRESS["52"]="Power HAT Mode 0"
CHIP_ADDRESS["53"]="Power HAT Mode 1"

create_dtoverlay() {
    while true; do

        local hat_current_supply="未设置"
        if [ "$dto_hat_current_supply" -ne 0 ]; then
            hat_current_supply="$dto_hat_current_supply mA"
        fi
        local i2c_enable="未设置"
        if [ "$dto_i2c_enable" == "1" ]; then
            i2c_enable="开启"
        elif [ "$dto_i2c_enable" == "0" ]; then
            i2c_enable="关闭"
        fi
        local spi_enable="未设置"
        if [ "$dto_spi_enable" == "1" ]; then
            spi_enable="开启"
        elif [ "$dto_spi_enable" == "0" ]; then
            spi_enable="关闭"
        fi
        local ir_pin="引脚未设置"
        if [ "$dto_ir_pin" -ne 0 ]; then
            ir_pin="GPIO$dto_ir_pin"
        fi
        local ir="未设置"
        if [ "$dto_ir_enable" == "1" ]; then
            ir="开启 ($ir_pin)"
        elif [ "$dto_ir_enable" == "0" ]; then
            ir="关闭"
        fi
        local i2s_dac_enable="未设置"
        if [ "$dto_i2s_dac_enable" == "1" ]; then
            i2s_dac_enable="开启"
        elif [ "$dto_i2s_dac_enable" == "0" ]; then
            i2s_dac_enable="关闭"
        fi
        local gpio_power_off="引脚未设置"
        if [ "$dto_gpio_poweroff" -ne 0 ]; then
            gpio_power_off="GPIO$dto_gpio_poweroff"
        fi
        local options=(
            "<" "返回"
            "1" "产品名称: $product_name"
            "2" "公司名称: $vendor"
            "3" "HAT+供电电流: $hat_current_supply"
            "4" "I2C: $i2c_enable"
            "5" "SPI: $spi_enable"
            "6" "IR: $ir"
            "7" "I2S DAC: $i2s_dac_enable"
            "8" "GPIO Power Off: $gpio_power_off"
            "=" "生成 DT Overlay"
        )
        select=$(whiptail --title "创建 DT Overlay" --menu "" 15 78 8 "${options[@]}" 3>&1 1>&2 2>&3)

        case $select in
            "<") # 返回
                break
            ;;
            "1") # 产品名称
                result=$(whiptail --title "产品名称" --inputbox "请输入产品名称:" 10 60 "$product_name" 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    product_name=$result
                    sed -i "/^product_name=/c\product_name=\"$product_name\"" "$CONFIG_FILE"
                fi
            ;;
            "2") # 公司名称
                result=$(whiptail --title "公司名称" --inputbox "请输入公司名称:" 10 60 "$vendor" 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    vendor=$result
                    sed -i "/^vendor=/c\vendor=\"$vendor\"" "$CONFIG_FILE"
                fi
            ;;
            "3") # HAT+供电电流
                result=$(whiptail --title "HAT+供电电流" --inputbox "请输入HAT+的供电电流(mA) 0表示不设置:" 10 60 "$dto_hat_current_supply" 3>&1 1>&2 2>&3)
                echo "result: $result"
                if [ -n "$result" ]; then
                    dto_hat_current_supply=$result
                    sed -i "/^dto_hat_current_supply=/c\dto_hat_current_supply=$dto_hat_current_supply" "$CONFIG_FILE"
                fi
            ;;
            "4") # I2C
                local options=()
                for ((i=0; i<${#ENABLE_TYPE[@]}; i+=2)); do
                    j=$((i+1))
                    if [ "${ENABLE_TYPE[$i]}" == "$dto_i2c_enable" ]; then
                        options+=("${ENABLE_TYPE[$i]}" "${ENABLE_TYPE[$j]}(*)")
                    else
                        options+=("${ENABLE_TYPE[$i]}" "${ENABLE_TYPE[$j]}")
                    fi
                done

                local result=$(whiptail --title "I2C" --menu "选择是否开启I2C:" 15 78 7 ${options[@]} 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    dto_i2c_enable=$result
                    sed -i "/^dto_i2c_enable=/c\dto_i2c_enable=$dto_i2c_enable" "$CONFIG_FILE"
                fi
            ;;
            "5") # SPI
                local options=()
                for ((i=0; i<${#ENABLE_TYPE[@]}; i+=2)); do
                    j=$((i+1))
                    if [ "${ENABLE_TYPE[$i]}" == "$dto_spi_enable" ]; then
                        options+=("${ENABLE_TYPE[$i]}" "${ENABLE_TYPE[$j]}(*)")
                    else
                        options+=("${ENABLE_TYPE[$i]}" "${ENABLE_TYPE[$j]}")
                    fi
                done

                local result=$(whiptail --title "SPI" --menu "选择是否开启SPI:" 15 78 7 ${options[@]} 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    dto_spi_enable=$result
                    sed -i "/^dto_spi_enable=/c\dto_spi_enable=$dto_spi_enable" "$CONFIG_FILE"
                fi
            ;;
            "6") # IR
                local options=()
                for ((i=0; i<${#ENABLE_TYPE[@]}; i+=2)); do
                    j=$((i+1))
                    if [ "${ENABLE_TYPE[$i]}" == "$dto_ir_enable" ]; then
                        options+=("${ENABLE_TYPE[$i]}" "${ENABLE_TYPE[$j]}(*)")
                    else
                        options+=("${ENABLE_TYPE[$i]}" "${ENABLE_TYPE[$j]}")
                    fi
                done

                local result=$(whiptail --title "IR" --menu "选择是否开启IR:" 15 78 7 ${options[@]} 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    dto_ir_enable=$result
                    sed -i "/^dto_ir_enable=/c\dto_ir_enable=$dto_ir_enable" "$CONFIG_FILE"
                fi
                if [ "$dto_ir_enable" -eq 1 ]; then
                    result=$(whiptail --title "IR" --inputbox "请输入IR的GPIO引脚(0表示未设置):" 10 60 "$dto_ir_pin" 3>&1 1>&2 2>&3)
                    if [ -n "$result" ]; then
                        dto_ir_pin=$result
                        sed -i "/^dto_ir_pin=/c\dto_ir_pin=$dto_ir_pin" "$CONFIG_FILE"
                    fi
                fi
            ;;
            "7") # I2S DAC
                local options=()
                for ((i=0; i<${#ENABLE_TYPE[@]}; i+=2)); do
                    j=$((i+1))
                    if [ "${ENABLE_TYPE[$i]}" == "$dto_i2s_dac_enable" ]; then
                        options+=("${ENABLE_TYPE[$i]}" "${ENABLE_TYPE[$j]}(*)")
                    else
                        options+=("${ENABLE_TYPE[$i]}" "${ENABLE_TYPE[$j]}")
                    fi
                done

                local result=$(whiptail --title "I2C" --menu "选择是否开启I2S DAC:" 15 78 7 ${options[@]} 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    dto_i2s_dac_enable=$result
                    sed -i "/^dto_i2s_dac_enable=/c\dto_i2s_dac_enable=$dto_i2s_dac_enable" "$CONFIG_FILE"
                fi
            ;;
            "8") # GPIO Power Off
                result=$(whiptail --title "GPIO Power Off" --inputbox "GPIO Power off 设置，会在树莓派关机后，把一个GPIO引脚拉高。请输入GPIO引脚(0表示未设置):" 10 60 "$dto_gpio_poweroff" 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    dto_gpio_poweroff=$result
                    sed -i "/^dto_gpio_poweroff=/c\dto_gpio_poweroff=$dto_gpio_poweroff" "$CONFIG_FILE"
                fi
            ;;
            "=") # 生成 DT Overlay
                if [ -z "$product_name" ] || [ -z "$vendor" ]; then
                    whiptail --title "错误" --msgbox "请先输入产品名称和公司名称" 8 78
                    continue
                fi
                local lower_vendor="${vendor,,}"
                local lower_product_name="${product_name,,}"
                local no_space_product=$(echo "$lower_product_name" | tr -d ' ')
                local name="$lower_vendor-$no_space_product"
                dt_blob="$name.dtbo"
                sed -i "/^dt_blob=/c\dt_blob=\"$dt_blob\"" "$CONFIG_FILE"
                local msg="生成dtoverlay: $name\n\n"
                local command="python3 scripts/create_dtoverlay.py -f --name $name"
                if [ "$dto_hat_current_supply" -ne 0 ]; then
                    msg+="设置最大电流: $dto_hat_current_supply mA, "
                    command+=" --hat-current-supply $dto_hat_current_supply"
                fi
                if [ "$dto_i2c_enable" != "-" ]; then
                    msg+="开启I2C, "
                    command+=" --i2c $dto_i2c_enable"
                fi
                if [ "$dto_spi_enable" != "-" ]; then
                    msg+="开启SPI, "
                    command+=" --spi $dto_spi_enable"
                fi
                if [ "$dto_ir_enable" != "-" ]; then
                    if [ "$dto_ir_enable" -eq 1 ]; then
                        msg+="开启IR GPIO$dto_ir_pin, "
                        command+=" --ir $dto_ir_enable --ir-gpio $dto_ir_pin"
                    fi
                fi
                if [ "$dto_i2s_dac_enable" != "-" ]; then
                    msg+="开启I2S DAC, "
                    command+=" --i2s-dac $dto_i2s_dac_enable"
                fi
                if [ "$dto_gpio_poweroff" -ne 0 ]; then
                    msg+="设置GPIO Power-Off GPIO$dto_gpio_poweroff, "
                    command+=" --gpio-poweroff $dto_gpio_poweroff"
                fi
                msg+="\n\n生成命令: $command\n"
                msg+="是否生成 DT Overlay?"
                if whiptail --title "确认" --yesno "$msg" 18 78; then
                    result=$(eval $command)
                    if [ $? -eq 0 ]; then
                        if whiptail --title "生成成功" --yesno "DTBO 文件: $dt_blob 生成成功，是否创建EEPROM？" 10 78; then
                            create_eeprom
                        fi
                    else
                        whiptail --title "生成失败" --msgbox "生成失败: $result" 30 78
                    fi
                    break
                fi
                break
            ;;
            *)
                break
            ;;
        esac
    done
}

create_eeprom() {
    while true; do
        select=$(whiptail --title "创建 EEPROM" --menu "填充下面内容生成EEPROM文件。(*)为必填项" 15 78 7 \
            "<" "返回" \
            "1" "产品编号: $eeprom_pcb_code (*)" \
            "2" "产品名称: $product_name (*)" \
            "3" "公司名称: $vendor (*)" \
            "4" "DT overlay: $dt_blob" \
            "5" "自定义数据: $eeprom_custom_data" \
            "=" "生成 EEPROM" \
        3>&1 1>&2 2>&3)

        case $select in
            "<") # 返回
                break
            ;;
            "1") # PCB 编码
                result=$(whiptail --title "产品编号" --inputbox "产品格式为P<流水号>V<版本号>:" 10 60 "$eeprom_pcb_code" 3>&1 1>&2 2>&3)
                echo "产品编号: $eeprom_pcb_code"
                if [ -n "$result" ]; then
                    eeprom_pcb_code=$result
                    sed -i "/^eeprom_pcb_code=/c\eeprom_pcb_code=\"$eeprom_pcb_code\"" "$CONFIG_FILE"
                fi
            ;;
            "2") # 产品名称
                result=$(whiptail --title "产品名称" --inputbox "请输入产品名称:" 10 60 "$product_name" 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    product_name=$result
                    sed -i "/^product_name=/c\product_name=\"$product_name\"" "$CONFIG_FILE"
                fi
            ;;
            "3") # 公司名称
                result=$(whiptail --title "公司名称" --inputbox "请输入公司名称:" 10 60 "$vendor" 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    vendor=$result
                    sed -i "/^vendor=/c\vendor=\"$vendor\"" "$CONFIG_FILE"
                fi
            ;;
            "4") # DT overlay
                result=$(whiptail --title "输入DT overlay" --inputbox "请输入DT overlay:" 10 60 "$dt_blob" 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    dt_blob=$result
                    sed -i "/^dt_blob=/c\dt_blob=\"$dt_blob\"" "$CONFIG_FILE"
                fi
            ;;
            "5") # 自定义数据
                result=$(whiptail --title "自定义数据" --inputbox "请输入自定义数据:" 10 60 "$eeprom_custom_data" 3>&1 1>&2 2>&3)
                if [ -n "$result" ]; then
                    eeprom_custom_data=$result
                    sed -i "/^eeprom_custom_data=/c\eeprom_custom_data=\"$eeprom_custom_data\"" "$CONFIG_FILE"
                fi
            ;;
            "=") # 生成 EEPROM
                # 在这里添加创建 EEPROM 的代码
                if [ -z "$eeprom_pcb_code" ] || [ -z "$product_name" ] || [ -z "$vendor" ]; then
                    whiptail --title "错误" --msgbox "请先输入所有的信息" 8 78
                else
                    command="python3 scripts/create_eeprom.py --less --id $eeprom_pcb_code --name \"$product_name\" --vendor \"$vendor\" --device-tree \"$dt_blob\" --custom-data \"$eeprom_custom_data\" -f"
                    if whiptail --title "确认" --yesno "你输入了以下信息:\n\n产品编号: $eeprom_pcb_code\n产品名称: $product_name\n公司名称: $vendor\nDT overlay: $dt_blob\n自定义数据: $eeprom_custom_data\n\n生成命令: $command\n\n是否开始生成?" 18 78; then
                        # 在这里添加生成 EEPROM 的代码、
                        result=$(eval $command)
                        if [ $? -eq 0 ]; then
                            eeprom_file=$(echo "$result" | awk 'END{print}')
                            if whiptail --title "生成成功" --yesno "EEPROM 文件: $eeprom_file 生成成功，是否烧录？" 10 78; then
                                sed -i "/^eeprom_file=/c\eeprom_file=\"$eeprom_file\"" "$CONFIG_FILE"
                                burn_eeprom
                            fi
                        else
                            whiptail --title "生成失败" --msgbox "生成失败: $result" 8 78
                        fi
                        break
                    fi
                fi
            ;;
            *)
                break
            ;;
        esac
    done
}

burn_eeprom() {
    # 检查是否有I2C总线 9
    if [ ! -d "/sys/class/i2c-dev/i2c-9" ]; then
        sudo dtoverlay i2c-gpio i2c_gpio_sda=0 i2c_gpio_scl=1 bus=9
    fi

    while true; do
        burn_select=$(whiptail --title "烧录EEPROM" --menu "选择你的操作" 15 78 8 \
            "<" "返回" \
            "1" "选择 EEPROM 文件: $eeprom_file" \
            "2" "选择芯片型号: $eeprom_chip_type" \
            "3" "选择I2C总线: $eeprom_i2c_bus" \
            "4" "选择芯片地址: $eeprom_chip_address" \
            "=" "开始烧录" \
        3>&1 1>&2 2>&3)
        
        case $burn_select in
            "<")
                break
            ;;
            "1") # 选择 EEPROM 文件
                eeprom_files=$(ls eeproms/ | grep '\.eep$')
                menu_items=()
                for file in $eeprom_files; do
                    if [ "$file" == "$eeprom_file" ]; then
                        menu_items+=("$file" "(*)")
                    else
                        menu_items+=("$file" "")
                    fi
                done
                eeprom_file=$(whiptail --title "选择一个 EEPROM 文件" --menu "" 15 78 6 "${menu_items[@]}" 3>&1 1>&2 2>&3)
                if [ $? -eq 0 ]; then
                    sed -i "/^eeprom_file=/c\eeprom_file=\"$eeprom_file\"" "$CONFIG_FILE"
                fi
            ;;
            "2") # 选择芯片型号
                menu_items=()
                for type in "${CHIP_TYPES[@]}"; do
                    if [ "$type" == "$eeprom_chip_type" ]; then
                        menu_items+=("$type" "(*)")
                    else
                        menu_items+=("$type" "")
                    fi
                done
                eeprom_chip_type=$(whiptail --title "选择芯片型号" --menu "" 15 78 6 "${menu_items[@]}" 3>&1 1>&2 2>&3)
                if [ $? -eq 0 ]; then
                    sed -i "/^eeprom_chip_type=/c\eeprom_chip_type=\"$eeprom_chip_type\"" "$CONFIG_FILE"
                fi
            ;;
            "3") # 选择I2C总线
                bus_items=()
                for bus in /sys/class/i2c-dev/*; do
                    bus=$(basename $bus)
                    if [ "$bus" == "$eeprom_i2c_bus" ]; then
                        bus_items+=("$bus" "(*)")
                    else
                        bus_items+=("$bus" "")
                    fi
                done
                eeprom_i2c_bus=$(whiptail --title "选择I2C总线" --menu "" 15 78 8 "${bus_items[@]}" 3>&1 1>&2 2>&3)
                if [ $? -eq 0 ]; then
                    eeprom_i2c_bus=${eeprom_i2c_bus}
                    sed -i "/^eeprom_i2c_bus=/c\eeprom_i2c_bus=\"$eeprom_i2c_bus\"" "$CONFIG_FILE"
                fi
            ;;
            "4") # 选择芯片地址
                if [ -z "$eeprom_i2c_bus" ]; then
                    whiptail --title "错误" --msgbox "请先选择 I2C 总线" 8 78
                    continue
                fi
                # 添加更多地址和名称的映射

                address_items=()
                while IFS= read -r line; do
                    for address in $line; do
                        # 检查地址是否在 CHIP_ADDRESS 数组中
                        if [[ -n "${CHIP_ADDRESS[$address]}" ]]; then
                            name=${CHIP_ADDRESS[$address]}
                            if [ "$address" == "$eeprom_chip_address" ]; then
                                address_items+=("$address" "$name (*)")
                            else
                                address_items+=("$address" "$name")
                            fi
                        fi
                    done
                done < <(i2cdetect -y ${eeprom_i2c_bus#i2c-} | awk 'NR>1 {print substr($0, 4, 49)}' | tr -s ' ' '\n' | grep "^[0-9a-f][0-9a-f]$")

                eeprom_chip_address=$(whiptail --title "选择芯片地址" --menu "" 15 78 4 "${address_items[@]}" 3>&1 1>&2 2>&3)
                if [ $? -eq 0 ]; then
                    eeprom_chip_address=${eeprom_chip_address}
                    sed -i "/^eeprom_chip_address=/c\eeprom_chip_address=\"$eeprom_chip_address\"" "$CONFIG_FILE"
                fi
            ;;
            "=") # 开始烧录
                if [ -z "$eeprom_file" ] || [ -z "$eeprom_i2c_bus" ] || [ -z "$eeprom_chip_type" ] || [ -z "$eeprom_chip_address" ] ; then
                    whiptail --title "错误" --msgbox "请先选择 EEPROM 文件、芯片型号和芯片地址" 8 78
                else
                    command="bash ./scripts/eepflash.sh -y -w -f=eeproms/$eeprom_file -t=$eeprom_chip_type -a=${eeprom_chip_address#0x} -d=${eeprom_i2c_bus#i2c-}"
                    echo "command: $command"
                    if whiptail --title "确认" --yesno "你选择了以下选项:\n\nEEPROM 文件: $eeprom_file\nI2C 总线: $eeprom_i2c_bus\n芯片型号: $eeprom_chip_type\n芯片地址: $eeprom_chip_address\n烧录命令: $command\n\n是否开始烧录，记得把WP拉高?" 15 78; then
                        result=$(eval $command)
                        if [ $? -eq 0 ]; then
                            whiptail --title "烧录成功" --msgbox "烧录成功" 8 78
                        else
                            whiptail --title "烧录失败" --msgbox "烧录失败: \n$result" 15 78
                        fi
                        break
                    fi
                    break
                fi
            ;;
            *)
                break
            ;;
        esac
    done
}

while true; do
    select=$(whiptail --title "SunFounder HAT+ 助手" --menu "" 10 78 3 \
        "1" "创建DT Overlay" \
        "2" "创建EEPROM" \
        "3" "烧录EEPROM到HAT" \
    3>&1 1>&2 2>&3)
    
    case $select in
        "1") # 创建DT Overlay
            create_dtoverlay
        ;;
        "2") # 创建EEPROM
            create_eeprom
        ;;
        "3") # 烧录EEPROM到HAT
            burn_eeprom
        ;;
        *)
            break
        ;;
    esac
done
