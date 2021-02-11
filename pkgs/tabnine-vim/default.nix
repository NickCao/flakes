{ vimUtils, fetchFromGitHub, lib }:
vimUtils.buildVimPlugin {
  name = "tabnine-vim";
  src = fetchFromGitHub {
    owner = "codota";
    repo = "tabnine-vim";
    rev = "fa891e62903501f7eeb2f00f6574ec9684e1c4ee";
    sha256 = "0cra1l31fcngp3iyn61rlngz4qx7zwk68h07bgp9w5gjx59a7npz";
  };
  meta = {
    url = "https://github.com/codota/tabnine-vim";
    license = lib.licenses.unfree;
  };
}
