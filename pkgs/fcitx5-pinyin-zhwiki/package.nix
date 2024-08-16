{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "fcitx5-pinyin-zhwiki";
  version = "20240722";

  src = fetchurl {
    url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.5/zhwiki-${version}.dict";
    hash = "sha256-ozGXj/xZmXzopF7qiG2z+hcwGHc+3Lq6OqyFRreK9Kc=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm644 $src $out/share/fcitx5/pinyin/dictionaries/zhwiki.dict
  '';

  meta = with lib; {
    description = "zhwiki dictionary for fcitx5-pinyin and rime";
    homepage = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki";
    license = licenses.unlicense;
  };
}
