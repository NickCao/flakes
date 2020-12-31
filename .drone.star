def main(ctx):
    return [
        step("linux", "amd64", "docker.io/nixos/nix"),
        step("linux", "arm64", "docker.io/nickcao/nix-aarch64"),
        {
            "kind": "secret",
            "name": "cachix_token",
            "data": "phZuIBNAXrxnaa84cTWkm2OBR3OhdZ1Du3e3iJtEzp1CtVXCc4t52Afz6H5wrJuS/b9s24udCCDF6gqw+G1E6vRH2R0Ryz5RSZJn0UPRfT8aeMFHcHSLQ1m9oFe3p8bS+RErNrc1TEytop90xuP/RyIgTSHXwUN0ras+L32GSAAy4dRWhq9LFZ4DWmSWwJJcWr+oVEcGsLZ4EfOCEjXKB+L/1vmRVqnKAnNAfM+tqmBEnEY/q+MfDQyOuZuac2pjK/71/yU=",
        },
    ]

def step(os, arch, image):
    return {
        "kind": "pipeline",
        "type": "docker",
        "name": "nix-%s-%s" % (os, arch),
        "platform": {
            "os": os,
            "arch": arch,
        },
        "steps": [
            {
                "name": "check",
                "image": image,
                "commands": [
                    "nix-env -iA nixpkgs.nixFlakes",
                    "echo 'experimental-features = nix-command flakes ca-references' >> /etc/nix/nix.conf",
                    "nix profile install nixpkgs#cachix nixpkgs#gnugrep nixpkgs#git",
                    "cachix authtoken $CACHIX_TOKEN",
                    "cachix use nichi",
                    "nix path-info --all > /tmp/store-path-pre-build",
                    "nix flake check -vL",
                    "bash -c \"comm -13 <(sort /tmp/store-path-pre-build | grep -v '\\\\.drv$') <(nix path-info --all | grep -v '\\\\.drv$' | sort) | cachix push nichi\"",
                ],
                "environment": {
                    "CACHIX_TOKEN": {
                        "from_secret": "cachix_token",
                    },
                },
            },
        ],
    }
