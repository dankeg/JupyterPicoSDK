from setuptools import setup, find_packages

setup(
    name="Pico_SDK_Kernel",
    version="0.1.0",
    description="A custom Jupyter kernel for PicoSDK.",
    packages=find_packages(),
    entry_points={
        "console_scripts": [
            "pico_kernel = pico_kernel.kernel:main",
        ]
    },
    install_requires=[
        "ipykernel",
        "pyserial",  
    ],
)
