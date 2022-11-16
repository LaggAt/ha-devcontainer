# Copyright (c) 2022 Florian Lagg
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from setuptools import setup

setup(
    name='dev',
    version='0.0.1',
    py_modules=['dev'],
    install_requires=[
        'Click',
    ],
    entry_points={
        'console_scripts': [
            'dev = dev:cli',
        ],
    },
)