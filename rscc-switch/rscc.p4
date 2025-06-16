#include <core.p4>
#include <v1model.p4>
#include "headers.p4"
#include "parsers.p4"

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

// Struct to hold extracted headers
struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

// Parser
parser MyParser(packet_in pkt,
               out headers hdr,
               out standard_metadata_t standard_meta) {
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        hdr.ipv4.verify_checksum(16w0, ChecksumLocation.Internet); // Verify IPv4 header checksum
        transition accept;
    }
}

// Ingress processing
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_meta) {

    action drop() {
        mark_to_drop(standard_meta);
    }

    // Action for L2 forwarding
    action set_egress_port(bit<9> port) {
        standard_meta.egress_spec = port;
    }

    // Action for IPv4 forwarding (sets DMAC, egress port, and decrements TTL)
    action ipv4_set_dmac_and_forward(mac_addr_t next_hop_mac, bit<9> out_port) {
        hdr.ethernet.dst_addr = next_hop_mac;
        standard_meta.egress_spec = out_port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    // Action Profile for ECMP group members
    action_profile ecmp_group_action_profile {
        actions {
            ipv4_set_dmac_and_forward;
        }
        size = 256; // Max number of unique members/paths
    }

    // Action Selector for ECMP load balancing
    action_selector ecmp_selector(ecmp_group_action_profile) {
        key {
            hdr.ipv4.src_addr;
            hdr.ipv4.dst_addr;
            hdr.ipv4.protocol;
            // Optionally, include L4 ports for finer-grained ECMP hashing
            // hdr.tcp.src_port;
            // hdr.tcp.dst_port;
        }
        algorithm: Crc16;
        size: 64; // Max number of groups
        group_size: 16; // Max members per group in each group
    }

    // L2 Forwarding Table
    table l2_fwd_table {
        key = {
            hdr.ethernet.dst_addr: exact;
        }
        actions = {
            set_egress_port;
            drop;
        }
        size = 1024;
        const default_action = drop();
    }

    // IPv4 Longest Prefix Match (LPM) Table for routing with ECMP
    table ipv4_lpm_table {
        key = {
            hdr.ipv4.dst_addr: lpm;
        }
        actions = {
            ipv4_set_dmac_and_forward;
            ecmp_selector; // For ECMP routes, action points to the selector
            drop;
        }
        const default_action = drop();
        size = 1024;
    }

    apply {
        // Initial checks for parser errors
        if (standard_meta.parser_err != 0) {
            drop();
            return;
        }

        if (hdr.ipv4.isValid()) {
            // Check TTL before attempting forwarding
            if (hdr.ipv4.ttl <= 1) {
                drop();
                return;
            }
            // Apply IPv4 LPM table for routing or ECMP
            ipv4_lpm_table.apply();
        } else if (hdr.ethernet.isValid()) {
            // If not IPv4, try L2 forwarding (e.g., ARP, other L2 traffic)
            l2_fwd_table.apply();
        } else {
            // Drop packets that are not Ethernet or IPv4 and have no specific handlers
            drop();
        }
    }
}

// Egress processing (empty for this basic setup)
control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_meta) {
    apply {
        // No specific egress processing needed for basic L2/L3 and ECMP beyond deparsing
    }
}

// Deparser
control MyDeparser(packet_out pkt, in headers hdr) {
    apply {
        pkt.emit(hdr.ethernet);
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.update_checksum(16w0, ChecksumLocation.Internet); // Recalculate IPv4 header checksum
            pkt.emit(hdr.ipv4);
        }
        // Emit other headers if added later
    }
}

// Top-level P4 program
V1Switch(
    MyParser(),
    MyIngress(),
    MyEgress(),
    MyDeparser()
) main;
