def main(ctx):
    return [
        step("linux", "amd64"),
        #step("linux", "arm64"),
        {
            "kind": "secret",
            "name": "cachix_token",
            "data": "phZuIBNAXrxnaa84cTWkm2OBR3OhdZ1Du3e3iJtEzp1CtVXCc4t52Afz6H5wrJuS/b9s24udCCDF6gqw+G1E6vRH2R0Ryz5RSZJn0UPRfT8aeMFHcHSLQ1m9oFe3p8bS+RErNrc1TEytop90xuP/RyIgTSHXwUN0ras+L32GSAAy4dRWhq9LFZ4DWmSWwJJcWr+oVEcGsLZ4EfOCEjXKB+L/1vmRVqnKAnNAfM+tqmBEnEY/q+MfDQyOuZuac2pjK/71/yU=",
        },
    ]

def step(os, arch):
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
                "image": "docker.io/nixpkgs/nix-flakes:latest",
                "commands": [
                    "mkdir /etc/nix",
                    "echo 'experimental-features = nix-command flakes ca-references' >> /etc/nix/nix.conf",
                    "echo 'sandbox = false' >> /etc/nix/nix.conf",
                    "nix shell nixpkgs#cachix -c cachix authtoken $CACHIX_TOKEN",
                    "nix shell nixpkgs#cachix -c cachix use nichi",
                    "nix path-info --all > /tmp/store-path-pre-build";
                    "nix flake check -vL",
                    "comm -13 <(sort /tmp/store-path-pre-build | grep -v '\.drv$') <(nix path-info --all | grep -v '\.drv$' | sort) | cachix push nichi",
                ],
                "environment": {
                    "CACHIX_TOKEN": {
                        "from_secret": "cachix_token",
                    },
                },
            },
        ],
    }
