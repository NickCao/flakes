resource "oci_identity_compartment" "staging" {
  compartment_id = local.secrets.oci.tenancy_ocid
  name           = "staging"
  description    = "staging"
  enable_delete  = true
}

resource "oci_core_vcn" "default" {
  compartment_id = oci_identity_compartment.staging.id
  display_name   = "vcn-default"

  cidr_blocks    = ["10.0.0.0/16"]
  is_ipv6enabled = true
}

resource "oci_core_subnet" "default" {
  compartment_id = oci_identity_compartment.staging.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "sub-default"

  cidr_block     = "10.0.1.0/24"
  ipv6cidr_block = cidrsubnet(oci_core_vcn.default.ipv6cidr_blocks[0], 8, 0)
}

resource "oci_core_default_route_table" "default" {
  compartment_id = oci_identity_compartment.staging.id
  display_name   = "rtb-default"

  manage_default_resource_id = oci_core_vcn.default.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.default.id
  }

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.default.id
  }
}

resource "oci_core_default_dhcp_options" "default" {
  compartment_id = oci_identity_compartment.staging.id
  display_name   = "dhc-default"

  manage_default_resource_id = oci_core_vcn.default.default_dhcp_options_id

  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
}

resource "oci_core_default_security_list" "default" {
  compartment_id = oci_identity_compartment.staging.id
  display_name   = "scl-default"

  manage_default_resource_id = oci_core_vcn.default.default_security_list_id

  egress_security_rules {
    destination_type = "CIDR_BLOCK"
    destination      = "0.0.0.0/0"
    protocol         = "all"
    stateless        = true
  }
  egress_security_rules {
    destination_type = "CIDR_BLOCK"
    destination      = "::/0"
    protocol         = "all"
    stateless        = true
  }
  ingress_security_rules {
    source_type = "CIDR_BLOCK"
    source      = "0.0.0.0/0"
    protocol    = "all"
    stateless   = true
  }
  ingress_security_rules {
    source_type = "CIDR_BLOCK"
    source      = "::/0"
    protocol    = "all"
    stateless   = true
  }
}

resource "oci_core_network_security_group" "default" {
  compartment_id = oci_identity_compartment.staging.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "nsg-default"
}

resource "oci_core_network_security_group_security_rule" "ingress-v4" {
  network_security_group_id = oci_core_network_security_group.default.id

  direction = "INGRESS"
  protocol  = "all"
  stateless = true

  source_type = "CIDR_BLOCK"
  source      = "0.0.0.0/0"
}

resource "oci_core_network_security_group_security_rule" "ingress-v6" {
  network_security_group_id = oci_core_network_security_group.default.id

  direction = "INGRESS"
  protocol  = "all"
  stateless = true

  source_type = "CIDR_BLOCK"
  source      = "::/0"
}

resource "oci_core_network_security_group_security_rule" "egress-v4" {
  network_security_group_id = oci_core_network_security_group.default.id

  direction = "EGRESS"
  protocol  = "all"
  stateless = true

  destination_type = "CIDR_BLOCK"
  destination      = "0.0.0.0/0"
}

resource "oci_core_network_security_group_security_rule" "egress-v6" {
  network_security_group_id = oci_core_network_security_group.default.id

  direction = "EGRESS"
  protocol  = "all"
  stateless = true

  destination_type = "CIDR_BLOCK"
  destination      = "::/0"
}

resource "oci_core_internet_gateway" "default" {
  compartment_id = oci_identity_compartment.staging.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "igw-default"
  enabled        = true
}

resource "oci_core_instance" "iad" {
  for_each = tomap({
    iad2 = {
      availability_domain = "vVVu:US-ASHBURN-AD-1"
      shape               = "VM.Standard.E2.1.Micro"
    }
    iad3 = {
      availability_domain = "vVVu:US-ASHBURN-AD-1"
      shape               = "VM.Standard.E2.1.Micro"
    }
    # iad4 = {
    #   availability_domain = "vVVu:US-ASHBURN-AD-2"
    #   shape               = "VM.Standard.A1.Flex"
    #   shape_config {
    #     ocpus         = 4
    #     memory_in_gbs = 24
    #   }
    #   source_details {
    #     source_id   = "ocid1.image.oc1.iad.aaaaaaaa6lsrj4xkrbm66rm3nv7vrw5tklfhnolczi2uijmnf4xndgdq7b2q"
    #     source_type = "image"
    #   }
    # }
  })

  compartment_id = oci_identity_compartment.staging.id

  availability_domain = each.value.availability_domain
  shape               = each.value.shape
  state               = "RUNNING"

  metadata = {
    "ssh_authorized_keys" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
  }

  is_pv_encryption_in_transit_enabled = true

  source_details {
    source_id               = "ocid1.image.oc1.iad.aaaaaaaapmcqm63rd6vdbcztfowph4ffgfu6dsvlj3gl5w6dvt5hfvgk3mfa"
    source_type             = "image"
    boot_volume_size_in_gbs = 50
  }

  agent_config {
    is_management_disabled = true
    is_monitoring_disabled = true
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  create_vnic_details {
    assign_ipv6ip             = true
    assign_private_dns_record = false
    assign_public_ip          = true
    subnet_id                 = oci_core_subnet.default.id
    nsg_ids                   = [oci_core_network_security_group.default.id]
  }
}
