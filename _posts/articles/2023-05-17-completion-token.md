---

layout: post
title: '完成令牌（completion token）'
subtitle: '完成令牌（completion token）'
date: 2023-05-17
categories: [article]
tags: ['C++', 'ASIO']

---

在 ASIO 中我们可以使用很多种表现形式来调用异步接口，这种技术称为 [completion token](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p1943r0.html)，用于定制库异步操作 API 表面的一种机制，它能自动使异步操作适应用户喜欢用的形式。

## 一般的回调

一般的回调形式，对代码实现者来说看起来相当简单。

[Run this code](https://godbolt.org/z/4E41nEW8M)
```.cp
#include <iostream>

template <class CompletionHandler>
void async_add(int a, int b, CompletionHandler&& handler) {
    std::forward<CompletionHandler>(handler)(a + b);
}

int main() {
    async_add(1, 2, [](int n) {
        std::cout << "callback: " << n << std::endl;
    });

    // wait return from async operation...
}
```

## 支持 completion token

为了让用户可以使用不同的表现形式来调用异步操作，并且对原来的用户没有影响。首先就是要提供一个跟原来表现形式一样的接口出来，但更加范型。然后把原来的接口原样的隐藏起来，在这里就是把它放入私有的命名空间，让用户看不到。

引入 `async_result` 的适配层来转发或修改用户的调用形式，使其既能符合用户的期望，又能转换到原始的异步调用形式。它有两个模板参数：
- CompletionToken：用户期望的回调形式。
- Signature：需要适配成原始异步操作的回调签名。

适配层的主要工作由 `initiate()` 函数来完成。它有三个参数来转发用户的输入：
- initiation：原始异步函数，这是个模板函数，难以作为参数传递，所以需要封装成函数对象，如 `async_add_op`。
- token：用户期望的回调形式实例，即 completion token，如果只是转发那么就是原始异步函数的回调实例。
- args...：异步操作的输入参数，原样转发给原始异步函数。

所以，可以看到 `async_result` 只是一个普通的转发工作，什么也不做，对原来使用原始异步操作函数的用户没有影响。

[Run this code](https://godbolt.org/z/jqKer4nnd)
```.cpp
#include <iostream>

namespace detail {

template <class CompletionHandler>
void async_add(int a, int b, CompletionHandler&& handler) {
    std::forward<CompletionHandler>(handler)(a + b);
}

struct async_add_op {
    template <class CompletionHandler>
    void operator()(int a, int b, CompletionHandler&& handler) const {
        return detail::async_add(a, b, std::forward<CompletionHandler>(handler));
    }
};

}  // namespace detail

// forward call
template <class CompletionToken, class Signature>
struct async_result 
{
    template <class Initiation,
              class RawCompletionToken,
              class... Args>
    static auto initiate(Initiation&& initiation, 
                         RawCompletionToken&& token,
                         Args&&... args)
    {
        return std::forward<Initiation>(initiation)(std::forward<Args>(args)...,
                                                    std::forward<RawCompletionToken>(token));
    }
};

// user interface
template <class CompletionToken>
auto async_add(int a, int b, CompletionToken token) {
    using signature_t = void(int);
    using result_t = async_result<CompletionToken, signature_t>;
    return result_t::initiate(detail::async_add_op{},
                              token,
                              a,
                              b);
}

int main() {
    // for callback by forward call
    async_add(1, 2, [](int n) {
        std::cout << "callback: " << n << std::endl;
    });

    // wait return from async operation...
}
```

## 定制 completion token

接下来，要动点手脚了。为了使原来的异步操作函数支持 [`future continuation`](https://en.cppreference.com/w/cpp/experimental/future/then) 的调用形式，可以使用 [类模板偏特化](https://en.cppreference.com/w/cpp/language/template_specialization) 来定制 `async_result` 实现适配。

> 由于 C++ 标准库现在没有对 `future continuation` 提供支持，所以这里只演示通过 `future` 获取结果。

[Run this code](https://godbolt.org/z/dYozEMEGc)
```.cpp
#include <future>
#include <tuple>
#include <type_traits>

// for future
constexpr struct use_future_t {} use_future;

template <class R, class... RArgs>
struct async_result<use_future_t, R(RArgs...)>
{
    template <class Initiation,
              class... Args>
    static auto initiate(Initiation&& initiation, 
                         use_future_t,
                         Args&&... args)
    {
        std::promise<std::tuple<std::remove_cvref_t<RArgs>...>> p;
        auto fut = p.get_future();

        auto handler = [pp = std::move(p)](RArgs... rargs) mutable {
            pp.set_value(std::make_tuple(rargs...));
        };
        std::forward<Initiation>(initiation)(std::forward<Args>(args)...,
                                             std::move(handler));
        return fut;
    }
};

int main() {
    // for future
    auto fut = async_add(1, 2, use_future);
    auto [n] = fut.get();
    std::cout << "future: " << n << std::endl;
}
```
