---

layout: post
title: 'C++20 协程'
subtitle: 'C++20 coroutines'
date: 2022-09-12
categories: [article]
tags: 'C++' 

---

## 协程的概念

协程是可恢复的函数，它本质上也是个函数，但不像普通的函数，调用后等待值的返回。调用者与协程间可以通过 `Invoke`、`Activate`、 `Supspend`、 `Finalize` 四个操作协作完成任务，也就是说调用者与协程间可以传递上下文，不必像函数那样调用完就销毁了，再也访问不到函数的内部状态。

| Operation | Subroutine |     Coroutine     |                                      |
| :-------- | :--------: | :---------------: | :----------------------------------- |
| Invoke    | func(args) |    func(args)     | General procedure start              |
| Activate  |     x      |     resume()      | `goto` a specific point of procedure |
| Suspend   |     x      | co_yield/co_await | Yield current control flow           |
| Finalize  |   return   |     co_return     | Cleanup and return                   |

<img src="https://cgiska.bn1304.livefilestore.com/y4myyjBEM4mTFN8yloP0iVkJc-b8wQ_OzKXH-Y03gXYlJqaxpsg7db3xWQAxUujyjQamngJ9mw7cnHmFt3_W2qxviWYpMzdRR6iub1Msi_bZOHuB76FbOOdfrhDo5yen6OAzJH48zRRfbbiiboTzymHRLN5xOosm6PyywXhQO9lYo80KY_lPRhaUMu-dcPkbu3wiL0OtjtiyJE8iGt1-d4vbw?width=1024&height=607&cropmode=none" width="600px">

协程使我们可以以同步的方式编写异步的逻辑让代码结构更加简洁清晰。

## 协程函数体

编译器将侵入用户编写的代码，对其进行包裹。
* 编译器将在 **堆空间** 上申请一个帧结构，用于存储协程的入口地址、参数变量、局部变量、用于调用者与协程函数体间交换信息的结构 `promise_type` 等信息；
* 然后挂起后将协程的返回值返回给调用者，待调用者调用恢复 `resume` 后开始执行用户的代码；
* 如果这个过程中抛出异常将传递给 `promise_type`：
  - 如果调用者未调用 `resume` 之前抛出的异常会将异常传递出来；
  - 否则异常会通过 `promise_type::unhandled_exception` 传给 `promise`。
* 待协程执行完将调用 `final_suspend` 最后一次挂起：
  - 如果它挂起的话需要用户调用 `coroutine_handle::destory` 释放编译器在堆空间上申请的帧结构
  - 否则编译器将自己释放这个内存空间

```.cpp
auto fibonacci(int n) {
  // At this point, compiler will generate code and check `return_type` fulfills
  // promise requirement.
  using return_type = generator<int>;
  using traits = coroutine_traite<return_type>;

  // We can generate unique frame type for this function.
  struct __frame {
    // `_Resumable_frame_prefix`
    Frame_Prefix _prefix;

    // Resumable Promise Requirement
    generator<int>::promise_type _promise;

    // Captured arguments
    int _n;  // fibonacci(n);

    int _f1, _f2;  // Local variable
    int _i, _f3;   // Temporaries

    // Platform dependent storage
    // for registers, etc.
  };

  try {
    // We are forwarding arguments to frame!
    __frame* ctx = new __frame{std::move(n)};

    // Generate return objet
    return_type __return = ctx->_promise.get_return_object();

    // Suspend if true else keep move...
    if (ctx->_promise.initial_suspend()) {
    __initial_suspend_point:
    }

    // User code : use variables in frame(ctx)...
    // ---- ---- ---- ---- ----
    ctx->_f1 = 0;
    ctx->_f2 = 1;

    for (ctx->_i = 0; ctx->_i < ctx->_n; ctx->_i++) {
      // co_yield f1;
      ctx->_promise.yield_value(ctx->_f1);
    __suspend_resume_point_1:

      // Calculate next fibo and shift
      ctx->_f3 = ctx->_f1 + ctx->_f2;
      ctx->_f1 = ctx->_f2;
      ctx->_f2 = ctx->_f3;
    }

    // co_return;
    ctx->_promise.set_result();
    goto __final_suspend_point;
    // ---- ---- ---- ---- ----
  } catch (...) {
    if (!initial_await_resume_called()) throw;
    ctx->_promise.unhandled_exception();
  }

  if (ctx->_promise.final_suspend()) {
  __final_suspend_point:
  }
  // Instructions for clean up...
}
```

## the promise object

在协程函数体的伪代码中，我们可以看到，编译器在堆空间上申请的帧结构有一个 `promise_type _promise`，这个结构由用户实现，用于调用者与协程函数体间交换信息。它应该满足以下必备条件：

