# Copyright (c) 2022 Florian Lagg
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import click
import subprocess
import sys
import time

def _run_ha_and_await_output(s: str):
    p = subprocess.Popen(
        ["/usr/local/bin/hass", "--config", "/config", "--ignore-os-check", "--verbose"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )
    click.echo("HA started with PID %s." % p.pid)
    for out in iter(p.stdout.readline, ""):
        click.echo(click.style(out.rstrip('\n'), fg='blue'))
        if s in out:
            click.echo("Found '%s' in stdout" % s)
            return p
    #process ran to completion before writing expected string
    raise Exception("Process exited returning %s" % p.returncode)

def _stop_process(p: subprocess.Popen):
    p.terminate()
    while p.poll() is None:
        time.sleep(1)

@click.group()
def cli():
    pass

@cli.command()
def hello():
    """Example script."""
    click.echo('Hello World!')
    
@cli.group()
def ha():
    """Home Assistant commands."""
    pass

@ha.command()
@click.option("--stop-on-init", default=False, help="After HA has initialized (and downloaded dependencies), stop HA again.")
def start(stop_on_init: bool):
    """Run Home Assistant."""
    p = _run_ha_and_await_output("[homeassistant.bootstrap] Home Assistant initialized in")
    click.echo("HA is initialized.")
    if stop_on_init:
        click.echo("Sending SIGTERM to HA.")
        _stop_process(p)
    sys.exit(p.returncode)
