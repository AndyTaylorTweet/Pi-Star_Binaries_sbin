#!/usr/bin/env python3

#
# (C) 2025, by Andy Taylor MW0MWZ
#

#
# This tool is used to send messages to the OLED screen (when attached)
# to give some status when the MMDVMHost binary is not running.
#

import sys
import subprocess

try:
    from PIL import Image, ImageDraw, ImageFont
    from luma.core.interface.serial import i2c
    from luma.oled.device import ssd1306, sh1106
    import configparser

except ImportError:
    exit(0)

# MMDVMHost Config
CONFIG_PATH = "/etc/mmdvmhost"

def get_screen_type_from_config():
    try:
        config = configparser.ConfigParser()
        config.read(CONFIG_PATH)
        screen_type = config.getint("OLED", "Type")
        if screen_type == 3:
            return 'type3', 0x3C  # Adafruit SSD1306 I2C
        elif screen_type == 6:
            return 'type6', 0x3C  # SH1106 I2C
        else:
            return None, None
    except:
        return None, None

def clear_display(device):
    try:
        device.clear()
        device.show()
    except:
        pass

def draw_text(device, line1, line2):
    try:
        width = device.width
        height = device.height
        font = ImageFont.load_default()

        # Create a blank image to draw on
        image = Image.new("1", (width, height))
        draw = ImageDraw.Draw(image)

        # Calculate X position for centering text horizontally
        text_width_1 = draw.textlength(line1, font=font)
        text_width_2 = draw.textlength(line2, font=font)
        
        x1 = (width - text_width_1) // 2
        x2 = (width - text_width_2) // 2

        # Center text vertically (simple method: divide screen height by number of lines)
        y1 = height // 4  # Line 1 at roughly 1/4 of the screen
        y2 = height // 2  # Line 2 at roughly 1/2 of the screen

        # Draw the text at calculated positions
        draw.text((x1, y1), line1, font=font, fill=255)
        draw.text((x2, y2), line2, font=font, fill=255)

        # Display the image on the screen
        device.display(image)
    except:
        pass

def main():
    args = sys.argv[1:]

    clear_screen = "-c" in args
    lines = [arg for arg in args if not arg.startswith("-")]

    if not clear_screen and len(lines) != 2:
        exit(0)

    screen_type, address = detect_screen_type()
    if not screen_type:
        exit(0)

    try:
        serial = i2c(port=1, address=address)

        if screen_type == 'type3':
            device = ssd1306(serial, width=128, height=64)
        elif screen_type == 'type6':
            device = sh1106(serial, width=128, height=64)
        else:
            exit(0)

        # Prevent screen reset on exit
        device.cleanup = lambda: None

        if clear_screen:
            clear_display(device)

        if len(lines) == 2:
            draw_text(device, lines[0], lines[1])

    except:
        exit(0)

if __name__ == "__main__":
    main()
