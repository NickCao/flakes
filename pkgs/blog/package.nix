{ runCommand, mdbook }:
runCommand "blog"
{
  src = ../../blog;
  nativeBuildInputs = [ mdbook ];
}
  ''
    mdbook build -d $out $src
  ''
