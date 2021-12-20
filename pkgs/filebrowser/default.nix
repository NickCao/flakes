{ source, stdenv, buildGoModule, lib, nodePackages, runCommand, callPackage, nodejs, go-rice }:
let
  frontendSrc = runCommand "frontend" { } "cp -a ${source.src}/frontend $out";
  nodeExprs = runCommand "exprs" { } ''
    mkdir $out
    ${nodePackages.node2nix}/bin/node2nix \
      --input ${frontendSrc}/package.json \
      --lock ${frontendSrc}/package-lock.json \
      --node-env $out/node-env.nix \
      --output $out/node-packages.nix \
      --composition $out/default.nix \
      --development
  '';
  nodeEnv = callPackage "${nodeExprs}/node-env.nix" { };
  nodePkg = callPackage "${nodeExprs}/node-packages.nix" { nodeEnv = null; };
  nodeDep = nodeEnv.buildNodeDependencies (nodePkg.args // { src = frontendSrc; });
in
stdenv.mkDerivation {
  inherit (source) pname version src;
  nativeBuildInputs = [ nodejs go-rice ];
  buildPhase = ''
    ln -s ${nodeDep}/lib/node_modules frontend/node_modules
    export PATH=${nodeDep}/bin:$PATH
    (cd frontend && npm run build)
    (cd http && rice embed-go)
    cp -a frontend/dist $out
  '';
  dontInstall = true;
}
