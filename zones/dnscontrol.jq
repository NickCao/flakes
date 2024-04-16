.nodes.value | to_entries[] | select(.value.tags | index("vultr")) |
  "PTR(XREV(\"2a0c:b641:69c:\(.value.prefix)0::/60\"), \"\(.value.fqdn).\"),"
