import io
import os
import subprocess
import sys
import time
from parse import parse
from datetime import datetime

def get_drive_info():
    # Use the 'lsblk' command to list block devices and their information
    result = subprocess.run(['lsblk', '-o', 'NAME,TYPE,MOUNTPOINT'], stdout=subprocess.PIPE, text=True)
    
    # Parse the output to find the DVD drive
    drive_info = []
    for line in result.stdout.splitlines():
        if 'rom' in line:  # 'rom' indicates a DVD drive
            drive_info.append(line.strip())
    
    return drive_info

def get_device():
    drive_info = get_drive_info()
    if drive_info:
        return "/dev/" + drive_info[0].split()[0]  # Return the device name of the first DVD drive found
    else:
        return None

def get_dvd_info(device):
    result = subprocess.run(['dvdbackup', '--info', '--input', device], stdout=subprocess.PIPE, text=True)
    
    return result.stdout

def get_dvd_title(dvd_info):
    for line in dvd_info.splitlines():
        if line.startswith("DVD-Video information of the DVD with title"):
            result = parse("DVD-Video information of the DVD with title \"{}\"", line)
            return result[0]
    return None

def extract_dvd(device, output_dir):
    # Use the 'dvdbackup' command to extract the DVD contents
    subprocess.run(['dvdbackup', '--input', device, '--output', output_dir, '--title', 'all'])

def main():
    print(f"rip dvd")

    device = get_device()
    if (device is None):
        sys.exit("No DVD drive found.")

    print(f"Using input device {device}")

    dvd_info = get_dvd_info(device)

    dvd_title = get_dvd_title(dvd_info)
    if (dvd_title is None):
        dvd_title = datetime.now().strftime("%Y%m%d_%H%M%S")  # Use current date and time as title if not found

    print(f"DVD title: {dvd_title}")

    output_dir = os.path.join("./trip", dvd_title)

    print(f"Output to: {output_dir}")

    os.makedirs(output_dir, exist_ok=True)

    log_file = os.path.join(output_dir, "rip.log")
    rip_dir = os.path.join(output_dir, "rip")
    command = ['dvdbackup', '--mirror', '--input', device, '--output', rip_dir]

    os.makedirs(rip_dir, exist_ok=True)

    with io.open(log_file, "w") as writer, io.open(log_file, "r", 1) as reader:
        process = subprocess.Popen(command, stdout=writer)
        try:
            while process.poll() is None:
                sys.stdout.write(reader.read())
                time.sleep(0.5)
            # Read the remaining
            sys.stdout.write(reader.read())
        except KeyboardInterrupt:
            process.terminate()
            print("Rip process terminated by user.")


if __name__ == "__main__":
    main()

