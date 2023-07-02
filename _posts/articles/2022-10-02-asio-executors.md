---

layout: post
title: 'ASIO 执行器'
subtitle: 'ASIO Executors'
date: 2022-10-02
categories: [article]
tags: ['C++', 'ASIO', 'Multithreading'] 

---

C++11 标准库为我们执行异步任务提供了一个接口 [`async`](https://cplusplus.com/reference/future/async/)，一般这个接口里面会创建一个线程来执行。

```.cpp
std::future<int> f = std::async([]{
  // ...
  return 42;
});

int i = f.get(); 
```

Boost 1.74 ASIO 开始支持 [`executors`](https://think-async.com/executors/Executors_and_Asynchronous_Operations_Slides.pdf)，能够以不同方式执行异步任务。

```.cpp
std::future<int> f = post(
  package([]{
    // ...
    return 42;
  })
);

int i = f.get()
```

## Executor

执行器是用来管理一个函数对象在什么时候，在什么地点，以何种方式执行一个函数对象的一组规则集。它提供了 `context()` 来访问执行上下文，以及 `dispatch`, `post`, `defer` 操作。

特点：可以持续或短暂存活，是一个轻量可拷贝的对象。

比如：[`system_executor`](https://think-async.com/Asio/boost_asio_1_24_0/doc/html/boost_asio/reference/system_executor.html), [`strand`](https://think-async.com/Asio/boost_asio_1_24_0/doc/html/boost_asio/reference/io_context__strand.html)

## Execution context

执行上下文是指一个用来执行函数对象的场所。可以通过 `get_executor()` 来获取执行上下文关联的执行器，也就说获取的这个执行器执行函数对象时将在这个上下文上执行。

特点：一般在程序运行期间持续存活，并且不允许被拷贝。

比如：[`system_context`](https://think-async.com/Asio/boost_asio_1_24_0/doc/html/boost_asio/reference/system_context.html), [`static_thread_pool`](https://think-async.com/Asio/boost_asio_1_24_0/doc/html/boost_asio/reference/static_thread_pool.html)

## Dispatch, post and defer

这是用于提交用来执行的函数对象的三个基本操作，它们之间的不同体现在执行函数的迫切程度。

* `dispatch` 如果当前在执行上下文上将立即执行函数，否则执行 `post` 操作。
* `post` 无论当前是否在执行上下文上都会将函数排队，然后唤醒一个线程来执行它。
* `defer` 如果当前在执行上下文上会将函数排队，但是不会唤醒线程来执行它，而等待当前的控制回到执行上下文后再执行，否则执行 `post` 操作。

