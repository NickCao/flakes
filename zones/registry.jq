{
  "public_key": "-----BEGIN PUBLIC KEY-----\nMCowBQYDK2VwAyEA1O8H5JDXOd4Lbhcq7DDZu9/OUxo+ys6EQ/jdO7JxdT8=\n-----END PUBLIC KEY-----",
  "organization": "nickcao",
  "nodes": ([
    {
      "common_name": "local",
      "endpoints": [
        {
          "serial_number": "0",
          "address_family": "ip4",
          "port": 13000
        },
        {
          "serial_number": "1",
          "address_family": "ip6",
          "port": 13000
        }
      ],
      "remarks": {
        "prefix": "2a0c:b641:69c:99c0::/60"
      }
    },
    {
      "common_name": "armchair",
      "endpoints": [
        {
          "serial_number": "0",
          "address_family": "ip4",
          "port": 13000
        },
        {
          "serial_number": "1",
          "address_family": "ip6",
          "port": 13000
        }
      ],
      "remarks": {
        "prefix": "2a0c:b641:69c:a230::/60"
      }
    }
  ] + [.nodes.value | to_entries[] | select(.value.tags | index("vultr")) | {
    "common_name": .key,
    "endpoints": [
      {
        "serial_number": "0",
        "address_family": "ip4",
        "address": .value.fqdn,
        "port": 13000
      },
      {
        "serial_number": "1",
        "address_family": "ip6",
        "address": .value.fqdn,
        "port": 13000
      }
    ],
    "remarks": .value.remarks
  } * {
    "remarks": {
      "provider": "vultr",
      "prefix": "2a0c:b641:69c:\(.value.prefix)0::/60"
    }
  }])
}
