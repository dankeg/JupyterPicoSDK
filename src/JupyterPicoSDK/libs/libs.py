import os
import subprocess

import serial
from serial.tools import list_ports
import time


def execute_script(script_name="test.sh", env=None) -> str:
    """Runs script with respect to the root of the project, returning stdout from a successful execution.

    Args:
        script_name (str, optional): Name of the script to run. Defaults to "test.sh".
        env (PicoKernel, optional): PicoKernel environment to log progress to. Defaults to None.

    Returns:
        str: Stdout from a successful execution of the script.
    """
    env.log.info("Executing Script!")
    root_dir = os.path.abspath(os.getcwd())
    script_path = os.path.join(root_dir, script_name)

    try:
        completed = subprocess.run(
            ["/bin/bash", script_path],
            cwd=root_dir,
            capture_output=True,
            text=True,
            check=True,
        )
        env.log.info(f"Success! {completed}")
    except subprocess.CalledProcessError as e:

        env.log.info(f"Failure: {e.stderr}")
        raise

    return completed.stdout


def find_pico_port():
    """
    Returns the serial port device (e.g. '/dev/ttyACM0', 'COM3', '/dev/tty.usbmodem1234')
    for the first connected Raspberry Pi Pico, or None if not found.
    """
    pico_vid = 0x2E8A
    pico_pids = {0x000A, 0x000B}

    for port_info in list_ports.comports():
        if port_info.vid == pico_vid and port_info.pid in pico_pids:
            return port_info.device

    return None
