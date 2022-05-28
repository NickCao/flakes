Go module is the currently in use dependency management system for golang, and it uses a `go.sum` lock file to record the checksum of dependencies. However the hashing scheme it uses to hash file trees, called `Hash1`, is not compatible with nix hashes, making it seemingly impossible to build functions like [`importCargoLock`](https://github.com/NixOS/nixpkgs/pull/122158) to support the direct use of lock files instead of a opaque `vendorSha256` that cannot be computed beforehand.  

A typical `go.sum` looks like this
```
github.com/davecgh/go-spew v1.1.0 h1:ZDRjVQ15GmhC3fiQ8ni8+OwkZQO4DARzQgrnXU1Liz8=
github.com/davecgh/go-spew v1.1.0/go.mod h1:J7Y8YcW2NihsgmVo/mv3lAwl/skON4iLHjSsI+c5H38=
github.com/go-chi/chi v1.5.4 h1:QHdzF2szwjqVV4wmByUnTcsbIg7UGaQ0tPF2t5GcAIs=
github.com/go-chi/chi v1.5.4/go.mod h1:uaf8YgoFazUOkPBG7fxPftUylNumIev9awIWOENIuEg=
github.com/pmezard/go-difflib v1.0.0 h1:4DBwDE0NGyQoBHbLQYPwSUPoCMWR5BEzIk/f1lZbAQM=
github.com/pmezard/go-difflib v1.0.0/go.mod h1:iKH77koFhYxTK1pcRnkKkqfTogsbg7gZNVY4sRDYZ/4=
github.com/stretchr/objx v0.1.0/go.mod h1:HFkY916IF+rwdDfMAkV7OtwuqBVzrE8GR6GFx+wExME=
github.com/stretchr/testify v1.5.1 h1:nOGnQDM7FYENwehXlg/kFVnos3rEvtKTjRvOWSzb6H4=
github.com/stretchr/testify v1.5.1/go.mod h1:5W2xD1RspED5o8YsWQXVCued0rvSQ+mT+I5cxcmMvtA=
github.com/stripe/stripe-go/v72 v72.45.0 h1:9hh0S/6HmBemEe04UKh1FsIt3lkuSVYCUYthDsuc678=
github.com/stripe/stripe-go/v72 v72.45.0/go.mod h1:QwqJQtduHubZht9mek5sds9CtQcKFdsykV9ZepRWwo0=
golang.org/x/crypto v0.0.0-20190308221718-c2843e01d9a2/go.mod h1:djNgcEr1/C05ACkg1iLfiJU5Ep61QUkGW8qpdssI0+w=
golang.org/x/net v0.0.0-20200324143707-d3edc9973b7e h1:3G+cUijn7XD+S4eJFddp53Pv7+slrESplyjG25HgL+k=
golang.org/x/net v0.0.0-20200324143707-d3edc9973b7e/go.mod h1:qpuaurCH72eLCgpAm/N6yyVIVM9cpaDIP3A8BGJEC5A=
golang.org/x/sys v0.0.0-20190215142949-d0b11bdaac8a/go.mod h1:STP8DvDyc/dI5b8T5hshtkjS+E42TnysNCUPdjciGhY=
golang.org/x/sys v0.0.0-20200323222414-85ca7c5b95cd/go.mod h1:h1NjWce9XRLGQEsW7wpKNCjG9DtNlClVuFLEZdDNbEs=
golang.org/x/text v0.3.0 h1:g61tztE5qeGQ89tm6NTjjM9VPIm088od1l6aSorWRWg=
golang.org/x/text v0.3.0/go.mod h1:NqM8EUOU14njkJ3fqMW+pc6Ldnwhi/IjpwHt7yyuwOQ=
gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405/go.mod h1:Co6ibVJAznAaIkqp8huTwlJQCZ016jof/cbN4VW5Yz0=
gopkg.in/yaml.v2 v2.2.2 h1:ZCJp+EgiOT7lHqUV2J862kp8Qj64Jo6az82+3Td9dZw=
gopkg.in/yaml.v2 v2.2.2/go.mod h1:hI93XBmqTisBFMUTm0b8Fm+jr3Dg1NNxqwp+5A1VGuI=
```
We can see that each line is constructed of three parts: an import path, a version (optionally suffixed with `/go.mod`) and a Hash1 hash. Given the import path and version, we may download the module as `$base/$module/@v/$version.zip` and the corresponding `go.mod` as `$base/$module/@v/$version.mod`, in which the module path has to be escaped (in a go module specific way). Now that we have the `go.mod` files and the module zip archive in hand, we compute there hashes in accordance with `Hash1`.
```bash
wget $base/$module/@v/$version.{mod,zip}
mv $version.mod go.mod
bsdtar xf $version.zip
sha256sum go.mod | sha256sum > $version.mod.manifest
find $module@$version -type f | LC_COLLATE=C sort | xargs sha256sum > $version.zip.manifest
```
the flat sha256 hashes of `$version.mod.manifest` and `$version.zip.manifest` are equal to those in `go.sum`, making it possible to use IFD to construct further expressions until we are able to reproduce the whole vendor dir. While this approach is possible, it's far from feasible to be accepted into nixpkgs. It creates a derivation for each file in the vendor directory, and downloads the same module zip archive thousands of times just to extract a single file out of it, but with the help of [impure derivations](https://github.com/NixOS/nix/commit/647291cd6c7559f68d49a5cdd907c2fd580790b1) at least the latter part can be solved elegantly. Still, the root cause of the situation is the lack of support for alternative hashing schemes in nix, and golang's strange designs.

ref: [gomod.nix](https://gist.github.com/NickCao/e2135fae47b31798c5d03cae1d242cb3)
