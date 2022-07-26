I've recently got a [HiFive Unmatched](https://www.sifive.com/boards/hifive-unmatched), *the world’s fastest native RISC-V development platform*. Despite being a nice board to play with RISC-V with a nice Mini-ITX form factor and decent performance, it has a 25mm fan which is **REALLY loud**. 

To make my experience with it more enjoyable by putting it away from my already crowed desktop, I bought a AX200 Wi-Fi adaptor (whose price has rocketed recently), which do solve the problem to a certain extent. But at the cost of loosing access to HDMI output, serial console and most importantly, the power button. 

Luckily, I still have a rpi lying around, armed with hardware video encoding, a bunch of USB ports, and GPIO. With a little setup, the rpi can serve as a BMC for the unmatched, restoring my access to that, nice, clicky, power button.

#### HDMI
For HDMI output, you would need a HDMI to USB adaptor. And to stream the video, I recommend using [µStreamer](https://github.com/pikvm/ustreamer) from the PiKVM project.

```shell
ustreamer \
  -r 1920x1080 # the default resolution is far too low
  -s :: # or only listens on localhost
  -p 8080 # pick a nice port to work with
```

#### UART and JTAG
The unmatched board has a builtin UART/JTAG to USB adaptor, thus connecting the console port directly to a USB port with the supplied cable is sufficient. To access the USB adaptor remotely, `usbip` can be used.

```shell
# server
# load usbip kernel module
modprobe usbip_host
# start control daemon
usbipd
# list available local devices
usbip list -l
# export USB device
usbip bind -b <busid>

# client
# load vhci-hcd kernel module
modprobe vhci-hcd
# list available remote devices
usbip list -r <server>
# attach remote device locally
usbip attach -r <server> -b <busid>
```

Now you can use the serial port and JTAG interface locally. For baremetal programming, a nice debugger like gdb would come in handy. We can use [OpenOCD](https://openocd.org/pages/about.html), the Open On-Chip Debugger to run a gdb server. While there is no official configuration for reference, I managed to fine usable pieces in a random reddit post [HiFive Unmatched + OpenOCD + GDB: Beginning bare metal programming on high-performance RISC-V board](https://web.archive.org/web/20211006094715/https://www.reddit.com/r/RISCV/comments/no4a3e/hifive_unmatched_openocd_gdb_beginning_bare_metal/).

#### power button
While having on board power and reset buttons, they are barely usable when enclosed in the chassis. Still, the board has standard front panel connectors for power buttons and indicators. By reading the schematics, I'm confident that they can be connected directly to the GPIO ports on rpi without risking buring anything. But one can never be too careful, I bought a few optically-isolated relays, and they work like a charm.
```shell
# 1 sec for a normal click, 4 sec for force off
gpioset -m time -s <sec> gpiochip0 <port>=1; gpioset gpiochip0 <port>=0
```

#### boot
It's not uncommon to render your system unbootable when playing around, being able to boot from the network or other media is a necessity to recover access. Normally the unmatched boot from the sdcard, where the target system also resides, making the creation of bootable system images somewhat hard. But with patches from [riscv: Support booting SiFive Unmatched from SPI](https://github.com/u-boot/u-boot/commit/6a863894ad53b2d0e6c6d47ad105850053757fec), it can also boot into u-boot from SPI flash, from which you can boot further into your target system. For the lazy, a prebuilt image can be downloaded from [bootrom.bin](https://hydra.nichi.co/job/nixos/riscv/bootrom-unmatched/latest/download-by-type/file/bin).

With the riscv-openocd fork, you can write uboot directly into the flash with JTAG
```tcl
adapter speed  10000
adapter driver ftdi

ftdi device_desc "Dual RS232-HS"
ftdi vid_pid     0x0403 0x6010

ftdi layout_init   0x0008 0x001b
ftdi layout_signal nSRST -oe 0x0020
ftdi layout_signal LED -data 0x0020

jtag   newtap riscv cpu -irlen 5
target create cpu0 riscv -chain-position riscv.cpu -rtos hwthread
cpu0   configure -work-area-phys 0x8000000 -work-area-size 0x2710 -work-area-backup 1

flash bank spi0 fespi 0x20000000 0 0 0 cpu0 0x10040000
init
halt

set filename flash.bin
flash erase_sector 0 0    last
flash write_bank   0 $filename
flash verify_bank  0 $filename

echo "flash succeeded"
```

To take it further, it's even possible to boot directly from JTAG, [Don’t fear the bricking (unbricking Unmatched via JTAG)](https://forums.sifive.com/t/dont-fear-the-bricking-unbricking-unmatched-via-jtag/5449). An optimized version of the provided configuration is below:
```tcl
adapter speed   10000
adapter driver  ftdi

ftdi_device_desc "Dual RS232-HS"
ftdi_vid_pid 0x0403 0x6010
ftdi_layout_init 0x0008 0x001b
ftdi_layout_signal nSRST -oe 0x0020 -data 0x0020

set _CHIPNAME riscv
transport select jtag
jtag newtap $_CHIPNAME cpu -irlen 5

target create $_CHIPNAME.cpu0 riscv -chain-position $_CHIPNAME.cpu -coreid 0 -rtos hwthread
target create $_CHIPNAME.cpu1 riscv -chain-position $_CHIPNAME.cpu -coreid 1
target create $_CHIPNAME.cpu2 riscv -chain-position $_CHIPNAME.cpu -coreid 2
target create $_CHIPNAME.cpu3 riscv -chain-position $_CHIPNAME.cpu -coreid 3
target create $_CHIPNAME.cpu4 riscv -chain-position $_CHIPNAME.cpu -coreid 4
target smp $_CHIPNAME.cpu0 $_CHIPNAME.cpu1 $_CHIPNAME.cpu2 $_CHIPNAME.cpu3 $_CHIPNAME.cpu4

init

proc load_uboot {} {
    reset halt
    load_image u-boot-spl.bin 0x08000000 bin
    wp 0x84000000 0x1000
    resume 0x08000000
    # longer timeout for usbip
    wait_halt 50000
    rwp 0x84000000
    load_image u-boot.itb 0x84000000 bin
    verify_image u-boot.itb 0x84000000 bin
    resume
}

load_uboot
```
Prebuilt patched uboot can be downloaded from [here](https://hydra.nichi.co/job/nixos/riscv/uboot-unmatched-ram/latest).

#### flashing
JTAG is painfully slow and thus should only serve as a mean for rescuing a bricked system. Now that you have booted into uboot, the next step is to *flash* a disk image into the onboard nvme drive. Luckily, uboot has native support for writing nvme devices, thus we do not need another level of indirection.

First, connect the board to your computer with an ethernet cable, and configure tftp and dhcp servers to run on that interface. Then prepare your disk image, prebuilt images for ubuntu can be found at [ubuntu 21.10](http://cdimage.ubuntu.com/releases/21.10/release/), make sure to decompress the image beforehand and serve it with tftp. The rest is now handled by the following uboot commands.

```
dhcp
setenv serverip <ip>
tftp 0x100000000 <filename>
pci enum
nvme scan
nvme info
nvme write 0x100000000 0 <block cnt>
```
`0x100000000` is just a randomly choosen memory address that has enough headroom to place the whole image. Block count can be calculated by `stat` the image file, but don't forget to take into account the block size.

#### list of additional hardware
- [HDMI to USB adaptor](https://item.m.jd.com/product/100015021338.html) 65 CNY
- [optically isolated relay](https://item.m.jd.com/product/10028350223255.html) 10 CNY

#### reference configuration
A reference configuration of all services documented in this article can be found at [https://github.com/NickCao/flakes/blob/master/nixos/rpi/configuration.nix](https://github.com/NickCao/flakes/blob/master/nixos/rpi/configuration.nix)
