{ config, lib, pkgs, modulesPath, ... }:
{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "nvidia" ];
  boot.kernelModules = [ "kvm-amd" "noacpi" "v4l2loopback" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ 
    v4l2loopback
    rtl8814au
    nvidia_x11
  ];
  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "performance";

  fileSystems."/" =
    { device = "/dev/disk/by-label/root";
      fsType = "ext4";
      neededForBoot = true;
    };

  # ssd is dead
  # fileSystems."/home" =
  #   { device = "/dev/disk/by-label/home";
  #     fsType = "ext4";
  #     neededForBoot = true;
  #   };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot-ssd";
      fsType = "vfat";
      neededForBoot = true;
    };

  swapDevices =
    [ { device = "/dev/disk/by-label/swap"; }
    ];

}
