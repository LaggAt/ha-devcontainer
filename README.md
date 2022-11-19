# ha-devcontainer

This is a container to develop a HACS/HASS integration. It features / will feature:

* *(done)* Fast development cycles. Fast startup of Home Assistant.
* *(done)* 'dev' cli tool for quick actions [usage and tab completion see here](docs/CLI_dev.md)
* *(testing)* Develop on a Remote Raspberry Pi4 x64 (to develop on the same platform running on later)
* *(testing)* Bluetooth / BLE is working as in the live Home Assistant container
* *(testing)* Live and Test system may be on the same system, and are separated (Test system uses TCP port 9123)
* Home Assistant, HACS and some useful Extensions preinstalled and all dependencies fulfilled at container build time (for fast startup)
* *(todo)* black, pytest, ...

This is *work in progess*, this is why the done/testing/todo marks are there.

## Usage

Latest container for AMD64, ARM and ARM64 is here:
https://hub.docker.com/repository/docker/laggat/ha-devcontainer

There is a minimal custom_component to showcase the use of this container. You can find it here:

[Jokes integration: Sensor showing new Joke every minute.](https://github.com/LaggAt/ha-jokes)

btw: thanks to [icanhazdadjoke.com](https://icanhazdadjoke.com/), they provide the Jokes and it was really fun reading these while developing. Also they were very nice when talking to them about that Idea.

The integration lacks good documentation and usage of the devcontainer on the Raspberry remotely, this is still on my TODO list.

## Contribute

### by donating a coffee or two

[![Buy me a Coffee](https://media.giphy.com/media/o7RZbs4KAA6tvM4H6j/giphy.gif)](https://www.buymeacoffee.com/LaggAt)

### help with coding:

Feel free to add pull requests, issues, whatever. Thanks.

## Credits

The idea for that container and some concepts are from the excelent container by ludeeus. Thanks alot!

https://github.com/ludeeus/container / [MIT License](https://github.com/ludeeus/container/blob/main/LICENSE)

Base images and some ideas are taken from the Microsoft vscode-dev-containers

https://github.com/microsoft/vscode-dev-containers / [MIT License](https://github.com/microsoft/vscode-dev-containers/blob/master/LICENSE)

Thanks for the hard work on these containers, which helped me to get up and running fast.

'dev' cli Tool makes a lot of use from the [click_](https://click.palletsprojects.com/) project. It saved a lot of work with command line handling and tab completion.

## License

This is also licensed using [MIT License](LICENSE), so have fun and build great things with it.
