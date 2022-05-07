#!/bin/bash

INFO=$(ioreg -l -n AppleSmartBattery -r)

if [ "$1" = "reg" ]; then
	ICON_SET="icons"
else
	ICON_SET="gradient-icons"
fi

# Charge and time remaining
RAW_CURRENT_CAPACITY=$(echo "$INFO" | grep -e \"AppleRawCurrentCapacity\" | awk '{printf $3; exit}')
RAW_MAX_CAPACITY=$(echo "$INFO" | grep -e \"AppleRawMaxCapacity\" | awk '{printf $3; exit}')
DESIGN_CAPACITY=$(echo "$INFO" | grep -e \"DesignCapacity\" | awk -F',' '{printf ("%s", $49)}' | awk -F'=' '{printf ("%i", $2)}')
CHARGE=$((RAW_CURRENT_CAPACITY * 100 / RAW_MAX_CAPACITY))
CELLS=$(/usr/bin/python3 -c "f='●'*(int($CHARGE/9)) + '○'*(int(10-$CHARGE/9)); print(f)")
STATUS_INFO=Draining...

CHARGING=$(echo "$INFO" | grep -e \"IsCharging\" | awk '{printf("%s", $3)}')
TIME_TO_EMPTY=$(echo "$INFO" | grep -e \"AvgTimeToEmpty | awk '{printf("%s", $3)}')
TIME_LEFT=Calculating…

if [ "$TIME_TO_EMPTY" -lt 15000 ]; then
    TIME_LEFT=$(echo "$INFO" | grep -e \"AvgTimeToEmpty\" | awk '{printf("%i:%.2i", $3/60, $3%60)}')
fi

if [ "$CHARGING" == Yes ]; then
    TIME_FULL=$(echo "$INFO" | grep -e \"AvgTimeToFull\" | tr '\n' ' | ' | awk '{printf("%i:%.2i", $3/60, $3%60)}')
    TIME_INFO="$TIME_FULL" until full
    STATUS_INFO=Charging...
    BATT_ICON="$ICON_SET/charging.png"
else
    FULLY_CHARGED=$(echo "$INFO" | grep -e \"FullyCharged\" | awk '{printf("%s", $3)}')
    EXTERNAL=$(echo "$INFO" | grep -e \"ExternalConnected\" | awk '{printf("%s", $3)}')
    if [ "$FULLY_CHARGED" == Yes ]; then
        if [ "$EXTERNAL" == Yes ]; then
            TIME_INFO="On AC power"
            STATUS_INFO="Fully Charged"
            BATT_ICON="$ICON_SET/power.png"
            CHARGE="100"
            CELLS="●●●●●●●●●●"
        else
            TIME_INFO=$TIME_LEFT
            BATT_ICON="$ICON_SET/full.png"
        fi
    else
        TIME_INFO=$TIME_LEFT
        BATT_ICON="$ICON_SET/critical.png"
        if [ "$CHARGE" -gt 80 ]; then
            BATT_ICON="$ICON_SET/full.png"
        elif [ "$CHARGE" -gt 50 ]; then
            BATT_ICON="$ICON_SET/medium.png"
        elif [ "$CHARGE" -gt 10 ]; then
            BATT_ICON="$ICON_SET/low.png"
        fi
    fi
fi

# Temperature
TEMPERATURE=$(echo "$INFO" | grep -e \"Temperature\" | awk '{printf ("%.1f", $3/10-273)}')

# Cycle Count
CYCLE_COUNT=$(echo "$INFO" | grep -e '"CycleCount" =' | awk '{printf ("%i", $3)}')

# Battery health
# ref: https://github.com/BenziAhamed/alfred-battery/issues/10#issuecomment-745541202
# DESIGN_CAPACITY=$(echo "$INFO" | grep DesignCapacity | awk '{printf ("%.i", $3)}')
HEALTH=$((RAW_MAX_CAPACITY * 100 / DESIGN_CAPACITY))

#if [ "$HEALTH" -gt 100 ]; then
#   HEALTH=100
#fi

# Serial
SERIAL=$(echo "$INFO" | grep -e \"Serial\" | awk -F',' '{printf ("%s", $40)}' | awk -F'=' '{printf ("%s", $2)}' | tr -d '"')
SERIAL="${SERIAL%\"}"

# Battery age
MANUFACTURE_DATE=$(echo "$INFO" | grep -e \"ManufactureDate\" | awk -F',' '{printf ("%s", $56)}' | awk -F'=' '{printf ("%i", $2)}')

let "MANUFACTURE_DATE=MANUFACTURE_DATE-0x0000303030303030"
let "MANUFACTURE_DATE=(MANUFACTURE_DATE & 0x000000FF00FF00FF) * 10 + ((MANUFACTURE_DATE & 0x0000FF00FF00FF00) >> 8) + 1992"

let "year=(MANUFACTURE_DATE >> 0) & 0xFFFF"
let "month=(MANUFACTURE_DATE >> 16) & 0xFFFF"
let "day=(MANUFACTURE_DATE >> 32) & 0xFFFF"

AGE=$("/usr/bin/python3" -c "from datetime import date as D; d1=D.today(); d2=D($year, $month, $day); print ( (d1.year - d2.year)*12 + d1.month - d2.month )")

TRACKPAD_ICON="$ICON_SET/trackpad.png"
# trackpad
TrackpadPercent=$(ioreg -c AppleDeviceManagementHIDEventService | grep -se \"Magic Trackpad\" -A8 | grep -se \"BatteryPercent\" | sed 's/[a-z,A-Z, ,|,\",=]//g' | tail -1 | awk '{print $1}')
if [ ${#TrackpadPercent} = 0 ]
then
	TrackpadTitle="Not connected"
else
	TrackpadSlug=$(python -c "f='●'*(int($TrackpadPercent/9)) + '○'*(int(10-$TrackpadPercent/9));print(f)")
	TrackpadTitle="$TrackpadPercent% $TrackpadSlug"
fi

MOUSE_ICON="$ICON_SET/mouse.png"
# mouse
MousePercent=$(ioreg -c AppleDeviceManagementHIDEventService | grep -se \"Magic Mouse\" -A8 | grep -se \"BatteryPercent\" | sed 's/[a-z,A-Z, ,|,\",=]//g' | tail -1 | awk '{print $1}')
if [ ${#MousePercent} = 0 ]
then
	MouseTitle="Not connected"
else
	MouseSlug=$(python -c "f='●'*(int($MousePercent/9)) + '○'*(int(10-$MousePercent/9));print(f)")
	MouseTitle="$MousePercent% $MouseSlug"
fi

KEYBOARD_ICON="$ICON_SET/keyboard.png"
# keyboard
KeyboardPercent=$(ioreg -c AppleDeviceManagementHIDEventService | grep -se \"Magic Keyboard\" -A8 | grep -se \"BatteryPercent\" | sed 's/[a-z,A-Z, ,|,\",=]//g' | tail -1 | awk '{print $1}')
if [ ${#KeyboardPercent} = 0 ]
then
	KeyboardTitle="Not connected"
else
	KeyboardSlug=$(python -c "f='●'*(int($KeyboardPercent/9)) + '○'*(int(10-$KeyboardPercent/9));print(f)")
	KeyboardTitle="$KeyboardPercent% $KeyboardSlug"
fi

# Alfred feedback
cat << EOB
<?xml version="1.0"?>
<items>
  <item>
    <title>$CHARGE% $CELLS</title>
	<subtitle>$STATUS_INFO</subtitle>
	<icon>$BATT_ICON</icon>
  </item>
  <item>
    <title>$TIME_INFO</title>
	<subtitle>Time Left</subtitle>
	<icon>$ICON_SET/clock.png</icon>
  </item>
  <item>
    <title>$TEMPERATURE °C</title>
	<subtitle>Temperature</subtitle>
	<icon>$ICON_SET/temp.png</icon>
  </item>
  <item>
    <title>$CYCLE_COUNT</title>
	<subtitle>Charge Cycles Completed</subtitle>
	<icon>$ICON_SET/cycles.png</icon>
  </item>
  <item>
    <title>$HEALTH%</title>
	<subtitle>Health</subtitle>
	<icon>$ICON_SET/health.png</icon>
  </item>
  <item>
    <title>$AGE months</title>
	<subtitle>Age</subtitle>
	<icon>$ICON_SET/age.png</icon>
  </item>
  <item>
    <title>$SERIAL</title>
	<subtitle>Serial</subtitle>
	<icon>$ICON_SET/serial.png</icon>
  </item>
  <item>
    <title>$MouseTitle</title>
    <subtitle>Magic Mouse</subtitle>
    <icon>$MOUSE_ICON</icon>
  </item>
  <item>
    <title>$KeyboardTitle</title>
    <subtitle>Magic Keyboard</subtitle>
    <icon>$KEYBOARD_ICON</icon>
  </item>
  <item>
    <title>$TrackpadTitle</title>
    <subtitle>Magic TrackPad</subtitle>
    <icon>$TRACKPAD_ICON</icon>
  </item>
</items>
EOB