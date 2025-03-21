{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Venv
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/vda";
  # boot.loader.grub.useOSProber = true;

  networking.hostName = "plgconnect";

  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the XFCE Desktop Environment.
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.desktopManager.xfce.enable = true;

  # Enable the LXQT Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.lxqt.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  console.keyMap = "de";

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.tag = {
    isNormalUser = true;
    description = "tag";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [];
  };

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "tag";

  programs.firefox.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      fontconfig
      xorg.libX11
      xorg.libICE
      xorg.libSM
      zlib
      openssl
    ];
  };

  environment.sessionVariables = {
    NIX_LD = lib.mkForce "${pkgs.stdenv.cc}/bin/ld";
    LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
    DOTNET_ROOT = "${pkgs.dotnet-sdk_9}";
  };

  systemd.tmpfiles.rules = [
    "d /home/tag/.config/autostart/ 0777 tag - - -"
    ''
      f /home/tag/.config/autostart/plg-connect.desktop 0777 tag - - [Desktop Entry]\nType=Application\nVersion=1.0\nOnlyShowIn=LXQt;\nName=PLGConnect\nPath=/home/tag/PLG-Connect/PLG-Connect-Presenter\nLD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH\nExec=dotnet run
    ''
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    featherpad
    git

    dotnet-sdk_9
    dotnet-runtime_9
    dotnet-aspnetcore_9
    wmctrl
  ];

  # PLG Connect Updater
  systemd.services.plg-connect-updater = {
    after = ["network.target"];
    serviceConfig = {
      User = "tag";
      Type = "oneshot";
      WorkingDirectory = "/home/tag";
    };
    path = [pkgs.git];
    startAt = "hourly";
    script = ''
      folder="PLG-Connect"

      if ! test -d $folder; then
        git clone https://github.com/PLG-Development/PLG-Connect.git
      fi

      pushd $folder

      git pull

      git switch production

      popd
    '';
  };

  # System Updater
  systemd.services.system-updater = {
    after = ["network.target"];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/etc/nixos";
    };
    path = [pkgs.git pkgs.nixos-rebuild];
    startAt = "hourly";
    script = ''
      if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        git clone https://github.com/PLG-Development/PLG-Connect-NixOS /tmp/plg-connect-nixos
        mv -f /tmp/plg-connect-nixos/{,.[^.]}* .
        rm -d /tmp/plg-connect-nixos
        git config --add safe.directory /etc/nixos
      fi

      git fetch

      local_commit=$(git rev-parse main)
      remote_commit=$(git rev-parse origin/main)

      if [ "$local_commit" != "$remote_commit" ]; then
        git pull
        nixos-rebuild boot
      fi
    '';
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
