&nbsp; &nbsp; &nbsp; &nbsp;Arch，最近迎来了一个重大的改变，base组改为了base元包，也即默认安装的最小系统更加精简（内核都可选了......（Arch/NT安排一下？当然Archwiki中的安装教程也有了相应的变化。但这只是一个契机，另一个契机是Gentoo handbook，虽然我曾是个distro hopper，却不曾试过Gentoo（我曾用的三代i3说它真的不可以......

&nbsp; &nbsp; &nbsp; &nbsp;好的上面都是废话，重点在于在安装Gentoo上的底裤时（我就是不用OpenRC了！发现hostname与locale等的设定都使用了hostnamectl等，而非如Arch所采取的手改配置文件的方法（然而这需要一个运行中的底裤d（把chroot换成nspwan不就好了？

archlinux - the elegant way
```bash
#（这里跳过了很多步骤，好孩子可不要学哦
# boot the live environment
# connect to the internet
timedatectl set-ntp true
# partition the disks
# format the partitions
# mount the file systems
pacstrap /mnt base linux nano # 这点包是肯定不够的呢
genfstab -U /mnt >> /mnt/etc/fstab
echo 'pts/0' >> /mnt/etc/securetty # 这一步很关键呢（不然root是无法从pts/0登录的
systemd-nspawn -b -D /mnt
#login as root
timedatectl set-timezone Asia/Shanghai # 为什么不是北京呢？这是历史遗留问题呢
hwclock --systohc
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
localectl set-locale en_US.UTF-8
hostnamectl set-hostname <hostname>
passwd
# install the bootloader
# 搞定！
```