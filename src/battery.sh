#!/bin/bash

ioreg -l -n AppleSmartBattery -r > info.txt

if [ "$1" = "reg" ]; then
	ICON_SET="icons"
else
	ICON_SET="gradient-icons"
fi

RAW_CURRENT_CAPACITY=$(cat info.txt | grep -e \"AppleRawCurrentCapacity\" | awk '{printf ("%i", $3)}')
RAW_MAX_CAPACITY=$(cat info.txt | grep -e \"AppleRawMaxCapacity\" | awk '{printf ("%i", $3)}')
# MAX_CAPACITY=$(cat info.txt | grep -e \"MaxCapacity\" | | awk -F',' '{printf ("%s", $45)}' | awk -F'=' '{printf      ("%i", $2)}')
DESIGN_CAPACITY=$(cat info.txt | grep -e \"DesignCapacity\" | awk '{printf ("%i", $3)}')
TEMPERATURE=$(cat info.txt | grep -e "\"Temperature\"" | awk '{printf ("%.1f", $3/100.00)}')
MANUFACTURE_DATE=$(cat info.txt | grep -e \"ManufactureDate\" | awk -F',' '{printf ("%s", $56)}' | awk -F'=' '{printf ("%i", $2)}')
CHARGING=$(cat info.txt | grep -e \"IsCharging\" | awk '{printf("%s",$3)}')


SERIAL=$(cat info.txt | grep -e \"Serial\" | awk -F',' '{printf ("%s", $40)}' | awk -F'=' '{printf ("%s", $2)}' | tr -d '"')
SERIAL="${SERIAL%\"}"

HEALTH=$(echo $RAW_MAX_CAPACITY $DESIGN_CAPACITY | awk '{printf ("%i", $1/$2 * 100)}')
CHARGE=$(echo $RAW_CURRENT_CAPACITY $RAW_MAX_CAPACITY | awk '{printf ("%i", $1/$2 * 100)}')
CELLS=$(/usr/bin/python3 -c "f='●'*(int($CHARGE/10)) + '○'*(int(10-$CHARGE/10));print(f)")

CYCLE_COUNT=$(cat info.txt | grep -e '\"CycleCount\" =' | awk '{printf ("%i", $3)}')

TIME_TO_EMPTY=$(cat info.txt | grep -e \"AvgTimeToEmpty\" | awk '{printf("%s", $3)}')
TIME_LEFT=Calculating…
if [ $TIME_TO_EMPTY -lt 15000 ]; then
TIME_LEFT=$(cat info.txt | grep -e \"AvgTimeToEmpty\" | awk '{printf("%i:%.2i", $3/60, $3%60)}')
fi

TIME_INFO=n
STATUS_INFO=Draining
BATT_ICON="$ICON_SET/draining.png"

if [ $CHARGING == Yes ]; then
	TIME_FULL=$(cat info.txt | grep -e \"AvgTimeToFull\" | tr '\n' ' | ' | awk '{printf("%i:%.2i", $3/60, $3%60)}')
	TIME_INFO=$(echo $TIME_FULL until full)
	STATUS_INFO=Charging
	BATT_ICON="$ICON_SET/charging.png"
else
	FULLY_CHARGED=$(cat info.txt | grep -e \"FullyCharged\" | awk '{printf("%s",$3)}')
	EXTERNAL=$(cat info.txt | grep -e \"ExternalConnected\" | awk '{printf("%s",$3)}')
	if [ $FULLY_CHARGED == Yes ]; then 
		if [ $EXTERNAL == Yes ]; then
			TIME_INFO=$(echo On AC power)
			STATUS_INFO=$(echo Fully Charged)
			BATT_ICON="$ICON_SET/power.png"
		else
			TIME_INFO=$(echo $TIME_LEFT)
			BATT_ICON="$ICON_SET/full.png"
		fi
	else
		TIME_INFO=$(echo $TIME_LEFT)
		BATT_ICON="$ICON_SET/critical.png"
		if [ $CHARGE -gt 80 ]; then
			BATT_ICON="$ICON_SET/full.png"
		elif [ $CHARGE -gt 50 ]; then
			BATT_ICON="$ICON_SET/medium.png"
		elif [ $CHARGE -gt 10 ]; then
			BATT_ICON="$ICON_SET/low.png"
		fi
	fi
fi

let "MANUFACTURE_DATE=MANUFACTURE_DATE-0x0000303030303030"
let "MANUFACTURE_DATE=(MANUFACTURE_DATE & 0x000000FF00FF00FF) * 10 + ((MANUFACTURE_DATE & 0x0000FF00FF00FF00) >> 8) + 1992"

let "year=(MANUFACTURE_DATE >> 0) & 0xFFFF"
let "month=(MANUFACTURE_DATE >> 16) & 0xFFFF"
let "day=(MANUFACTURE_DATE >> 32) & 0xFFFF"

AGE=$(python3 -c "from datetime import date as D; d1=D.today(); d2=D($year, $month, $day); print ( (d1.year - d2.year)*12 + d1.month - d2.month )")

TRACKPAD_ICON="$ICON_SET/trackpad.png"
# trackpad
TrackpadPercent=`ioreg -c AppleDeviceManagementHIDEventService | grep -se \"Magic Trackpad\" -A8 | grep -se \"BatteryPercent\" | sed 's/[a-z,A-Z, ,|,\",=]//g' | tail -1 | awk '{print $1}'`
if [ ${#TrackpadPercent} = 0 ]
then
	TrackpadTitle="Not connected"
else
	TrackpadSlug=$(python -c "f='●'*(int($TrackpadPercent/10)) + '○'*(int(10-$TrackpadPercent/10));print(f)")
	TrackpadTitle="$TrackpadPercent% $TrackpadSlug"
fi

MOUSE_ICON="$ICON_SET/mouse.png"
# mouse
MousePercent=`ioreg -c AppleDeviceManagementHIDEventService | grep -se \"Magic Mouse\" -A8 | grep -se \"BatteryPercent\" | sed 's/[a-z,A-Z, ,|,\",=]//g' | tail -1 | awk '{print $1}'`
if [ ${#MousePercent} = 0 ]
then
	MouseTitle="Not connected"
else
	MouseSlug=$(python -c "f='●'*(int($MousePercent/10)) + '○'*(int(10-$MousePercent/10));print(f)")
	MouseTitle="$MousePercent% $MouseSlug"
fi

KEYBOARD_ICON="$ICON_SET/keyboard.png"
# keyboard
KeyboardPercent=`ioreg -c AppleDeviceManagementHIDEventService | grep -se \"Magic Keyboard\" -A8 | grep -se \"BatteryPercent\" | sed 's/[a-z,A-Z, ,|,\",=]//g' | tail -1 | awk '{print $1}'`
if [ ${#KeyboardPercent} = 0 ]
then
	KeyboardTitle="Not connected"
else
	KeyboardSlug=$(python -c "f='●'*(int($KeyboardPercent/10)) + '○'*(int(10-$KeyboardPercent/10));print(f)")
	KeyboardTitle="$KeyboardPercent% $KeyboardSlug"
fi

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
    <title>${TEMPERATURE} °C</title>
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
  <item>
    <title>$SERIAL</title>
	<subtitle>Serial</subtitle>
	<icon>$ICON_SET/serial.png</icon>
  </item>
  <item>
    <title>$AGE months</title>
	<subtitle>Age</subtitle>
	<icon>$ICON_SET/age.png</icon>
  </item>
</items>
EOB
