 fromstream(1|truncate_stream(inputs)) | ._source.layers | add |
    {
        "frame.time",
        "frame.time_epoch",
        "frame.time_delta",
        "frame.time_relative",
        "frame.number",
        "frame.protocols",
        "eth.src",
        "eth.dst",
        "ip.len",
        "ip.id",
        "ip.flags_tree",
        "ip.dsfield_tree",
        "ip.frag_offset",
        "ip.ttl",
        "ip.proto",
        "ip.src",
        "ip.dst",
        "udp.srcport",
        "udp.dstport",
        "udp.length",
        "udp.stream",
        "tcp.srcport",
        "tcp.dstport",
        "tcp.stream",
        "tcp.completeness",
        "tcp.len",
        "tcp.seq",
        "tcp.seq_raw",
        "tcp.nxtseq",
        "tcp.ack",
        "tcp.flags_tree",
        "tcp.ack_raw",
        "tcp.hdr_len",
        "tcp.window_size_value",
        "tcp.window_size",
        "tcp.window_size_scalefactor",
        "tcp.urgent_pointer"
    }

