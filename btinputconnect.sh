#!/bin/bash

# MAC address of the Bluetooth device (your keyboard)
device_mac="50:E6:76:A6:49:A0"

# Function to check if the device is connected
is_device_connected() {
    bluetoothctl info "$device_mac" | grep -q "Connected: yes"
}

# Function to get the device name
get_device_name() {
    bluetoothctl info "$device_mac" | grep "Name:" | cut -d ' ' -f 2-
}

# Function to display a KDE notification
show_notification() {
    notify-send "$1" "$2"
}

# Connect to the device
connect_device() {
    bluetoothctl connect "$device_mac"
}

# Maximum number of retries
max_retries=30

# Retry for up to 30 seconds or until successful
retries=0
while [ $retries -lt $max_retries ]; do
    connect_device
    if is_device_connected; then
        device_name=$(get_device_name)
        show_notification "Bluetooth Keyboard Connected" "Connected to $device_name."
        exit 0
    else
        if [ $retries -eq 0 ]; then
            show_notification "Bluetooth Keyboard Pairing" "Please press the pairing button on your keyboard."
        fi
        echo "Retrying in 1 second..."
        sleep 1
        retries=$((retries + 1))
    fi
done

# If we couldn't connect after 30 seconds, exit with an error
show_notification "Failed to Connect" "Failed to connect to the Bluetooth device after 30 seconds."
exit 1
#!/bin/bash

# Configuration section (customizable)
max_retries=30                  # Retry for up to 30 seconds

# Function to check if a device is a Bluetooth input device
is_input_device() {
    local device_mac="$1"
    local device_info
    device_info=$(bluetoothctl info "$device_mac")
    # Check if the device info contains the word "Mouse" or "Keyboard"
    if [[ $device_info =~ "Mouse" || $device_info =~ "Keyboard" ]]; then
        return 0  # It's an input device
    else
        return 1  # It's not an input device
    fi
}

# Function to get the device name
get_device_name() {
    local device_mac="$1"
    bluetoothctl info "$device_mac" | grep "Name:" | cut -d ' ' -f 2-
}

# Function to display a KDE notification
show_notification() {
    notify-send "$1" "$2"
}

# Function to connect to the device in the background
connect_device_background() {
    local device_mac="$1"
    connect_device "$device_mac" &
}

# Connect to the device
connect_device() {
    local device_mac="$1"
    retries=0
    while [ $retries -lt $max_retries ]; do
        if is_input_device "$device_mac"; then
            device_name=$(get_device_name "$device_mac")
            show_notification "Bluetooth Input Device Connected" "Connected to $device_name."
            break
        else
            if [ $retries -eq 0 ]; then
                show_notification "Bluetooth Input Device Pairing" "Please press the pairing button on the device."
            fi
            echo "Retrying in 1 second..."
            sleep 1
            retries=$((retries + 1))
        fi
    done
}

# Get a list of available Bluetooth devices
devices=($(bluetoothctl devices | awk '{print $2}'))

# Run connection attempts in parallel
for device_mac in "${devices[@]}"; do
    connect_device_background "$device_mac"
done

# Wait for all background processes to complete
wait

# Notify when all attempts are done
show_notification "Bluetooth Input Device Connection Complete" "Connection attempts completed."
