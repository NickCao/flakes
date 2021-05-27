def main(ctx):
    return [
        step("linux", "amd64", "registry.gitlab.com/nickcao/oci-images/nix"),
        step("linux", "arm64", "registry.gitlab.com/nickcao/oci-images/nix"),
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
                        "nix profile install github:NixOS/nixpkgs/nixos-unstable-small#git github:NixOS/nixpkgs/nixos-unstable-small#openssh",
                        "mkdir ~/.ssh",
                        "echo $DEPLOY_KEY | base64 -d > ~/.ssh/id_ed25519",
                        "chmod 0600 ~/.ssh/id_ed25519",
                        "ssh-keyscan nrt.jp.nichi.link sin.sg.nichi.link > ~/.ssh/known_hosts",
                        "chmod 0600 ~/.ssh/known_hosts",
                        "nix run github:serokell/deploy-rs -- -s",
                    ],
                    "environment": {
                        "DEPLOY_KEY": {
                            "from_secret": "deploy_key",
                        },
                    },
                    "when": {
                        "event": [ "promote" ],
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
            "data": "isSZyowiTawHN3fd4gDpjEbr3J8SE+HROLBiAAYMc664xtXP+imoCzMxwZ1Hm/4RXG44TsEbQ2C3SLdCUEOQbqkRBUssiIGgmhQZhlie0affB/3bceKJZyCuhxVEXiDIn8rY1WCFCGvCleke2ggSaZ4/hN980TWdzRry08U49EzWx5fvzERpmdSkUUob7PMsUuITQLoqyESajRzrKoxyi+Pyx37tyRCI+lYw3PGxKVB4vJ1LaWadHV/eAG/OjRYTSxt62P82hOI6oNq3fcfZ31cz8WCQ233gwPDKaoqGFBqh7py0FRwEta7+bXJuPyKeRHpSmtrjcvrR3ie0QD73FNgQqYFdZVgTJmURBOS1NqQRHAHPYFj++aMw8f6I5AgBPrpfwEjpEjrH1qUymRy7f3VLbx4O9t31YcjfT/j5JifV2PTEfuxN/kDESRzuuZDHHgF4hS5wgEryRTzLLyQW5IMSWLdPfbFGsjjnbkVUBGy12Sl+BdRrScgZOr/JbVIznxPeU3fxgQSNbo+L70VhOFYDCMwOMXg4lLVN8a5vOEIIqYCHEV6m0ImNvdrWfcqGzZuWaSnm/AuAbuq+j/y0xS3/pCFSYg8XslIvdOeEt5o1mZKLPEsS/pgbErBVrszDkCkSPddiFe3SAo/B0ZGe5uEPwoKTVmeW4u6oC3Nd8DCQQYcdN/sooeydzNdi1jWsgBQ+xOleYuj3bRT0nYCeDiiPApoiK2Q7r13l35VfyDA=",
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
                    "nix profile install nixpkgs#cachix",
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
