
import argparse
import os

parser = argparse.ArgumentParser(description='Create dtoverlay')
parser.add_argument('-n', '--name', help='Name of dtoverlay', required=True)
parser.add_argument('-c', '--hat-current-supply', help='Hat current Supply')
parser.add_argument('-i', '--i2c', help='Enable I2C')
parser.add_argument('-s', '--spi', help='Enable SPI')
parser.add_argument('-r', '--ir', help='Enable IR')
parser.add_argument('-g', '--ir-gpio', help='GPIO pin for IR')
parser.add_argument('-d', '--i2s-speaker', help='Enable I2S Speaker')
parser.add_argument('-G', '--i2s-speaker-mic', action='store_true', help='Enable I2S Speaker and microphone')
parser.add_argument('-p', '--gpio-poweroff', help='Enable GPIO poweroff')
parser.add_argument('-m', '--hat-mode-current', action='store_true', help='Enable Hat mode change current')
parser.add_argument('-o', '--otg', action='store_true', help='Enable OTG')
parser.add_argument('-f', '--force', action='store_true', help='Force overwrite')
args = parser.parse_args()

script_directory = os.path.dirname(os.path.abspath(__file__))
OVERLAYS_DIR = os.path.join(script_directory, "../overlays")

i2c_template='''{{
        target = <&i2c1>;
        __overlay__ {{
            status = "{status}";
        }};
    }};'''

spi_template='''{{
        target = <&spi0>;
        __overlay__ {{
            status = "{status}";
        }};
    }};'''

ir_template_1 = '''{{
        target-path = "/";
        __overlay__ {{
            gpio_ir: ir-receiver@{pin:x} {{
                compatible = "gpio-ir-receiver";
                pinctrl-names = "default";
                pinctrl-0 = <&gpio_ir_pins>;

                // pin number, high or low
                gpios = <&gpio {pin} 1>;

                // parameter for keymap name
                linux,rc-map-name = "rc-rc6-mce";

                status = "okay";
            }};
        }};
    }};'''

ir_template_2 = '''{{
        target = <&gpio>;
        __overlay__ {{
            gpio_ir_pins: gpio_ir_pins@{pin:x} {{
                brcm,pins = <{pin}>;
                brcm,function = <0>;
                brcm,pull = <2>;
            }};
        }};
    }};'''

ir_overrides = [
    'ir = <&gpio_ir>,"status";',
    'ir_pins =	<&gpio_ir>,"gpios:4",',
    '			<&gpio_ir>,"reg:0",',
    '			<&gpio_ir_pins>,"brcm,pins:0",',
    '			<&gpio_ir_pins>,"reg:0";',
]

i2s_speaker_template_1 = '''{{
        target = <&i2s_clk_producer>;
        __overlay__ {{
            status = "{status}";
        }};
    }};'''

i2s_speaker_template_2 = '''{{
        target-path = "/";
        __overlay__ {{
            pcm5102a-codec {{
                compatible = "ti,pcm5102a";
                status = "{status}";
            }};
        }};
    }};'''

i2s_speaker_template_3 = '''{{
        target = <&sound>;
        __overlay__ {{
            compatible = "hifiberry,hifiberry-dac";
            i2s-controller = <&i2s_clk_producer>;
            status = "{status}";
        }};
    }};'''

gpio_poweroff_template_1 = '''{{
        target-path = "/";
        __overlay__ {{
            power_ctrl: power_ctrl {{
                compatible = "gpio-poweroff";
                gpios = <&gpio {pin} 0>;
                force;
            }};
        }};
    }};'''

gpio_poweroff_template_2 = '''{{
        target = <&gpio>;
        __overlay__ {{
            power_ctrl_pins: power_ctrl_pins {{
                brcm,pins = <{pin}>;
                brcm,function = <1>; // out
            }};
        }};
    }};'''

gpio_overrides = [
    'poweroff_pin =	<&power_ctrl>,"gpios:4",',
    '				<&power_ctrl_pins>,"brcm,pins:0";',
]


hat_current_supply_template = '''{{
        target-path = "/chosen";
        __overlay__ {{
            power: power {{
                hat_current_supply = <{current}>;
            }};
        }};
    }};'''

hat_mode_curent_overrides = [
    'mode0 = <&power>, "hat_current_supply:0=3000";',
    'mode1 = <&power>, "hat_current_supply:0=5000";'
]

i2s_speaker_mic_template1 = '''{{
        target = <&i2s_clk_producer>;
        __overlay__ {{
            status = "{status}";
        }};
    }};'''
i2s_speaker_mic_template2 = '''{
        target = <&gpio>;
        __overlay__ {
            googlevoicehat_pins: googlevoicehat_pins {
                brcm,pins = <16>;
                brcm,function = <1>; /* out */
                brcm,pull = <0>; /* up */
            };
        };
    };'''
