{ ... }: {
  services.piv-agent = {
    enable = true;
  };

  test.script = ''
    # Path to the generated home directory files inside the derivation build matrix
    assertFileExists home-files/.config/my-feature/config.conf

    # You can also inspect generated file contents
    assertFileContains home-files/.config/my-feature/config.conf "expected-setting = true"
  '';
}
