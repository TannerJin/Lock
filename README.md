#  Lock

基于原子操作实现的各种锁，而原子操作的API基于CPU硬件，CPU指令前缀lock


// 单核：停止多线程调度(关中断)
// 多核：1.锁住总线 or 2.锁住缓存

 - [SpinLock](#SpinLock (自旋锁))
 - [SpinRecursiveLock](#SpinRecursiveLock (递归自旋锁))
 - [MutexLock](#MutexLock (互斥锁))
 - [MutexRecursiveLock](#MutexRecursiveLock (递归互斥锁))

## SpinLock (自旋锁)

基于原子操作

## SpinRecursiveLock (递归自旋锁)

基于原子操作，线程对象

## MutexLock (互斥锁)

基于原子操作，线程通信

## MutexRecursiveLock (递归互斥锁)

基于原子操作，线程通信，线程对象