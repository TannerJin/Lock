//
//  main.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

print("Hello, Lock!\n")

TestSpinLock()

TestSpinRecursiveLock()

TestMutexLock()

TestMutexRecursiveLock()

TestSemaphore()

TestReadWriteLock()

TestConditionLock()

print("\nLock Test Success 🚀🚀🚀")
