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

# Import some python modules, or fail silently if they wont load.
try:
    import serial
    import os
except ImportError:
    sys.exit(1)


MODEM_BAUDRATE = 115200
MMDVM_SERIAL = 0x80

NEXTION_FIELDS = ["t0", "t1", "t2", "t5", "t20", "t30", "t31", "t32" ] # <https://repo.w0chp.net/WPSD-Dev/WPSD_Nextion/src/branch/main/Nextion_Field_Use.md#nextion-display-fields>

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

    if len(sys.argv) < 3:
        print(f"Usage: {programName} <port> [-c | <field> <text value>]")
        sys.exit()

    port = sys.argv[1]

    try:
        serialInterface = serial.Serial(port=port, baudrate=MODEM_BAUDRATE)
        
        if sys.argv[2] == "-c":
            ClearAllFields(serialInterface)
        elif len(sys.argv) == 4:
            field = sys.argv[2]
            textValue = sys.argv[3]
            SetTextValue(field, textValue, serialInterface)
        else:
            print(f"Invalid arguments. Usage: {programName} <port> [-c | <field> <text value>]")
            sys.exit()
        
        serialInterface.close()
    
    except serial.SerialException as e:
        print(f"Serial port exception: {e}")
        sys.exit()

