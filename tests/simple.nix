{ ... }: {
  services.piv-agent = {
    enable = true;
  };

  test.script = ''
    assertFileExists home-files/.config/systemd/user/piv-agent.socket
    assertFileExists home-files/.config/systemd/user/piv-agent.service
  '';
}
