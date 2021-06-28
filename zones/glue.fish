for record in (jq -r -c '.nodes.value|to_entries[]|[.key,{ ips:[.value.ipv4,.value.ipv6]}|tostring]|@sh' zones/nodes.json)
  set records (string split " " -- $record)
  set host (echo $records[1] | tr -d "'")
  eval "curl -X PUT \
  https://api.gandi.net/v5/domain/domains/nichi.link/hosts/$host \
  -H 'authorization: Apikey $key' \
  -H 'content-type: application/json' \
  -d $records[2]"
end
