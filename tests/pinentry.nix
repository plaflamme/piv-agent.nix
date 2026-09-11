{ pkgs, ... }: {
  services.piv-agent = {
    enable = true;
    pinentry = {
      package = pkgs.pinentry-egui;
    };
  };

  test.script = ''
    assertFileContains home-files/.config/systemd/user/piv-agent.service --pinentry-binary-name=${pkgs.pinentry-egui}/bin/pinentry-egui
  '';
}
