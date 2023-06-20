---

layout: post
title: '在派生类内获取共享指针'
subtitle: '在派生类内获取共享指针'
date: 2023-05-21
categories: [article]
tags: 'C++' 

---

## Curiously Recurring Template Pattern

[Run this code](https://godbolt.org/z/zc43d491e)
```.cpp
#include <iostream>
#include <memory>

template <class T>
struct base_session
    : std::enable_shared_from_this<T>
{};

template <class T>
struct session : base_session<T>
{};

struct ssl_session : session<ssl_session>
{};

int main() {
    auto pssl = std::make_shared<ssl_session>(); // OK
    auto psession = std::make_shared<session<session>>(); // ERROR
}
```

为了在类内部取得 `shared_ptr`，使用 CRTP。这也导致了一些问题：
- 无法实例化中间类 `session`
- 无法在容器中存储基类指针 `shared_ptr<base_session>`

## 多继承

[Run this code](https://godbolt.org/z/je4xx3Td7)
```.cpp
#include <iostream>
#include <memory>
#include <vector>

struct base_session
{};

struct session : base_session
    , std::enable_shared_from_this<session>
{};

struct ssl_session : base_session
    , std::enable_shared_from_this<ssl_session>
{
    std::shared_ptr<session> session_; // aggregation
};

int main() {
    auto pssl = std::make_shared<ssl_session>(); // OK
    auto psession = std::make_shared<session>(); // OK
    
    using session_ptr = std::shared_ptr<base_session>;
    std::vector<session_ptr> v = {pssl, psession}; // OK
}
```

为了解决前面的问题，在实际工作中，可以看到类似上面的代码（[相似问题](https://www.codeproject.com/Articles/286304/Solution-for-multiple-enable-shared-from-this-in-i)），引入多继承来解决。这也存在一些问题：
- `ssl_session` 无法通过继承复用 `session` 的功能，只能通过聚合 `session` 作为成员变量处理。
- 当继承链长时，通过聚合访问里层函数需要长的名字引用（e.g. `pssl->psession->...`）。

## `shared_ptr<T> as_shared(T* p)`

[Run this code](https://godbolt.org/z/xzcz3zEY4)
```.cpp
#include <cassert>
#include <concepts>
#include <type_traits>
#include <utility>
#include <vector>

#if __has_include(<boost/smart_ptr.hpp>)
#   define NS boost
#   include <boost/smart_ptr.hpp>
#   include <boost/type_traits/is_virtual_base_of.hpp>
#else
#   define NS std
#   include <memory>
#endif

// concept: derived_from_enable_shared_from_this<T>
template <class T>
concept derived_from_enable_shared_from_this = std::derived_from<T,
    typename std::pointer_traits<decltype(std::declval<T>().shared_from_this())>::element_type>;

// shared_ptr<T> as_shared(T* p)
template <derived_from_enable_shared_from_this T> 
inline auto as_shared(T* p) noexcept(noexcept(std::declval<T>().shared_from_this()))
{
    using shared_type = decltype(std::declval<T>().shared_from_this());
    using U = typename std::pointer_traits<shared_type>::element_type;

    assert(p);
    if constexpr (std::same_as<U, T>) {
        return p->shared_from_this();
    // } else if constexpr (boost::is_virtual_base_of<U, T>::value) {
    //     (void)dynamic_cast<T*>(static_cast<U*>(nullptr));
    //     return dynamic_pointer_cast<T>(p->shared_from_this()); // ADL
    } else {
        (void)static_cast<T*>(static_cast<U*>(nullptr));
        return static_pointer_cast<T>(p->shared_from_this()); // ADL
    }
}

struct base_session : NS::enable_shared_from_this<base_session> 
{
};

struct session : base_session 
{
    virtual void connect()
    {
        auto self = as_shared(this); // OK
        // ... init async connect
    }
};

struct ssl_session : session
{
    void connect() override 
    {
        auto self = as_shared(this); // OK
        // ... init async connect
    }
};

int main() {
    using namespace NS;
    auto pssl = make_shared<ssl_session>(); // OK
    auto psession = make_shared<session>(); // OK

    using session_ptr = shared_ptr<base_session>;
    std::vector<session_ptr> v = {pssl, psession}; // OK
}
```

既然 `shared_from_this()` 无法达到要求，那就写个函数来适配它。

标准库的 [`static_pointer_cast()`](https://en.cppreference.com/w/cpp/memory/shared_ptr/pointer_cast) 用于创建 `std::shared_ptr` 的新实例，它存储的指针通过 `static_cast` 转换实参存储的指针取得。

由于 `enable_shared_from_this` 存储的指针类型，并不是派生类类型，类似于 `static_pointer_cast` 语义，需要进行类型转换。我们可以考虑拿到 `enable_shared_from_this` 存储的指针，转换到期望的类型，因此可以扩展 `static_pointer_cast` 来达到目的。

扩展的 `static_pointer_cast()`，利用参数依赖查找机制获取对象的实际类型，检查对象是否实际派生于 `enable_shared_from_this` 以确保可以取得它存储的指针，然后再使用 `std::static_pointer_cast` 转换到符合要求的类型。当基类是虚继承时，无法使用 `static_pointer_cast()`，为了兼容这种情况，将这个扩展的函数改名为 `as_shared()`。

因此，也可以直接使用 `std::static_pointer_cast<T>(shared_from_this())` 或 `std::dynamic_pointer_cast<T>(shared_from_this())` 获取，只是相比 `as_shared(this)` 要麻烦一些。

## 类型擦除

[Run this code](https://godbolt.org/z/YbPn6dbd5)
```.cpp
// concept: member_function_get_shared<T>
template <class T>
concept member_function_get_shared = not derived_from_enable_shared_from_this<T> && 
    requires(T* p) {
        static_pointer_cast<T>(p->get_shared());
    };

// overload: shared_ptr<T> as_shared(T* p)
template <member_function_get_shared T>
inline auto as_shared(T* p)
{
    using shared_type = decltype(std::declval<T>().get_shared());
    using U = typename std::pointer_traits<shared_type>::element_type;

    if constexpr (std::same_as<U, T>) {
        return p->get_shared();
    } else {
        (void)static_cast<T*>(static_cast<U*>(nullptr));
        return static_pointer_cast<T>(p->get_shared());
    }
}

// Example:
//==========
using namespace std;

struct A 
{
    virtual ~A() = default;
    virtual shared_ptr<void> get_shared() const = 0;

    void foo1() {
        auto self = as_shared(this);
        // ...
    }
};

struct B
{
    virtual ~B() = default;
    virtual shared_ptr<void> get_shared() const = 0;

    void foo2() const {
        auto self = as_shared(this);
        // ...
    }
};

struct C : enable_shared_from_this<C>, A, B
{
    shared_ptr<void> get_shared() const override 
    {
        return static_pointer_cast<void>(const_cast<C*>(this)->shared_from_this());
    }
};

int main() 
{
    auto c = make_shared<C>();
    // ...
}
```

有时候，可能需要继承多个类，这些类内需要使用 `shared_ptr` 来做一些异步逻辑，然而无法在这些类上继承 `enable_shared_from_this`。这种情况可以考虑使用模板方法，在这些类上定义一个获取 `shared_ptr` 的接口，如 `get_shared()`，由最终的实现者来实现。

在基类上要获取的 `shared_ptr` 元素类型应该是基类本身，有多个基类的情况下，应让 `get_shared()` 返回的类型一致，这个时候考虑类型擦除，返回一个 `shared_ptr<void>`。但是在类里面使用 `shared_ptr<void>` 是相当不便的，这时可以重载 `as_shared()` 进行处理。 