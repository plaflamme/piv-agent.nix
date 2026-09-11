{
  pkgs,
  home-manager,
  piv-agent,
}:

let
  hmTesting = {
    runTest =
      {
        name,
        configuration,
        tests,
      }:
      pkgs.lib.mapAttrs (
        testName: testModule:
        let
          # 1. Evaluate the module purely to extract the custom test script
          # without breaking the strict option check of Home Manager.
          evaledTest = if builtins.isFunction testModule then testModule { inherit pkgs; } else testModule;
          testScript = evaledTest.test.script or "";

          # 2. Strip out the 'test' attribute so Home Manager doesn't throw the option error
          cleanTestModule = builtins.removeAttrs evaledTest [ "test" ];

          # 3. Build the underlying Home Manager environment
          hmConfig =
            (home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                configuration
                cleanTestModule
              ];
            }).activationPackage;
        in
        # 4. If a script exists, run it against the generated files. Otherwise, just validate evaluation.
        if testScript == "" then
          hmConfig
        else
          pkgs.runCommand "hm-test-${testName}" { } ''
            # Create helper bash functions matching your target syntax
            assertFileExists() {
              if [ ! -f "$1" ]; then
                echo "FAIL: File '$1' does not exist." >&2
                exit 1
              fi
            }

            assertFileContains() {
              if ! grep -q "$2" "$1"; then
                echo "FAIL: File '$1' does not contain content pattern: '$2'" >&2
                echo "File contents were:" >&2
                cat "$1" >&2
                exit 1
              fi
            }

            # Provide a convenient alias/symlink to the home files structure inside the derivation environment
            # Home Manager puts generated files in the activation package under 'home-files'
            ln -s ${hmConfig}/home-files ./home-files

            # Run user's test.script block
            ${testScript}

            # If we get here, the checks passed. Output the files so it's possible to inspect them.
            mkdir $out
            cp -r ./home-files $out
          ''
      ) tests;
  };
in
hmTesting.runTest {
  name = "piv-agent-module-tests";

  configuration = {
    imports = [ piv-agent ];

    home.username = "testuser";
    home.homeDirectory = "/home/testuser";
    home.stateVersion = "26.05";
  };

  tests = {
    simple = import ./simple.nix;
  };
}
