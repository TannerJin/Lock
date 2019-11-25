#  Lock

基于原子操作实现的各种锁，而原子操作的API基于CPU硬件，CPU指令前缀lock


// 单核：停止多线程调度(关中断)    
// 多核：1.锁住总线 or 2.锁住缓存

## [SpinLock (自旋锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/SpinLock.swift)

基于原子操作

## [SpinRecursiveLock (递归自旋锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/SpinRecursiveLock.swift)

基于原子操作，线程对象

## [MutexLock (互斥锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/MutexLock.swift)

基于原子操作，线程通信

## [MutexRecursiveLock (递归互斥锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/MutexRecursiveLock.swift)

基于原子操作，线程通信，线程对象

## [ReadWriteLock (读写锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/ReadWriteLock.swift)

基于原子操作，线程通信，线程对象(写线程)，线程数量(读线程)
