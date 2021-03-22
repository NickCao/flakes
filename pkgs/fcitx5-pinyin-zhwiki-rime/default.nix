{ stdenv, fetchurl, lib }:
stdenv.mkDerivation rec {
  pname = "fcitx5-pinyin-zhwiki-rime";
  pversion = "0.2.2";
  version = "20210320";
  src = fetchurl {
    url = "https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/${pversion}/zhwiki-${version}.dict.yaml";
    sha256 = "sha256-cWeW7uVUd4E/Uzf8JYmGMq1IphNxhtpQJKOseN4K3gU=";
  };
  phases = [ "installPhase" ];
  installPhase = ''
    install -Dm644 $src $out/share/rime-data/zhwiki.dict.yaml
  '';
}
