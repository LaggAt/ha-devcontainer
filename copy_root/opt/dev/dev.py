# Copyright (c) 2022 Florian Lagg
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import click

@click.command()
def cli():
    """Example script."""
    click.echo('Hello World!')