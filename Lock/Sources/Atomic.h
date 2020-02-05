//
//  Atomic.h
//  Lock
//
//  Created by jintao on 2020/2/3.
//  Copyright © 2020 jintao. All rights reserved.
//

#ifndef Atomic_h
#define Atomic_h

#include <stdio.h>

int32_t LockAtomicAdd32(int32_t theCount, int32_t* theValue);

_Bool LockAtomicCompareAndSwap32(int32_t oldValue, int32_t newValue, int32_t* theValue);

#endif /* Atomic_h */
