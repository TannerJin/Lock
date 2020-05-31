#  Lock

基于原子操作，用Swift实现的锁


[__Atomic 原子操作__](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/Atomic.c)


[__SpinLock (自旋锁)__](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/SpinLock.swift)


[__SpinRecursiveLock (递归自旋锁)__](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/SpinRecursiveLock.swift)


[__MutexLock (互斥锁)__](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/MutexLock.swift)


[__MutexRecursiveLock (递归互斥锁)__](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/MutexRecursiveLock.swift)


[__Semaphore (信号量)__](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/Semaphore.swift)


[__ReadWriteLock (读写锁)__](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/ReadWriteLock.swift)


[__ConditionLock (条件锁)__](https://github.com/TannerJin/Lock/blob/master/Lock/Sources/ConditionLock.swift)

## 不加锁保证变量的安全性

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


