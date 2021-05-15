{ pkgs, config, ... }:
{
  environment.etc."ssh/keys" = {
    mode = "0555";
    text = ''
      #!${pkgs.runtimeShell}
      ${pkgs.curl}/bin/curl https://gitlab.com/NickCao.keys
    '';
  };

  services.openssh = {
    enable = true;
    authorizedKeysCommand = "/etc/ssh/keys";
  };
}
