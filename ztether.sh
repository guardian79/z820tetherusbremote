#!/bin/bash


# Set path to adb binary
# adb="/opt/android-sdk/platform-tools/adb"
# adb="$HOME/dev/opt/android-sdk-linux/platform-tools/adb"
adb=$(which adb)

error() {
  echo $@
  exit 1
}

adb_check() {
  for i in `seq 1 10`
  do
    $adb devices 2>/dev/null | grep device$ >/dev/null && return 0
    echo -n "."
    sleep 1
  done
  return 1
}

rndis_enabled() {
  if $adb shell getprop sys.usb.config | grep rndis >/dev/null ; then
    return 0
  else
    return 1
  fi
}


tether_toggle() {
  # http://stackoverflow.com/questions/13850192/how-to-lock-android-screen-via-adb
  if [ "$(adb shell dumpsys power | grep "Display Power: state=" | grep -oE '(ON|OFF)')" == OFF ] ; then
    $adb shell input keyevent 26 # wakeup
    $adb shell input keyevent 82 # unlock
fi

  # go home
  $adb shell input keyevent 3
  # open tethering settings
  $adb shell am start -a android.intent.action.MAIN -n com.android.settings/.TetherSettings

  # wait 1 second to start activity
  sleep 1

  # move up - this always select first list item
  $adb shell input keyevent 19
sleep 1
case $MYTETHER in 
        wifi)
          $adb shell input keyevent 20
          $adb shell input keyevent 20 
                   sleep 1
                      ;;
       bt)
           $adb shell input keyevent 20 
                    sleep 1 
                  ;;
          usb)
             if rndis_enabled ; then
    echo "Tethering already enabled ... disabling..."
    fi


esac
 

# move down - select "USB tethering"
#  $adb shell input keyevent 20

  # toggle checkbox
  $adb shell input keyevent 66

  # alternatively, tap checkbox
  #$adb shell input tap 400 300

  # adb shell is unavailable for ~1 sec
  sleep 2

  # return home
  $adb shell input keyevent 3

  # turn off the screen
  $adb shell input keyevent 26
}

tether_enable() {
#  if rndis_enabled ; then
#    echo "Tethering already enabled"
#    return
#  fi

  echo "Toggle tethering checkbox"
  tether_toggle
}
tether_disable() {
#  if rndis_enabled ; then
       echo "Toggle tethering checkbox"
       tether_toggle   
#    return
#  fi
#       echo "Tethering already disabled"
}



# Main program
case $1 in
  usb)
    MYTETHER="usb"
             ;;
   wifi)
    MYTETHER="wifi"
             ;;
   bt)
    MYTETHER="bt"
              ;;
   *)
   error "Which network device usb / bt / wifi?"
    ;;
esac


if ! adb_check ; then
  error "No android devices found, exiting.."
fi


tether_toggle
