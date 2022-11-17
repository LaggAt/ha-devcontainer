# Copyright (c) 2022 Florian Lagg
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import click
import fnmatch
import json
import os
import subprocess
import sys
import time
from typing import List

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

def _get_matching_files(dir: str, file_pattern: str):
    """get all matching files in a directory."""
    matching_files = []
    for root, _, files in os.walk(dir):
        for file in files:
            if fnmatch.fnmatchcase(file, file_pattern):
                fn = f"{root}/{file}"
                matching_files.append(fn)
    return matching_files

@click.group()
def cli():
    pass
    
    
    
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
        # we are OK with stopping HA, so ignore exit code.
        sys.exit(0)
    else:
        #keep running to keep HA process alive
        for out in iter(p.stdout.readline, ""):
            click.echo(click.style(out.rstrip('\n'), fg='blue'))
    sys.exit(p.poll())



@cli.group()
def component():
    """custom_components commands."""
    pass

@component.command()
@click.option("--all", is_flag=True, help="Activate all components. Explicitly listed domains are excluded.")
@click.argument("domains", nargs=-1, type=str)
def activate(all: bool, domains: List[str]):
    """Activate a components from /workspaces folder."""
    if not os.path.exists("/config/custom_components"):
        os.mkdir("/config/custom_components")
    for manifest_file in _get_matching_files("/workspaces", "manifest.json"):
        domain = None
        try:
            f = open(manifest_file, "r")
            domain = json.load(f)["domain"]
        except Exception as ex:
            click.echo(f"cannot read domain from '{manifest_file}': {ex}")
        # valid domain
        if domain:
            # domain is listed explicitly
            listed = domain in domains
            do_add = True
            if all:
                if listed:
                    # exclude listed
                    do_add = False
            else:
                if not listed:
                    # exclude not listed
                    do_add = False
            
            # not in exclude listed mode
            if do_add:
                source = os.path.dirname(manifest_file)
                target = f"/config/custom_components/{domain}"
                if os.path.exists(target):
                    click.echo(f"'{domain}' for '{target}' already activated.")
                else:
                    click.echo(f"'{domain}' for '{target}' activated")
                    os.symlink(source, target)
                