i2s_speaker_mic_template3 = '''{{
        target-path = "/";
        __overlay__ {{
            voicehat-codec {{
                #sound-dai-cells = <0>;
                compatible = "google,voicehat";
                pinctrl-names = "default";
                pinctrl-0 = <&googlevoicehat_pins>;
                sdmode-gpios= <&gpio 16 0>;
                status = "{status}";
            }};
        }};
    }};'''
i2s_speaker_mic_template4 = '''{{
        target = <&sound>;
        __overlay__ {{
            compatible = "googlevoicehat,googlevoicehat-soundcard";
            i2s-controller = <&i2s_clk_producer>;
            status = "{status}";
        }};
    }};'''

otg_template = '''{
        target = <&usb>;
        dwc2_usb: __overlay__ {
            compatible = "brcm,bcm2835-usb";
            dr_mode = "host";
            g-np-tx-fifo-size = <32>;
            g-rx-fifo-size = <558>;
            g-tx-fifo-size = <512 512 512 512 512 256 256>;
            status = "okay";
        };
    };'''

content = '''/dts-v1/;
/plugin/;

/ {{
    compatible = "brcm,bcm2835";
{fragments}
{overrides}
}};
'''

fragment_template = '''
    fragment@{count} {node}'''

fragments = ""
override_list = []
fragment_count = 0

if args.hat_current_supply:
    node = hat_current_supply_template.format(current=args.hat_current_supply)
    fragments += fragment_template.format(count=fragment_count, node=node)
    fragment_count += 1
if args.i2c:
    status = "okay" if args.i2c == "1" else "disabled"
    node = i2c_template.format(status=status)
    fragments += fragment_template.format(count=fragment_count, node=node)
    fragment_count += 1
if args.spi:
    status = "okay" if args.spi == "1" else "disabled"
    node = spi_template.format(status=status)
    fragments += fragment_template.format(count=fragment_count, node=node)
    fragment_count += 1
if args.ir:
    node1 = ir_template_1.format(pin=int(args.ir_gpio))
    node2 = ir_template_2.format(pin=int(args.ir_gpio))
    fragments += fragment_template.format(count=fragment_count, node=node1)
    fragment_count += 1
    fragments += fragment_template.format(count=fragment_count, node=node2)
    fragment_count += 1
    override_list += ir_overrides
if args.i2s_speaker:
    status = "okay" if args.i2s_speaker == "1" else "disabled"
    node1 = i2s_speaker_template_1.format(status=status)
    node2 = i2s_speaker_template_2.format(status=status)
    node3 = i2s_speaker_template_3.format(status=status)
    fragments += fragment_template.format(count=fragment_count, node=node1)
    fragment_count += 1
    fragments += fragment_template.format(count=fragment_count, node=node2)
    fragment_count += 1
    fragments += fragment_template.format(count=fragment_count, node=node3)
    fragment_count += 1
if args.gpio_poweroff:
    node1 = gpio_poweroff_template_1.format(pin=int(args.gpio_poweroff))
    node2 = gpio_poweroff_template_2.format(pin=int(args.gpio_poweroff))
    fragments += fragment_template.format(count=fragment_count, node=node1)
    fragment_count += 1
    fragments += fragment_template.format(count=fragment_count, node=node2)
    fragment_count += 1
    override_list += gpio_overrides
if args.hat_mode_current:
    override_list += hat_mode_curent_overrides
if args.i2s_speaker_mic:
    status = "okay"
    node1 = i2s_speaker_mic_template1.format(status=status)
    node2 = i2s_speaker_mic_template2
    node3 = i2s_speaker_mic_template3.format(status=status)
    node4 = i2s_speaker_mic_template4.format(status=status)
    fragments += fragment_template.format(count=fragment_count, node=node1)
    fragment_count += 1
    fragments += fragment_template.format(count=fragment_count, node=node2)
    fragment_count += 1
    fragments += fragment_template.format(count=fragment_count, node=node3)
    fragment_count += 1
    fragments += fragment_template.format(count=fragment_count, node=node4)
    fragment_count += 1
if args.otg:
    node = otg_template
    fragments += fragment_template.format(count=fragment_count, node=node)
    fragment_count += 1


overrides = ""
if len(override_list) > 0:
    overrides = "	__overrides__ {\n"
    for override in override_list:
        overrides += f"		{override}\n"
    overrides += "	};"

content = content.format(fragments=fragments, overrides=overrides)

dts_file = f"{OVERLAYS_DIR}/{args.name}-overlay.dts"
dtbo_file = f"{OVERLAYS_DIR}/{args.name}.dtbo"

if (os.path.exists(dts_file) or os.path.exists(dtbo_file))and not args.force:
    force = input(f"File {dts_file} or {dtbo_file} exists, overwrite? (y/N): ")
    if force != "y":
        exit(1)

with open(dts_file, 'w') as f:
    f.write(content)

command = f"dtc -@ -Hepapr -I dts -O dtb -o {dtbo_file} {dts_file}"
os.system(command)
print(f"Created\n  {dts_file}\n  {dtbo_file}")