| Expression                             | Note                                                                         |
| :------------------------------------- | :--------------------------------------------------------------------------- |
| P{}                                    | Promise must be default constructible                                        |
| corountine_trait p.get_return_object() | The return value of funtion. It can be future<T>, or some user-defined type. |
| awaitable p.initial_suspend()          | If return suspend, suspends at initial suspend point.                        |
| awaitable p.final_suspend()            | If return suspend, suspends at final suspend point.                          |
| void p.unhandled_exception()           | It will be called when the resumer activates the function with exception.    |
| awaitable p.yield_value(v)             | Pass the value v and the value will be consumed later by `co_yield v;`       |
| void p.return_value(v)                 | Pass the value v and the value will be consumed later by `co_return v;`      |
| void p.return_value()                  | Pass void and can be invoked when the coroutine returns by `co_return ;`     |
| awaitable await_transform(expr)        | Convert expr to awaitable object by `co_await expr;`                         |

> co_yield v; => co_await p.yield_value(v);
> 
> co_return v; => p.return_value(v);
>
> co_return ; => p.return_value();

## coroutine_handle<>

编译器在堆空间上申请的帧结构内的 `_promise` 为了让调用者和协程函数体使用户可以访问到，定义了 `coroutine_handle` 结构指向该地址，通过帧结构内 `_promise` 的地址偏移可以访问到帧结构。

| Expression                              | Note                                                |
| :-------------------------------------- | :-------------------------------------------------- |
| static coroutine_handle from_promise(p) | 在 promise 对象内可以将自己转换成 coroutine_handle. |
| promise& h.promise()                    | 返回 promise 对象的引用，使用户可以访问 promise.    |
| void h.resume()                         | 恢复挂起的协程，让其继续执行.                       |
| void perator()()                        | 同上                                                |
| operator bool()                         | 检查句柄是否指向一个协程.                           |
| bool h.done()                           | 检查挂起的协程是否是在 `final_suspend()` 上挂起.    |
| void h.destory()                        | 销毁编译器在协程函数体内创建的帧结构                |

调用者可以使用 `coroutine_handle` 来控制协程和访问 `promise`。

协程函数体用户可以通过 `coroutine_handle` 来访问 `promise`。

## the coroutine return object

C++20 协程函数要求返回值必须符合 [`coroutine_traits`](https://en.cppreference.com/w/cpp/coroutine/coroutine_traits) 要求，也就是返回值类型内嵌 `promise_type`，然后这个内嵌的类型的 `get_return_object()` 可以构造出返回值对象。

一般情况会在返回值内声明一个 `coroutine_handle` 成员，然后编译器调用 `get_return_object()` 将 `this` 通过 `coroutine_handle::from_promise(*this)` 转换到 `coroutine_handle`，然后初始化这个成员，并在第一次挂起时将这个返回值对象交给调用者，这样调用者就可以拿到协程句柄来控制协程。

```.cpp
struct return_type {
  // 内嵌类型
  struct promise_type {
    return_type get_return_object() {
      return { std::coroutine_handle<promise_type>::from_promise(*this) };
    }
  };

  std::coroutine_handle<promise_type> h_;
};
```

## awaitable

### Normally Awaitable

支持 `co_await` 操作的类型被称为可等待的类型，一个可等待的对象必须实现以下三个函数:

| Expression                     | Note                                                                                               |
| :----------------------------- | :------------------------------------------------------------------------------------------------- |
| bool await_ready()             | `await_resume()` 要继续的条件是否准备好, true 将跳过 `await_suspend()`，否则进入 `await_resume()`. |
| auto await_suspend(handle<> h) | suspend if void, true, noop_coroutine(); continue if false; h.resume if valid handle.              |
| T await_resume()               | 返回值为 `co_await expr;` 的返回值.                                                                |

> `await_ready()` 是个优化，没有它，`await_suspend(h)` 通过返回值也可以决定要不要挂起。
> 
> 编译器调用 `await_suspend()` 需要将当前协程状态保存到堆上是个代价，如果 `await_ready()` 返回 true，可以跳过这个过程，直接进入 `await_resume()` 是个优化。

<img src="https://bqivka.bn1304.livefilestore.com/y4mfcDYFCH6SMe0hrR74BNJzFaua5hK_tksI8vp8pdRykhjrX1yuUOQoHrhFVFu9ci5icB6lOrMGLwaC74PxZthzgw8u-O4yNDAgEnkT5EMTPv7CcAVmOX6DHF_Ofi44GE33IJgYheftmKUrKX46k9SubyycOFSpsjxd_2Vj5bKAwzML-6geswyforIr-YIeBH1_B82cMEKrJnsOf5kJDOfbQ?width=1024&height=692&cropmode=none" width="600px">

### Contextually Awaitable

* [上下文的可等待对象](https://lewissbaker.github.io/2017/11/17/understanding-operator-co-await)为第一优先级，通过 `promise_type::await_transform(expr)` 将 `co_await expr;` 中的 expr 转成可等待对象；
* 接着尝试通过 `operator co_await` 操作符重载(作为成员函数)来获取可等待对象；
* 接着尝试通过 `operator co_await` 操作符重载(非成员函数)来获取可等待对象；
* 然后直接使用 Normally Awaitable 的成员函数。 

## Reference

- [My tutorial and take on C++20 coroutines](https://www.scs.stanford.edu/~dm/blog/c++-coroutines.html)
- [Exploring MSVC Coroutine](https://luncliff.github.io/coroutine/articles/exploring-msvc-coroutine/)
- [C++ Coroutines](https://lewissbaker.github.io/)