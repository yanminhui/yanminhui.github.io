---

layout: post
title: '监视器对象模式'
subtitle: 'Monitor Object Pattern'
date: 2023-07-07
categories: [article]
tags: ['C++', 'Multithreading', 'DesignPatterns'] 

---

前文在解释 [ASIO Strand](https://yanminhui.github.io/2023/07/02/asio-strand.html) 的实现中，提到一种用于并发编程的对象行为模式 Active Object，本文介绍另一种并发编程的对象行为模式 [Monitor Object](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=29903ed1cf0a1d930e4b601f20c91da184807411) 的一种实现。

Monitor Object 能够保证在对象内部任意时刻只能运行一个方法，使线程可以获得对共享资源的独占访问，防止多个线程同时访问它。当线程想要访问共享资源时，它必须先获得监视器对象上的锁。如果锁已经被另一个线程持有，则请求线程将被阻塞，直到锁被释放。一般的实现形式如下：

```.cpp
struct monitor_example
{
    void foo()
    {
        lock_guard<mutex> lock(mtx_);
        // ...
    }

    void bar()
    {
        lock_guard<mutex> lock(mtx_);
        // ...
    }

private:
    mutex mtx_;
};
```

Bjarne Stroustrup 提出了[一种包裹成员函数调用的方法](https://www.stroustrup.com/wrapper.pdf)，使用它可以避免上述实现方法中每个成员函数内部都要手动上锁的样板代码。

```.cpp
namespace detail {

template <class T, class Mutex>
class call_proxy 
{
public:
    call_proxy(T* p, Mutex& mtx) noexcept
        : p_{p}, mtx_{mtx}
    {
    }

    call_proxy(const call_proxy&) = delete;
    call_proxy(call_proxy&& rhs) = delete;
    call_proxy& operator=(const call_proxy&) = delete;
    call_proxy& operator=(call_proxy&&) = delete;

    T* operator->() noexcept
    { 
        return p_;
    }

    ~call_proxy()
    {
        if (p_) {
            mtx_.unlock();
        }
    }

private: 
    T* p_ = nullptr;
    Mutex& mtx_;
};

} // namespace detail

template <class T, class Mutex = typename T::mutex_type>
class monitor_ptr
{
    using proxy_type = detail::call_proxy<T, Mutex>;

public:
    monitor_ptr(T* p, Mutex& mtx) noexcept
        : p_{p}, mtx_{mtx}
    {
    }

    template <class U>
    requires requires(U u) {
        {u.monitor()} -> std::same_as<monitor_ptr>;
    }
    monitor_ptr(U& u)
        : monitor_ptr{u.monitor()}
    {
    }

    explicit operator bool() const noexcept
    {
        return !!p_;
    }

    proxy_type operator->() 
    {
        mtx_.lock();
        return {p_, mtx_}; 
    }

private:
    T* p_ = nullptr;
    Mutex& mtx_;
};

template <class U>
monitor_ptr(U&) -> monitor_ptr<U>;

template <class T>
using monitor_ptr_t = typename T::monitor_ptr_t;
```

我们来看下，如何使用它：

```.cpp
class monitor_example
{
public:
    struct mutex_type
    {
        void lock()
        {
            std::cout << "> lock" << std::endl;
        }
        void unlock()
        {
            std::cout << "> unlock" << std::endl;
        }
    };

    using monitor_ptr_type = monitor_ptr<monitor_example>;

    monitor_ptr_type monitor() noexcept
    {
        return {this, mtx_};
    }

    void print() const noexcept
    {
        std::cout << "print" << std::endl;
    }

private:
    mutex_type mtx_;
};

// usage:
monitor_example obj;
monitor_ptr mp = obj;
if (mp) {
    mp->print();
}

// or
monitor_ptr{obj}->print();
```

运行结果：[godbolt](https://godbolt.org/z/WYh5Kc8nf)

    > lock
    print
    > unlock
    > lock
    print
    > unlock

一般情况下，在内部实现中我们可以使用该方法，简化重复的样板代码。但对于要提供给外部人员使用的对象，不建议使用该方法，用户可能会直接使用原始对象，而不使用 `monitor_ptr` 来调用对象的方法从而导致问题。
