{ config, pkgs, inputs, ... }:
let
  canopus = inputs.canopus.packages."${pkgs.system}".default;
in
{

  sops.secrets.canopus = { };

  cloud.services.canopus.config = {
    MemoryMax = "5G";
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
              res = subprocess.run(["${canopus}/bin/canopus", "${inputs.nixpkgs}", expr], capture_output=True, timeout=5)
              context.bot.send_message(chat_id=update.effective_chat.id, text=res.stdout.decode("utf-8"))
          except Exception as e:
              context.bot.send_message(chat_id=update.effective_chat.id, text="evaluation timed out")
      dispatcher.add_handler(CommandHandler('eval', eval))
      updater.start_polling()
    ''}";
    EnvironmentFile = config.sops.secrets.canopus.path;
  };

}
