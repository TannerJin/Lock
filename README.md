#  Lock

自己基于原子操作，Mach线程通信实现的各种锁，而原子操作的API基于CPU硬件，CPU指令前缀lock


// 单核：停止多线程调度(关中断)    
// 多核：1.锁住总线(禁止内存数据传输到CPU中) or 2.锁住缓存(在CPU缓存行中的该变量地址无效，需要重新从内存中加载)

## [Atomic 原子操作](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/Atomic.c)

基于CPU相关指令

## [SpinLock (自旋锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/SpinLock.swift)

基于原子操作

## [SpinRecursiveLock (递归自旋锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/SpinRecursiveLock.swift)

基于原子操作，线程对象

## [MutexLock (互斥锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/MutexLock.swift)

基于原子操作，线程通信

## [MutexRecursiveLock (递归互斥锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/MutexRecursiveLock.swift)

基于原子操作，线程通信，线程对象

## [Semaphore (信号量)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/Semaphore.swift)

基于原子操作，线程通信

## [ReadWriteLock (读写锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/ReadWriteLock.swift)

基于原子操作，线程通信，线程对象(写线程)，线程数量(读线程)

## [ConditionLock (条件锁)](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/ConditionLock.swift)

# 不加锁保证变量的安全性

操作变量的多线程在同一核中，多线程读变量可以虚拟并发(保证每次从内存中加载，不利用寄存器以及CPU缓存. 使用`valatile`修饰变量)，但是写变量保证是单一线程

demo如下(参考自libmalloc的`magazine_s->alloc_underway`)

```c
volatile boolean_t condition;   

// 保证以下代码在同一核的多线程下运行
while(1) {
  if (condition) {  // 读变量
    condition = ！condition  // 写变量
    break;
  } else {
    yield();  // 不写变量，让出该核的时间片
  }
}
```


