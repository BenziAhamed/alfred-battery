# Thanks to:
# Bash Workflow Handler https://github.com/markokaestner/bash-workflow-handler
# Battery Status of Apple Devices http://www.macosxtips.co.uk/geeklets/system/battery-status-for-apple-wireless-keyboard-mouse-and-trackpad/

. workflowHandler.sh

# laptop
ioreg -l -n AppleSmartBattery -r > battery_info.txt
BatteryCurrentCapacity=$(cat battery_info.txt | grep CurrentCapacity | awk '{printf ("%i", $3)}')
if [ ${#BatteryCurrentCapacity} != 0 ]
then
	BatteryMaxCapacity=$(cat battery_info.txt | grep MaxCapacity | awk '{printf ("%i", $3)}')
	BatteryDesignCapacity=$(cat battery_info.txt | grep DesignCapacity | awk '{printf ("%i", $3)}')
	BatteryHealth=$(echo $BatteryMaxCapacity $BatteryDesignCapacity | awk '{printf ("%i", $1/$2 * 100)}')
	BatteryPercent=$(echo $BatteryCurrentCapacity $BatteryMaxCapacity | awk '{printf ("%i", $1/$2 * 100)}')
	BatterySlug=$(python -c "f='●'*($BatteryPercent/10) + '○'*(10-$BatteryPercent/10);print f")
	BatteryTitle="$BatteryPercent% $BatterySlug"
	BatteryCycles=$(cat battery_info.txt | grep -e '"CycleCount" =' | awk '{printf ("%i", $3)}')
	BatteryTimeToEmpty=$(cat battery_info.txt | grep -i AvgTimeToEmpty | awk '{printf("%s", $3)}')
	BatteryTimeLeft=Calculating...
	if [ $BatteryTimeToEmpty -lt 15000 ]; then
		BatteryTimeLeft=$(cat battery_info.txt | grep -i AvgTimeToEmpty | awk '{printf("%i:%.2i", $3/60, $3%60)}')
	fi
	BatteryIsCharging=$(cat battery_info.txt | grep -i ischarging | awk '{printf("%s",$3)}')
	BatteryStatus=draining
	if [ $BatteryIsCharging == Yes ]; then
		BatteryTimeToFull=$(cat battery_info.txt | grep -i AvgTimeToFull | tr '\n' ' | ' | awk '{printf("%i:%.2i", $3/60, $3%60)}')
		BatteryTime=$(echo $BatteryTimeToFull until full)
		BatteryStatus=Charging
	else
		BatteryFullyCharged=$(cat battery_info.txt | grep -i FullyCharged | awk '{printf("%s",$3)}')
		BatteryOnExternal=$(cat battery_info.txt | grep -i ExternalConnected | awk '{printf("%s",$3)}')
		if [ $BatteryFullyCharged == Yes ]; then 
			if [ $BatteryOnExternal == Yes ]; then
				BatteryTime=$(echo on AC power)
				BatteryStatus=
			else
				BatteryTime=$(echo $BatteryTimeLeft left)
			fi
		else
			BatteryTime=$(echo $BatteryTimeLeft left)
		fi
	fi
	addResult "battery2.Battery" "" "$BatteryTitle" "Laptop $BatteryStatus $BatteryTime  ($BatteryCycles cycles $BatteryHealth% healthy)" "macbook.png" "no" ""
fi


# trackpad
TrackpadPercent=`ioreg -c BNBTrackpadDevice | grep BatteryPercent | sed 's/[a-z,A-Z, ,|,",=]//g' | tail -1 | awk '{print $1}'`
if [ ${#TrackpadPercent} = 0 ]
then
	TrackpadTitle="Not connected"
else
	TrackpadSlug=$(python -c "f='●'*($TrackpadPercent/10) + '○'*(10-$TrackpadPercent/10);print f")
	TrackpadTitle="$TrackpadPercent% $TrackpadSlug"
fi

# mouse
MousePercent=`ioreg -c BNBMouseDevice | grep BatteryPercent | sed 's/[a-z,A-Z, ,|,",=]//g' | tail -1 | awk '{print $1}'`
if [ ${#MousePercent} = 0 ]
then
	MouseTitle="Not connected"
else
	MouseSlug=$(python -c "f='●'*($MousePercent/10) + '○'*(10-$MousePercent/10);print f")
	MouseTitle="$MousePercent% $MouseSlug"
fi

# keyboard
KeyboardPercent=`ioreg -c AppleBluetoothHIDKeyboard | grep BatteryPercent | sed 's/[a-z,A-Z, ,|,",=]//g' | tail -1 | awk '{print $1}'`
if [ ${#KeyboardPercent} = 0 ]
then
	KeyboardTitle="Not connected"
else
	KeyboardSlug=$(python -c "f='●'*($KeyboardPercent/10) + '○'*(10-$KeyboardPercent/10);print f")
	KeyboardTitle="$KeyboardPercent% $KeyboardSlug"
fi


# alfred results
# create feedback entries
# addResult "uid" "arg" "title" "subtitle" "icon" "valid" "autocomplete"
addResult "battery2.Keyboard" "" "$KeyboardTitle" "Keyboard" "keyboard.png" "no" ""
addResult "battery2.Trackpad" "" "$TrackpadTitle" "Trackpad" "trackpad.png" "no" ""
addResult "battery2.Mouse" "" "$MouseTitle" "Mouse" "mouse.png" "no" ""

getXMLResults