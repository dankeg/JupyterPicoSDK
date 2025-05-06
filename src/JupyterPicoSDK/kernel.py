import os
import sys
import subprocess
import tempfile
import logging
import time
from ipykernel.kernelapp import IPKernelApp
from ipykernel.kernelbase import Kernel
import serial
from importlib import resources, files

from src.JupyterPicoSDK.libs.libs import execute_script, find_pico_port

TIMEOUT = 20


class PicoKernel(Kernel):
    implementation = "pico_kernel"
    implementation_version = "0.1"
    language_info = {"name": "c", "mimetype": "text/x-csrc", "file_extension": ".c"}
    banner = "Pico Kernel - a custom kernel for Raspberry Pi Pico"

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def do_execute(
        self, code, silent, store_history=True, user_expressions=None, allow_stdin=False
    ):
        """Handles execution of a cell in the notebook by a user.

        Performs 4 Primary Tasks:
        1. Exports code to a main.c file, serving as the entrypoint.
        2. Uses the docker container to build executable binaries.
        3. Flashes code to the Pico, starting execution.
        4. Reads Stdout, presenting it within Jupyter
        """
        self.log.info("Performing Execution!")

        if not code.strip():
            return self._response_ok("")

        source_path = os.path.join(os.getcwd(), "main.c")
        with open(source_path, "w") as f:
            f.write(code)

        final_output = f"Wrote code to {source_path}"

        self.log.info("Performing Build!")

        script_path = resources.files("JupyterPicoSDK.resources").joinpath("build_code.sh")
        script_output = execute_script(str(script_path), self)

        self.log.info("Finished Build!")

        script_path = resources.files("JupyterPicoSDK.resources").joinpath("load_code.sh")
        script_output = execute_script(str(script_path), self)

        time.sleep(2)

        self.log.info("Starting Serial Connection!")
        pico_port = find_pico_port()
        if pico_port is None:
            self.log.info("Connection Failure!")
            return self._response_error("No Pico found via USB serial.")

        self._stream_message(f"Reading output from {pico_port}...\n")
        try:
            with serial.Serial(pico_port, 115200, timeout=0.5) as ser:
                end_time = time.time() + TIMEOUT
                while time.time() < end_time:
                    line = ser.readline()
                    if line:
                        self._stream_message(line.decode(errors="replace"))
                        end_time = time.time() + TIMEOUT
        except Exception as e:
            return self._response_error(f"Serial read error: {str(e)}")

        return self._response_ok("Finished reading Pico output.")

    def _response_ok(self, text):
        """Return a standard 'ok' execution result."""
        return {
            "status": "ok",
            "execution_count": self.execution_count,
            "payload": [],
            "user_expressions": {},
            "data": {"text/plain": text},
        }

    def _response_error(self, text):
        """Return an error execution result."""
        return {
            "status": "error",
            "ename": "PicoKernelError",
            "evalue": text,
            "traceback": [text],
        }

    # --- Comm message stubs ---
    def comm_open(self, stream, ident, parent):
        self.log.info("comm_open called - ignoring for now.")

    def comm_msg(self, stream, ident, parent):
        self.log.info("comm_msg called - ignoring for now.")

    def comm_close(self, stream, ident, parent):
        self.log.info("comm_close called - ignoring for now.")

    def _stream_message(self, text):
        self.send_response(
            self.iopub_socket, "stream", {"name": "stdout", "text": text}
        )


def main():
    IPKernelApp.launch_instance(kernel_class=PicoKernel, log_level=logging.INFO)


if __name__ == "__main__":
    main()
