{ formats, msmtp, lynx }:
let
  server = "hel0.nichi.link";
  address = "nickcao@nichi.co";
  password = "cat ~/.config/meli/password";
in
(formats.toml { }).generate "config.toml" {
  accounts.nickcao = {
    root_mailbox = "INBOX";
    format = "imap";
    subscribed_mailboxes = [ "*" ];
    identity = address;
    display_name = "Nick Cao";
    search_backend = "none";
    mailboxes = {
      INBOX = {
        alias = "Inbox";
        subscribe = true;
      };
    };
    server_hostname = server;
    server_username = address;
    server_password_command = password;
    server_port = 993;
  };
  shortcuts = {
    general = {
      quit = "Esc";
    };
    listing = {
      prev_account = "Left";
      next_account = "Right";
    };
    compact-listing = {
      exit_thread = "h";
      open_thread = "l";
      select_entry = "v";
    };
    envelope-view = {
      toggle_expand_headers = "H";
    };
    thread-view = {
      collapse_subtree = "c";
      scroll_up = "K";
      scroll_down = "J";
    };
  };
  composing = {
    send_mail = "${msmtp}/bin/msmtp --read-recipients --read-envelope-from";
  };
  pager = {
    html_filter = "${lynx}/bin/lynx -assume_charset=utf-8 -display_charset=utf-8 -dump -force_html -stdin";
  };
  terminal = {
    theme = "light";
  };
}
