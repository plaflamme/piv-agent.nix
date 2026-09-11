{ pkgs, ... }: {
  services.piv-agent = {
    enable = true;
    exit-timeout = "42h";
    idle-timeout = "77h";
    load-keyfile = true;
    pinentry = {
      package = pkgs.pinentry-egui;
    };
  };

  test.script = ''
    assertFileContains home-files/.config/systemd/user/piv-agent.service --pinentry-binary-name=${pkgs.pinentry-egui}/bin/pinentry-egui
    assertFileContains home-files/.config/systemd/user/piv-agent.service --load-keyfile
    assertFileContains home-files/.config/systemd/user/piv-agent.service --exit-timeout=42h
    assertFileContains home-files/.config/systemd/user/piv-agent.service --idle-timeout=77h
  '';
}
