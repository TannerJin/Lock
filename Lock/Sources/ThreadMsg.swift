//
//  LockMsg.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// MARK: Port
@discardableResult
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

@discardableResult
public func freePort(_ port: mach_port_t) -> kern_return_t {
    let ret = mach_port_deallocate(mach_task_self_, port)
    return ret
}


// MARK: Message(Simple MSG not Complete MSG)
private let mach_port_null = mach_port_t(MACH_PORT_NULL)

private func mach_msgh_bits(remote: mach_msg_bits_t, local: mach_msg_bits_t) -> mach_msg_bits_t {
    return (remote) | ((local) << 8)
}

@discardableResult
public func thread_message_send(to remotePort: mach_port_t) -> mach_msg_return_t {
    var msg_header = mach_msg_header_t()
    msg_header.msgh_remote_port = remotePort
    msg_header.msgh_local_port = mach_port_null
    msg_header.msgh_bits = mach_msgh_bits(remote: mach_msg_bits_t(MACH_MSG_TYPE_MAKE_SEND), local: 0)
    msg_header.msgh_size = mach_msg_size_t(MemoryLayout<mach_msg_header_t>.size)
    
    let ret = mach_msg_send(&msg_header)
    #if DEBUG
    if ret != KERN_SUCCESS {
        assert(false, "msg send failure: " + String(cString: mach_error_string(ret)))
    }
    #endif
    return ret
}

@discardableResult
public func thread_message_receive(at replyPort: mach_port_t) -> mach_msg_return_t {
    var msg_header = mach_msg_header_t()
    msg_header.msgh_remote_port = mach_port_null
    msg_header.msgh_local_port = replyPort
    msg_header.msgh_bits = 0
    msg_header.msgh_size = mach_msg_size_t(MemoryLayout<mach_msg_header_t>.size) + 8

    var msg = mach_msg_base_t(header: msg_header, body: mach_msg_body_t())
    
    let msg_header_addr = withUnsafePointer(to: &msg) { (pointer) -> UnsafeMutablePointer<mach_msg_header_t> in
        return UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: mach_msg_header_t.self)
    }
    
    let ret = mach_msg_receive(msg_header_addr)
    #if DEBUG
    if ret != KERN_SUCCESS {
        assert(false, "msg receive failure: " + String(cString: mach_error_string(ret)))
    }
    #endif
    return ret
}
