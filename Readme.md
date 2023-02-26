sweetRV
======

This is a fork of [femtorv](https://github.com/BrunoLevy/learn-fpga) which is directly ported to work on IceSugar-nano FPGA boards. Kudos to the original authors.

<img src="https://raw.githubusercontent.com/Archfx/ice40lib/main/images/ice40.jpeg" alt="docker" width="200" align="right">

Summary
------

This repository contains RISCV processor that can be packed withing 1200LUTs with rv32i tool chain. There are bunch of firmware examples to try. You can use the docker enronment direclty without installing any dependancies.


Get Started
=======

Docker Image
-------


<p align="center">
  <img src="https://dockerico.blankenship.io/image/archfx/ice40tools" alt="Sublime's custom image"/>
</p>

Follow the steps to build usign the docker environemt. (You should have the docker deamon installed on your system)

1. Clone the repository

```shell
git clone https://github.com/Archfx/sweetRV
```

2. Pull the docker image from docker-hub


```shell
docker pull archfx/ice40tools
```

3. Set the expected location to mount with the container
```shell
export LOC=/sweetRV
```

4. Run the Docker image
```shell
docker run -t -p 6080:6080 -v "${PWD}/:/$LOC" -w /$LOC --name ice40tools archfx/ice40tools
```

5. Connect to the docker image

```shell
docker exec -it ice40tools /bin/bash
```

Build the Binary
-------
Now the environment is ready. Next, we need to compile the firmware. This step will take the assembly files/ c source files and generate a hex file that is the firmware for our processor.

```shell
$ cd FIRMWARE/EXAMPLES
$ make hello.hex
```
This will generate the hex file of the firmware. Next we need to build the hardware with inbuilt firmware. For that follow the below steps from the main folder.

```shell
$ make ICESUGAR_NANO
```

This will produce the file `femtosoc.bin` at the home folder. You can directly upload this to the FPGA by drag and drop.

Terminal of RV32
------

Firmware contains different example applications which you can run on your FPGA. In order to talk with processor using UART you need to install a terminal emulator application (screen/picocom). 

Below are the steps for the `screen` terminal to talk with your processor. Use `command + a + \` to exit.

- on Mac
```shell
brew  install screen 
```
```shell
/opt/homebrew/Cellar/screen/4.9.0_1/bin/screen /dev/tty.usbmodem102 115200
```
- on Ubuntu

```shell
apt-get install screen 
```
```shell
screen /dev/ttyUSB1 115200
```