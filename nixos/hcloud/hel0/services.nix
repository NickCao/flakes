{ config, pkgs, ... }:
{

  cloud.services.blog.config = {
    ExecStart = "${pkgs.miniserve}/bin/miniserve -i 127.0.0.1 -p 8007 --index index.html ${pkgs.blog}";
  };

  cloud.services.canopus.config = {
    MemoryLimit = "5G";
    SystemCallFilter = null;
    ExecStart = "${pkgs.python3.withPackages (ps: with ps;[ python-telegram-bot ])}/bin/python ${pkgs.writeText "canopus.py" ''
      from telegram.ext import Updater
      from telegram import Update
      from telegram.ext import CallbackContext
      from telegram.ext import CommandHandler
      import subprocess
      import os
      updater = Updater(token=os.environ['BOT_TOKEN'])
      dispatcher = updater.dispatcher
      def eval(update: Update, context: CallbackContext):
          expr = "with import <nixpkgs> {};" + update.message.text.split(maxsplit=1)[-1]
          try:
              res = subprocess.run(["${pkgs.canopus}/bin/canopus", "${pkgs.nixpkgs}", expr], capture_output=True, timeout=5)
              context.bot.send_message(chat_id=update.effective_chat.id, text=res.stdout.decode("utf-8"))
          except Exception as e:
              context.bot.send_message(chat_id=update.effective_chat.id, text="evaluation timed out")
      dispatcher.add_handler(CommandHandler('eval', eval))
      updater.start_polling()
    ''}";
    EnvironmentFile = config.sops.secrets.canopus.path;
  };

  services.traefik = {
    dynamicConfigOptions = {
      http = {
        routers = {
          blog = {
            rule = "Host(`nichi.co`)";
            entryPoints = [ "https" ];
            middlewares = [ "blog" ];
            service = "blog";
          };
        };
        middlewares = {
          blog.headers = {
            stsSeconds = 31536000;
            stsIncludeSubdomains = true;
            stsPreload = true;
          };
        };
        services = {
          blog.loadBalancer = {
            servers = [{ url = "http://127.0.0.1:8007"; }];
          };
        };
      };
    };
  };

}
