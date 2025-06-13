resource "oci_core_vcn" "default" {
  compartment_id = local.secrets.oci.tenancy_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  is_ipv6enabled = true
}

resource "oci_core_subnet" "default" {
  compartment_id = local.secrets.oci.tenancy_ocid
  vcn_id         = oci_core_vcn.default.id
  cidr_block     = "10.0.1.0/24"
  ipv6cidr_block = cidrsubnet(oci_core_vcn.default.ipv6cidr_blocks[0], 8, 0)
}

resource "oci_core_route_table" "default" {
  compartment_id = local.secrets.oci.tenancy_ocid
  vcn_id         = oci_core_vcn.default.id
  display_name   = "rtb-default"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.default.id
  }
}

resource "oci_core_security_list" "default" { # import from default_security_list_id
  compartment_id = local.secrets.oci.tenancy_ocid
  vcn_id         = oci_core_vcn.default.id
  display_name   = "scl-default"

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
  compartment_id = local.secrets.oci.tenancy_ocid
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
  compartment_id = local.secrets.oci.tenancy_ocid
  vcn_id         = oci_core_vcn.default.id
  display_name   = "igw-default"
  enabled        = true
}

resource "oci_core_instance" "generated_oci_core_instance" {
  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }
  availability_domain = "vVVu:US-ASHBURN-AD-1"
  compartment_id      = local.secrets.oci.tenancy_ocid
  create_vnic_details {
    assign_ipv6ip             = "true"
    assign_private_dns_record = "true"
    assign_public_ip          = "true"
    subnet_id                 = oci_core_subnet.default.id
  }
  display_name = "iad2"
  instance_options {
    are_legacy_imds_endpoints_disabled = "false"
  }
  is_pv_encryption_in_transit_enabled = "true"
  metadata = {
    "ssh_authorized_keys" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
  }
  shape = "VM.Standard.E2.1.Micro"
  source_details {
    source_id   = "ocid1.image.oc1.iad.aaaaaaaaxmcdhhangzctdwlsut42ty5jiwjysyw6kxxmxqv7wm4wmpsek7ma"
    source_type = "image"
  }
}
