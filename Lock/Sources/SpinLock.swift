//
//  SpinLock.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// 自旋锁

public class SpinLock {
    private var value: Int32 = 0
    
    private static var PreQosClassKey: pthread_key_t = 0
    private static let swiftOnceRegisterSpinLockThreadKey = {
        pthread_key_create(&SpinLock.PreQosClassKey, nil)
    }()
    
    public init() {
        // 只会注册一次
        _ = SpinLock.swiftOnceRegisterSpinLockThreadKey
    }

    public func lock() {
        while !LockAtomicCompareAndSwap32(0, 1, &value) {
            // sched_yield() 主动放弃时间片？
        }

        // QOS_CLASS_BACKGROUND        : 9
        // QOS_CLASS_UTILITY           : 17
        // QOS_CLASS_DEFAULT           : 21
        // QOS_CLASS_USER_INITIATED    : 25
        // QOS_CLASS_USER_INTERACTIVE  : 33

        /*  1. fix优先级反转 (提高获取到锁的线程优先级, 目前是这个) or (降低没获取到锁的线程优先级)
                lock   提升优先级
                unlock 恢复线程优先级
         */
        let preQosClassSelf = qos_class_self()

        if preQosClassSelf.rawValue <= QOS_CLASS_DEFAULT.rawValue {
            let pointer = malloc(MemoryLayout<qos_class_t>.size)
            pointer?.bindMemory(to: qos_class_t.self, capacity: 1).initialize(to: preQosClassSelf)

            pthread_setspecific(Self.PreQosClassKey, pointer)
            
            // 或者 thread_policy_set
            pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0)
        }
    }

    public func unlock() {
        var preQosClassSelf: UnsafeMutablePointer<qos_class_t>?

        if Self.PreQosClassKey != 0 {
            preQosClassSelf = pthread_getspecific(Self.PreQosClassKey)?.assumingMemoryBound(to: qos_class_t.self)
            pthread_setspecific(Self.PreQosClassKey, nil)
        }

        value = 0
        
        if preQosClassSelf != nil {
            pthread_set_qos_class_self_np(preQosClassSelf!.pointee, 0)
            free(preQosClassSelf)
        }
    }
}


// MARK: Test
func TestSpinLock() {
    let concurrentCount = 500
    let lock = SpinLock()
    var value = 0

    let queue = DispatchQueue(label: "SpinLockQueue", qos: .userInteractive, attributes: .concurrent)
    
    for _ in 0..<concurrentCount {
        queue.async {
            lock.lock()
            Thread.sleep(forTimeInterval: 0.01)
            value += 1
            lock.unlock()
        }
    }

    queue.sync(flags: .barrier) { () -> Void in
        assert(value == concurrentCount)
        print("SpinLock Test Success")
    }
}
