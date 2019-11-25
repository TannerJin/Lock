//
//  LockMsg.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// MARK: Port
public func constructPortWith(context: UInt) -> mach_port_t? {
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

@discardableResult
public func destructPort(_ port: mach_port_t, context: UInt) -> kern_return_t {
    let ret = mach_port_destruct(mach_task_self_, port, -1, mach_port_context_t(context))
    return ret
}


public func allocatePort() -> mach_port_t? {
    var port: mach_port_name_t = 0
    let ret = mach_port_allocate(mach_task_self_, MACH_PORT_RIGHT_RECEIVE, &port)
    if ret == KERN_SUCCESS {
        let ret2 = mach_port_insert_right(mach_task_self_, port, port, mach_msg_type_name_t(MACH_MSG_TYPE_MAKE_SEND))
        if ret2 == KERN_SUCCESS {
            return port
        } else {
            return nil
        }
    } else {
        return nil
    }
}


// MARK: Message(Simple MSG not Complete MSG)
private let mach_port_null = mach_port_t(MACH_PORT_NULL)

private func mach_msgh_bits(remote: mach_msg_bits_t, local: mach_msg_bits_t) -> mach_msg_bits_t {
    return (remote) | ((local) << 8)
}

@discardableResult
public func lock_message_send(port remotePort: mach_port_t) -> mach_msg_return_t {
    var header = mach_msg_header_t()
    header.msgh_remote_port = remotePort
    header.msgh_local_port = mach_port_null
    header.msgh_bits = mach_msgh_bits(remote: mach_msg_bits_t(MACH_MSG_TYPE_MAKE_SEND), local: 0)
    header.msgh_size = mach_msg_size_t(MemoryLayout<mach_msg_header_t>.size)
    
    let ret = mach_msg_send(&header)
    #if DEBUG
    if ret != KERN_SUCCESS {
        assert(false)
    }
    #endif

    return ret
}

@discardableResult
public func lock_message_receive(port replyPort: mach_port_t) -> mach_msg_return_t {
    var recv_msg = mach_msg_header_t()
    recv_msg.msgh_remote_port = mach_port_null
    recv_msg.msgh_local_port = replyPort
    recv_msg.msgh_bits = 0
    recv_msg.msgh_size = mach_msg_size_t(MemoryLayout<mach_msg_header_t>.size) + 8

    var msg = mach_msg_base_t(header: recv_msg, body: mach_msg_body_t())
    let recv_msg_addr = withUnsafePointer(to: &msg) { (pointer) -> UnsafeMutablePointer<mach_msg_header_t> in
        return UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: mach_msg_header_t.self)
    }
    
    let ret = mach_msg_receive(recv_msg_addr)
    #if DEBUG
    if ret != KERN_SUCCESS {
        assert(false)
    }
    #endif
    return ret
}
