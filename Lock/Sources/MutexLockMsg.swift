//
//  LockMsg.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// MARK: Port
public func mallocPortWith(context: UInt) -> mach_port_t? {
    var port: mach_port_t = 0
    
    var options = mach_port_options_t()
    options.flags = UInt32(MPO_CONTEXT_AS_GUARD | MPO_QLIMIT | MPO_INSERT_SEND_RIGHT | MPO_STRICT)
    options.mpl.mpl_qlimit = 1
    
    let option_ptr = withUnsafePointer(to: &options, {UnsafeMutablePointer(mutating: $0)})
    
    let ret = mach_port_construct(mach_task_self_, option_ptr, mach_port_context_t(context), &port)
    
    if ret != KERN_SUCCESS {
        return nil
    }
    return port
}

public func freePort(_ port: mach_port_t) {
    mach_port_deallocate(mach_task_self_, port)
}


// MARK: Message(Simple)
private let mach_port_null = mach_port_t(MACH_PORT_NULL)

private func mach_msgh_bits(remote: mach_msg_bits_t, local: mach_msg_bits_t) -> mach_msg_bits_t {
    return (remote) | ((local) << 8)
}

public func lock_message_send(port remotePort: mach_port_t) {
    var header = mach_msg_header_t()
    header.msgh_remote_port = remotePort
    header.msgh_local_port = mach_port_null
    header.msgh_bits = mach_msgh_bits(remote: mach_msg_bits_t(MACH_MSG_TYPE_COPY_SEND), local: 0);
    header.msgh_size = mach_msg_size_t(MemoryLayout<mach_msg_header_t>.size)
    
    mach_msg_send(&header)
}

public func lock_message_receive(port replyPort: mach_port_t) {
    var recv_msg = mach_msg_header_t()
    recv_msg.msgh_remote_port = mach_port_null
    recv_msg.msgh_local_port = replyPort
    recv_msg.msgh_bits = 0
    recv_msg.msgh_size = mach_msg_size_t(MemoryLayout<mach_msg_header_t>.size)

    mach_msg_receive(&recv_msg)
}
