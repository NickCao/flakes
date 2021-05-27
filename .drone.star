def main(ctx):
    return [
        step("linux", "amd64", "docker.io/nixos/nix"),
        step("linux", "arm64", "quay.io/nickcao/nix-aarch64"),
        {
            "kind": "pipeline",
            "type": "docker",
            "name": "deploy",
            "platform": {
                "os": "linux",
                "arch": "amd64",
            },
            "steps": [
                {
                    "name": "deploy",
                    "image": "docker.io/nixos/nix",
                    "commands": [
                        "nix-env -iA nixpkgs.nixFlakes",
                        "echo 'experimental-features = nix-command flakes ca-references\nmax-jobs = auto' >> /etc/nix/nix.conf",
                        "nix profile install .#git .#openssh",
                        "mkdir ~/.ssh",
                        "echo $DEPLOY_KEY > .ssh/id_ed25519",
                        "nix run github:serokell/deploy-rs -s",
                    ],
                    "environment": {
                        "DEPLOY_KEY": {
                            "from_secret": "deploy_key",
                        },
                    },
                },
            ],
        },
        {
            "kind": "secret",
            "name": "cachix_token",
            "data": "phZuIBNAXrxnaa84cTWkm2OBR3OhdZ1Du3e3iJtEzp1CtVXCc4t52Afz6H5wrJuS/b9s24udCCDF6gqw+G1E6vRH2R0Ryz5RSZJn0UPRfT8aeMFHcHSLQ1m9oFe3p8bS+RErNrc1TEytop90xuP/RyIgTSHXwUN0ras+L32GSAAy4dRWhq9LFZ4DWmSWwJJcWr+oVEcGsLZ4EfOCEjXKB+L/1vmRVqnKAnNAfM+tqmBEnEY/q+MfDQyOuZuac2pjK/71/yU=",
        },
        {
            "kind": "secret",
            "name": "deploy_key",
            "data": "PVmJLV1S5kPYLna7deKhUfHYBqN9wUL49nDO/UuEwypmd8/EjfwXDH0AG9e9WERxkNxscNQXid4jguNC3oxG7v+5DRGST3K6qZZSun68NjbC18vE7nCVmO2ShhPrzg015C4HgSzJ+du2Gb0v2wr/isbVTpgDl++bIrtKhUgSGmcb0xWRdnMaUaE+USPp8Ib/7gLA5gL2EGR/l32USNjdLclrELl8F5RzzNOsY35YSFcCrPqVb5ByAYBLX/muesokEXnwkKu9QJpqJBzpvF5TOaAjvFyeZ1sYYetLv+qOqZADTSxwI78g2/A/WSy47+waL5GK0T/ExMM1CbyGG1MWGfds+rsJ/XiZNfywL6qQ1G+GHfeHCw49VoOLEpRP1+dRUMMWF/ftwhm1UO02aNbCdftNYehDhg/E0+i5bWIeL7ot+XZFqeIpqhBm8wDsq7Tt9FVBQQSo20G3wYnz4ydh0hvUpQX1HoT8ftwJEnZQ2mbDbSBMtLlTDyq4w8bx2Lx22bB7JLiCn2zlRusq8MAWAGUK0VyRAj6paYr6vhkp7resU7jbPGrJVRCT4A==",
        }
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
                    "echo 'experimental-features = nix-command flakes ca-references\nmax-jobs = auto' >> /etc/nix/nix.conf",
                    "nix profile install .#cachix .#git",
                    "cachix authtoken $CACHIX_TOKEN",
                    "cachix use nichi",
                    "cachix watch-exec nichi -- nix flake check -vL",
                ],
                "environment": {
                    "CACHIX_TOKEN": {
                        "from_secret": "cachix_token",
                    },
                },
            },
        ],
    }
