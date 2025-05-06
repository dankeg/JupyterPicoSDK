"""
Helpers run after `pip install`.
"""

from importlib import resources
from pathlib import Path
import json, subprocess, sys


def _install_kernelspec():
    import jupyter_client
    from tempfile import TemporaryDirectory
    
    with TemporaryDirectory() as tmp:
        # copy resources/kernel.json + launcher script paths
        kernel_json = json.loads(
            resources.files("JupyterPicoSDK.resources").joinpath("kernel.json").read_text()
        )
        # point to the python executable inside the current venv
        kernel_json["argv"] = [
            sys.executable,
            "-m",
            "JupyterPicoSDK.kernel",
            "-f",
            "{connection_file}",
        ]

        spec_dir = Path(tmp) / "pico-sdk"
        spec_dir.mkdir()
        (spec_dir / "kernel.json").write_text(json.dumps(kernel_json))
        jupyter_client.kernelspec.install_kernel_spec(
            str(spec_dir), "pico-sdk", user=True, replace=True
        )


def run_install_script():
    """
    CLI helper: `pico-sdk-install-deps`
    """
    import subprocess, shutil, os, platform, textwrap

    script = resources.files("JupyterPicoSDK.resources").joinpath(
        "install_dependencies.sh"
    )
    print("▶ Executing system‑dependency installer…")
    subprocess.check_call(["bash", str(script)])


class _Installer:
    """Subclassed in setup.py if you opt for auto‑run (see §5.2)."""

    def run(self):
        super().run()
        _install_kernelspec()
