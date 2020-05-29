//
//  Atomic.c
//  Lock
//
//  Created by jintao on 2020/2/3.
//  Copyright © 2020 jintao. All rights reserved.
//

#include "Atomic.h"

// MARK: arm64

#if defined(__arm64__) || defined(__aarch64__)
__attribute__((target("lse")))
int32_t LockAtomicAdd32(int32_t theCount, int32_t* theValue) {
    int32_t result = 0;
    __asm__ volatile(
                     "mov w0, %w2\n"
                     "mov x2, %1\n"
                     "ldadd w0, w1, [x2]\n"    // w0: theCount值; x2: theValue地址; w1: 加之前theValue值
                     "add w1, w1, w0\n"
                     "mov %w0, w1\n"
                     
                     :"=&r"(result)
                     :"r"(theValue), "r"(theCount)
                     :"memory", "w0", "w1", "x2"
                    );
    
    return result;
}

// https://developer.arm.com/docs/dui0801/g/a64-data-transfer-instructions/casa-casal-cas-casl-casal-cas-casl
__attribute__((target("lse")))
_Bool LockAtomicCompareAndSwap32(int32_t oldValue, int32_t newValue, int32_t* theValue) {
    _Bool result = 0;
    __asm__ volatile(
                     "mov w0, %w1\n"
                     "cas w0, %w2, [%3]\n"
                     "cmp w0, %w1\n"
                     "beq 12\n"
                     "mov %w0, 0\n"
                     "b 8\n"
                "12:\n"
                     "mov %w0, 1\n"
                     :"=&r"(result)
                     :"r"(oldValue), "r"(newValue), "r"(theValue)
                     :"memory", "w0"
                     );
    return result;
};
#endif



// MARK: __x86_64__

#if defined(__x86_64__)
// edi, rsi
int32_t LockAtomicAdd32(int32_t theCount, int32_t* theValue) {
    int32_t result = 0;
    __asm__ volatile(
                     "movl %%edi, %%edx\n"
                     "lock\n"                    // 锁总线
                     "xaddl %%edi, (%%rsi)\n"    // rsi: theValue地址;  edi: 加之前是theCount, 加完之后是theValue加之前的值
                     "addl %%edi, %%edx\n"
                     "movl %%edx, %0\n"
                     
                     :"=&r"(result)
                     :
                     :"memory", "edx"
                     );
    return result;
}

// https://blog.csdn.net/xiuye2015/article/details/53406432
// 0: edi, 1: esi, 2: rdx
_Bool LockAtomicCompareAndSwap32(int32_t oldValue, int32_t newValue, int32_t* theValue) {
    _Bool result = 0;
    __asm__ volatile(
                     // cmpxchg指令，判断eax和rdx地址值是否相等
                     "mov %%edi, %%eax\n"
                     "lock\n"
                     // 相等: *theValue = esi, zf=1;
                     // 不等: eax = *theValue, zf=0;
                     "cmpxchg %%esi, (%%rdx)\n"
                     "je equal\n"           // zf=1: ==
                     "jmp notEqual\n"       // zf=0: !=
                    "equal:"
                        "mov $1, %0\n"
                        "jmp end\n"
                    "notEqual:"
                        "mov $0, %0\n"
                     "end:"
                     :"=&r"(result)
                     :
                     :"memory", "eax"
                     );
    
//    asm{
//        mov eax, edi;
//        lock;
//        cmpxchg [rdx], rsi;
//        je equal;
//        jmp notEqual;
//    equal:
//        mov result, 0x1;
//        jmp end;
//    notEqual:
//        mov result, 0x0;
//    end:
//    };
    
    return result;
};

#endif
