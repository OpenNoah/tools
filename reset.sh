#!/bin/sh -e
# Control Raspberry Pi GPIOs

# GPIO definitions
reset=298
usbboot=388

if [ ! -d /sys/class/gpio/gpio$reset ]; then
	echo $reset > /sys/class/gpio/export
fi

if [ ! -d /sys/class/gpio/gpio$usbboot ]; then
	echo $usbboot > /sys/class/gpio/export
fi

usb=1
if [ "x$1" = "xusb" ]; then
	usb=0
fi

echo out > /sys/class/gpio/gpio$reset/direction
echo 0 > /sys/class/gpio/gpio$reset/value
echo out > /sys/class/gpio/gpio$usbboot/direction
echo $usb > /sys/class/gpio/gpio$usbboot/value

sleep 0.1
echo 1 > /sys/class/gpio/gpio$reset/value
