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
      from telegram import Update
      from telegram.ext import ApplicationBuilder, ContextTypes, CommandHandler
      import logging
      import asyncio
      import os

      logging.basicConfig(format="%(name)s [%(levelname)s] %(message)s", level=logging.INFO)
      logger = logging.getLogger(__name__)

      async def eval_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
          expr = "with import <nixpkgs> {};" + update.message.text.split(maxsplit=1)[-1]
          try:
              proc = await asyncio.create_subprocess_exec("${canopus}/bin/canopus", "${inputs.nixpkgs}", expr,
                  stderr=asyncio.subprocess.PIPE,
                  stdout=asyncio.subprocess.PIPE)
              stdout, stderr = await asyncio.wait_for(proc.communicate(), 5)
              await update.message.reply_text(stdout.decode())
          except asyncio.exceptions.TimeoutError:
              proc.kill()
              await update.message.reply_text("evaluation timed out")
          except Exception as e:
              logging.warning(e)
              await update.message.reply_text("evaluation error")

      token = os.environ['BOT_TOKEN']
      application = ApplicationBuilder().token(token).build()
      application.add_handler(CommandHandler('eval', eval_handler))
      application.run_polling()
    ''}";
    EnvironmentFile = config.sops.secrets.canopus.path;
  };

}
