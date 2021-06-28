#!/usr/bin/env python
from os import path
from urllib import request
import json

with open(path.join(path.dirname(__file__), "nodes.json"), "r") as f:
    nodes = json.load(f)["nodes"]["value"]
nodes = list(
    map(
        lambda x: {
            "host": x,
            "data": json.dumps(
                {"ips": [nodes[x]["ipv4"], nodes[x]["ipv6"]]}, separators=(",", ":")
            ),
        },
        nodes,
    )
)
for node in nodes:
    print(
        f"curl -X PUT https://api.gandi.net/v5/domain/domains/nichi.link/hosts/{node['host']} -H \"authorization: Apikey $GANDI_API_KEY\" -H 'content-type: application/json' -d '{node['data']}'"
    )
