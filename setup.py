# setup.py  (minimal but robust)
from pathlib import Path
from setuptools import setup
from setuptools.command.install import install
import os, sys


class InstallWithDeps(install):
    """Registers the kernelspec after the real install finishes."""

    def run(self):
        super().run()  # ← copies files into self.install_lib

        # Put the just‑installed site‑packages dir on sys.path
        sys.path.insert(0, str(Path(self.install_lib).resolve()))

        # When building a wheel we don't want to run any post‑install hooks.
        # Detect that case and bail out early.
        if os.environ.get("PICO_SKIP_POSTINSTALL") == "1" or "bdist_wheel" in sys.argv:
            return

        # Now the import works
        from JupyterPicoSDK.post_install import _install_kernelspec

        _install_kernelspec()  # adds kernelspec to the user dir


setup(
    cmdclass={"install": InstallWithDeps},
)
