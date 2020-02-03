//
//  Atomic.c
//  Lock
//
//  Created by jintao on 2020/2/3.
//  Copyright © 2020 jintao. All rights reserved.
//

#include "Atomic.h"

#if defined(__arm64__) || defined(__aarch64__)
__attribute__((target("lse")))
int32_t LockAtomicAdd32(int32_t theCount, int32_t* theValue) {
    int32_t result = 0;
    __asm__ volatile(
                     "mov w0, %w2\n"
                     "mov x2, %1\n"
                     "ldadd w0, w1, [x2]\n"    // w0: theCount值; x2: theValue地址; w1: theValue值
                     "add w1, w1, w0\n"
                     "mov %w0, w1\n"
                     
                     :"=&r"(result)
                     :"r"(theValue), "r"(theCount)
                     :"memory", "w0", "w1", "x2"
                    );
    
    return result;
}
#endif

#if defined(__x86_64__)
int32_t LockAtomicAdd32(int32_t theCount, int32_t* theValue) {
    
    return 0;
}
#endif
