# oItsMineZKernel for OneUI 3/4 Exynos 9820/9825 Devices (S10/Note10)

<img src="https://github.com/KernelSU-Next/KernelSU-Next/blob/next/assets/kernelsu_next.png" style="width: 96px;" alt="logo">

Stock Kernel with KernelSU Next & SuSFS based on [Kernel Source](https://github.com/ivanmeler/android_kernel_samsung_beyondlte) by [`ivanmeler`](https://github.com/ivanmeler)

## Features

- Kernel Based on HVD3 OneUI 4.1 (Binary 7)
- OneUI 3/4 and Binaries 7, 8 and 9 Support (It may have some issues depending on ROM binary or OneUI version)
- Implement Ramdisk (No more root loss after reboot)
- Compile with AOSP Clang 16.0.2 (Based on r475365b)
- Nuke all Samsung's Security Feature, Logs & Debug in the Kernel
- KernelSU Next
- SuSFS
- WireGuard
- CPU Input Boost
- Voltage Control
- Fingerprint Boost
- Mali R38P1 GPU Driver
- OC for Little, Mid and Big CPU
- HZ Tick Set at 25Hz
- Boeffla Wakelock Blocker
- Bypass Charging (Use power directly from charger)
- ThunderTweaks Support (You can get ThunderTweaks [here](https://github.com/oItsMineZKernel/build/raw/refs/heads/main/ThunderTweaks_v1.1.1.5.apk) to customize kernel features)

## Tested On

- [Dr.Ketan ROM](https://xdaforums.com/t/31-07-24-i-n975f-i-n976b-i-n976n-i-n970f-i-dr-ketan-rom-i-oneui-4-1-i-oneui-3-1.3962839)
- [HyperROM](https://xdaforums.com/t/rom-n10-n10plus-n105g-14-jan-23-v1-1s-hyper-rom-be-unique.4268123)
- [VN-ROM](https://t.me/vnromchannel/394)
- And more... (It should work if your ROM is based on stock ROM)

## How to Install
- Flash kernel zip file via `TWRP` recovery based
- Install `Kernel Addons` on `/sdcard/oItsMineZKernel-Addons-Exynos9820-[version].zip` via KernelSU Next
- Install `KernelSU Next` from [Here](https://github.com/KernelSU-Next/KernelSU-Next/releases)
- Install `susfs4ksu module` from [Here](https://github.com/sidex15/susfs4ksu-module/releases)

## Supported Devices:

- All Dual Sim Devices are Supported


|        Name       |  Codename  |    Model   |
:------------------:|:----------:|:----------:|
|    Galaxy S10e    | beyond0lte | SM-G970F/N |
|     Galaxy S10    | beyond1lte | SM-G973F/N |
|    Galaxy S10+    | beyond2lte | SM-G975F/N |
|   Galaxy S10 5G   |   beyondx  | SM-G977B/N |
|   Galaxy Note10   |     d1     | SM-N970F/N |
|  Galaxy Note10 5G |    d1xks   |  SM-N971N  |
|   Galaxy Note10+  |     d2s    | SM-N975F/N |
| Galaxy Note10+ 5G |     d2x    | SM-N976B/N |

## How to Build

1. Copy command below and paste on your terminal to install all necessary dependencies

```
sudo apt update && sudo apt upgrade -y && sudo apt install --no-install-recommends -y build-essential gcc-aarch64-linux-gnu
```

2. Clone this repository

```
git clone https://github.com/oItsMineZKernel/android_kernel_samsung_exynos9820
```

3. Build for your device (To list all build script command run `./build.sh -h`)

```
./build.sh -m [device_codename]
```

4. After build you can find the kernel zip file at the location below

```
build/export/oItsMineZKernel-Unofficial-[yyyyMMdd]-[device_model]-[device_codename].zip
```

5. Flash using TWRP based recovery

6. Test it and enjoy!

## Credits

- [`rifsxd`](https://github.com/rifsxd) for [KernelSU Next](https://github.com/KernelSU-Next/KernelSU-Next)
- [`simonpunk`](https://github.com/simonpunk) for [susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu)
- [`ivanmeler`](https://github.com/ivanmeler) for [Kernel Source](https://github.com/ivanmeler/android_kernel_samsung_beyondlte)
- [`Linux4`](https://github.com/Linux4) for [LineageOS Kernel](https://github.com/LineageOS/android_kernel_samsung_exynos9820)
- [`Ocin4ever`](https://github.com/Ocin4ever) & [`ExtremeXT`](https://github.com/ExtremeXT) for [ExtremeKernel](https://github.com/Ocin4ever/ExtremeKernel)
- [`ThunderStorms21th`](https://github.com/ThunderStorms21th) for [ThunderStormS Kernel](https://github.com/ThunderStorms21th/S10-source)
- [`evdenis`](https://github.com/evdenis) for [CruelKernel](https://github.com/CruelKernel/samsung-exynos9820)
