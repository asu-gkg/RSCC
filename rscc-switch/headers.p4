// headers.p4
// This file defines the common headers and metadata structures.

// Header definitions
header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  protocol;
    @checksum
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header tcp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<2>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    @checksum
    bit<16> checksum;
    bit<16> urg_ptr;
}

typedef bit<48> mac_addr_t;
typedef bit<32> ip4_addr_t;

// Struct to hold extracted headers
struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
    tcp_t      tcp;
}

// Metadata struct (can be customized as needed)
struct metadata {
    // Add custom metadata fields here if needed by your logic.
    bit<32> my_custom_field; // Example field
}

