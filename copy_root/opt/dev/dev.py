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
import threading
import time
from typing import Callable, List

CMD_HA = ["/usr/local/bin/hass", "--config", "/config", "--ignore-os-check", "--verbose"]
#CMD_HA = ["/bin/ping", "1.1.1.1"]


def _cb_echo_output(self: 'Run', out: str, err: bool):
    """helper method to echo output."""
    fg = 'yellow' if err else 'blue'
    click.echo(click.style(out.rstrip('\n'), fg=fg))

class Run(object):
    """Helper class to run and inspect a subprocess."""
    
    def __init__(self, args: List[str]):
        self._args = args
        self._p = None
        self._output_callbacks = []
        self.log = []
        
    def do_echo_output(self):
        if _cb_echo_output not in self._output_callbacks:
            self.register_output_callback(_cb_echo_output)
        return self
        
    def register_output_callback(self, func: Callable[['Run', str, bool], str]) -> 'Run':
        """Register output callbacks. Anything a callback returns will be added to self.log."""
        self._output_callbacks.append(func)
        return self
        
    def run(self) -> bool:
        """Run the process."""
        self._p = subprocess.Popen(
            self._args,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            close_fds=True,
        )
        #read both outputs
        out_thread = threading.Thread(
            target=lambda: self._read_loop(self._p.stdout, err=False)
        )
        err_thread = threading.Thread(
            target=lambda: self._read_loop(self._p.stderr, err=True)
        )
        out_thread.start()
        err_thread.start()
        out_thread.join()
        err_thread.join()
        return self._p.poll()

    def terminate(self, timeout: int):
        """send terminate to a prcess. After timeout (if set), kill the process."""
        self._p.terminate()
        cnt = 0
        while self._p.poll() is None:
            if timeout and cnt >= timeout:
                self._p.kill()
            time.sleep(1)
            cnt += 1
            
    def _on_output(self, s: str, err: bool):
        for cb in self._output_callbacks:
            log = cb(self, s, err)
            if log:
                self.log.append(log)
        
    def _read_loop(self, pipe, err):
        for line in pipe:
            self._on_output(line, err)
    
    def get_pid(self):
        if self._p is None:
            return None
        return self._p.pid

def _get_matching_files(folder: str, file_pattern: str):
    """get all matching files in a directory."""
    matching_files = []
    for root, _, files in os.walk(folder):
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

@ha.command()
@click.option("--install-deps-only", is_flag=True, help="Start HA, download dependencies, then stop.")
def start(install_deps_only: bool):
    """Run Home Assistant."""
    
    r = Run(CMD_HA) \
        .do_echo_output()
    
    cnt_dep_err = 0
    if install_deps_only:
        def cb_count_dep_errors(run: 'Run', out: str, err: bool):
            nonlocal cnt_dep_err
            if "ModuleNotFoundError" in out:
                cnt_dep_err += 1
        def cb_exit_condition(run: 'Run', out: str, err: bool):
            if "[homeassistant.bootstrap] Home Assistant initialized in" in out:
                run.terminate(60)
        r \
            .register_output_callback(cb_count_dep_errors) \
            .register_output_callback(cb_exit_condition)
        
    err_level = r.run()
    
    if install_deps_only:
        #stop successfully, when all dependencies could be installed
        sys.exit(cnt_dep_err)
    sys.exit(err_level)

@cli.group()
def component():
    """custom_components commands."""

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
                
# # debug
# if __name__ == '__main__':
#     cli(["ha", "start", "--install-deps-only"])
