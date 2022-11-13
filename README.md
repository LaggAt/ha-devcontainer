# ha-devcontainer

> INCOMPLETE I'm working on this. Until I'm ready, this describes my wishes. INCOMPLETE

This is a container to develop a HACS/HASS integration. It will feature:

* Develop on a Remote Raspberry Pi4 x64 (to develop on the same platform running on later)
* Bluetooth / BLE is working as in the live Home Assistant container
* Live and Test system may be on the same system, and are separated (Test system uses TCP port 9123)
* Home Assistant, HACS and some useful Extensions preinstalled
* black, pytest, ...

## Development progress

For now I have a container which should be useable.
It's based on [the official DevContainer for Addons](https://github.com/home-assistant/devcontainer/blob/main/addons/Dockerfile)
but should also be usable in Raspbian 64bit. Until here I developed the container on Windows, seems I need to switch to the PI now.
I have some concerns the Supervisor installer 

## Usage

Latest container for AMD64, ARM and ARM64 is here:
https://hub.docker.com/repository/docker/laggat/ha-devcontainer

TODO: Example project using the container remotely on a Raspberry PI 4 will follow.

## Contribute

### by donating a coffee or two:

[![Buy me a Coffee](https://media.giphy.com/media/o7RZbs4KAA6tvM4H6j/giphy.gif)](https://www.buymeacoffee.com/LaggAt)

### help with coding:

Feel free to add pull requests, issues, whatever. Thanks.

## Credits

This container is partly based on the excelent container by ludeeus

https://github.com/ludeeus/container / [MIT License](https://github.com/ludeeus/container/blob/main/LICENSE)

Base images and some ideas are taken from the Microsoft vscode-dev-containers

https://github.com/microsoft/vscode-dev-containers / [MIT License](https://github.com/microsoft/vscode-dev-containers/blob/master/LICENSE)

Thanks for the hard work on these containers, which helped me to get up and running fast.

## License

This is also licensed using [MIT License](LICENSE), so have fun and build great things with it.


## How to use this

I owe you a howto. Or an small sample integration. 
