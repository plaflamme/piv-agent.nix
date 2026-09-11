# `piv-agent.nix`

A nix flake with a home-manager module for configuring and running [`piv-agent`](https://github.com/smlx/piv-agent).

Largely based on [ssh-agent](https://github.com/nix-community/home-manager/blob/release-26.05/modules/services/ssh-agent.nix) and [gpg-agent](https://github.com/nix-community/home-manager/blob/release-26.05/modules/services/gpg-agent.nix) home manager modules.

## Usage

```nix
{
  inputs = {
    # Add this flake as an input
    piv-agent.url = "github:plaflamme/piv-agent.nix";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { piv-agent, home-manager, ... } : {
    # in your home-manager configuration...
    homeConfigurations."alice" = home-manager.lib.homeManagerConfiguration {
      imports = [
        # import the module
        piv-agent.homeModules.default
      ];

      # enable and optionally configure the agent
      services.piv-agent = {
        enable = true;
        pinentry.package = pkgs.pinentry-egui;
        exit-timeout = "42h";
      };
    };
  };
}
```

Once the configuration activated, `$SSH_AUTH_SOCK` should point at the `systemd` socket created to start `piv-agent` on demand.
