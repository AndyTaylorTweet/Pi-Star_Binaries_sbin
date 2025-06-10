#!/usr/bin/env python3

#
# (C) 2025, by Lucas Burns, AE0LI; Chip Cuccio, W0CHP
# Pi-Star changes (not many) by Andy Taylor, MW0MWZ
#

#
# This tool is used to send messages to the Nextion screen (when attached)
# to give some status when the MMDVMHost binary is not running.
#

import sys
import os

# Import some python modules, or fail silently if they won't load.
try:
    import serial
    import configparser
except ImportError:
    sys.exit(1)

# Nextion Display Port Configuration (Automated)
def get_display_port():
    config = configparser.ConfigParser()
    config.read('/etc/mmdvmhost')

    try:
        display = config.get('General', 'Display').strip()
    except (configparser.NoSectionError, configparser.NoOptionError):
        display = None

    # Default fallback
    displayPort = "/dev/ttyAMA0"

    if display == "Nextion":
        try:
            nextion_port = config.get('Nextion', 'Port').strip()
            if nextion_port == "/dev/ttyNextionDriver":
                try:
                    driver_port = config.get('NextionDriver', 'Port').strip()
                    displayPort = driver_port if driver_port else nextion_port
                except (configparser.NoSectionError, configparser.NoOptionError):
                    displayPort = nextion_port
            else:
                displayPort = nextion_port
        except (configparser.NoSectionError, configparser.NoOptionError):
            pass  # Leave default if Nextion section or Port is missing

    # Final substitution: if it's set to "modem", look up the real port
    if displayPort == "modem":
        try:
            modem_port = config.get('Modem', 'Port').strip()
            if modem_port:
                displayPort = modem_port
        except (configparser.NoSectionError, configparser.NoOptionError):
            pass  # Leave as "modem" if we can't resolve it

    return displayPort

MODEM_BAUDRATE = 115200
MMDVM_SERIAL = 0x80

NEXTION_FIELDS = ["t0", "t1", "t2", "t5", "t20", "t30", "t31", "t32"] # <https://repo.w0chp.net/WPSD-Dev/WPSD_Nextion/src/branch/main/Nextion_Field_Use.md#nextion-display-fields>

def MakeNextionCommand(commandString: str):
    result = bytearray()
    result.extend(commandString.encode())
    result.extend([0xff, 0xff, 0xff])
    return result

def MakeSetTextCommandString(field, value):
    return f"{field}.txt=\"{value}\""

def MakeModemCommand(nextionCommand: bytearray):
    frameLength = len(nextionCommand) + 3
    result = bytearray([0xe0, frameLength, MMDVM_SERIAL])
    result.extend(nextionCommand)
    return result

def SendModemCommand(mmdvmCommand: bytearray, serialInterface: serial.Serial):
    serialInterface.write(mmdvmCommand)

def SetTextValue(field, value, serialInterface: serial.Serial):
    command = MakeModemCommand(MakeNextionCommand(MakeSetTextCommandString(field, value)))
    SendModemCommand(command, serialInterface)

def ClearAllFields(serialInterface: serial.Serial):
    for field in NEXTION_FIELDS:
        SetTextValue(field, "", serialInterface)
    SendModemCommand(MakeModemCommand(MakeNextionCommand("ref 0")), serialInterface)  # Refresh display

if __name__ == "__main__":
    programPath = sys.argv[0]
    programName = os.path.basename(programPath)

    # Use get_display_port() to get the port instead of command-line arguments
    port = get_display_port()

    # Check if the resolved port exists
    if not os.path.exists(port):
        sys.exit(0)  # Exit silently

    if port is None:
        print(f"Failed to get the display port from configuration.")
        sys.exit(1)

    if len(sys.argv) < 2:  # Skip the port-related argument
        print(f"Usage: {programName} [-c | <field> <text value>]")
        sys.exit()

    try:
        serialInterface = serial.Serial(port=port, baudrate=MODEM_BAUDRATE)

        # Adjust the argument parsing to start after the port is handled
        if sys.argv[1] == "-c":
            ClearAllFields(serialInterface)
        elif len(sys.argv) == 3:
            field = sys.argv[1]
            textValue = sys.argv[2]
            SetTextValue(field, textValue, serialInterface)
        else:
            print(f"Invalid arguments. Usage: {programName} [-c | <field> <text value>]")
            sys.exit()

        serialInterface.close()

    except serial.SerialException as e:
        print(f"Serial port exception: {e}")
        sys.exit()
