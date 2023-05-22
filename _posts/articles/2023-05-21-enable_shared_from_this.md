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

## 扩展 static_pointer_cast / dynamic_pointer_cast

[Run this code](https://godbolt.org/z/K3jbnP5hj)
```.cpp
#include <cassert>
#include <concepts>
#include <iostream>
#include <memory>
#include <type_traits>
#include <utility>
#include <vector>

namespace stdpatch {

// concept: derived_from_enable_shared_from_this<T>
template <class T>
concept derived_from_enable_shared_from_this = requires(T p) {
    p.shared_from_this();
    requires std::derived_from<
        std::remove_cvref_t<T>, std::enable_shared_from_this<
            std::remove_cvref_t<typename decltype(p.shared_from_this())::element_type>>>;
};

// shared_ptr<T> static_pointer_cast(T* p)
template <derived_from_enable_shared_from_this T> std::shared_ptr<T>
static_pointer_cast(T* p) noexcept(noexcept(std::declval<T>().shared_from_this()))
{
    using shared_type = decltype(std::declval<T>().shared_from_this());
    using element_type = typename shared_type::element_type;

    assert(p);
    if constexpr (std::same_as<T, element_type>) {
        return p->shared_from_this();
    } else {
        return static_pointer_cast<T>(p->shared_from_this());
    }
}

// shared_ptr<T> static_pointer_cast<T>(shared_ptr<U> p)
template <class T, class U>
auto static_pointer_cast(U&& p) noexcept
{
    using type = std::remove_cvref_t<U>;
    using element_type = typename type::element_type;

    (void) static_cast<T*>(static_cast<element_type*>(nullptr));

    return std::static_pointer_cast<T>(std::forward<U>(p));
}

// shared_ptr<T> dynamic_pointer_cast(T* p)
template <derived_from_enable_shared_from_this T> std::shared_ptr<T>
dynamic_pointer_cast(T* p) noexcept(noexcept(std::declval<T>().shared_from_this()))
{
    using shared_type = decltype(std::declval<T>().shared_from_this());
    using element_type = typename shared_type::element_type;

    assert(p);
    if constexpr (std::same_as<T, element_type>) {
        return p->shared_from_this();
    } else {
        return dynamic_pointer_cast<T>(p->shared_from_this());
    }
}

// shared_ptr<T> dyanmic_pointer_cast<T>(shared_ptr<U> p)
template <class T, class U>
auto dynamic_pointer_cast(U&& p) noexcept
{
    using type = std::remove_cvref_t<U>;
    using element_type = typename type::element_type;

    (void) dynamic_cast<T*>(static_cast<element_type*>(nullptr));

    return std::dynamic_pointer_cast<T>(std::forward<U>(p));
}

} // namespace stdpatch

struct base_session
    : std::enable_shared_from_this<base_session> 
{
    virtual ~base_session() = default;
};

struct session
    : base_session 
{
    virtual void connect()
    {
        auto self = stdpatch::static_pointer_cast(this); // OK
        // ... init async connect
    }
};

struct ssl_session 
    : session
{
    void connect() override 
    {
        auto self = stdpatch::dynamic_pointer_cast(this); // OK
        // ... init async connect
    }
};

int main() {
    auto pssl = std::make_shared<ssl_session>(); // OK
    auto psession = std::make_shared<session>(); // OK

    using session_ptr = std::shared_ptr<base_session>;
    std::vector<session_ptr> v = {pssl, psession}; // OK
}
```

既然 `shared_from_this()` 无法达到要求，那就写个函数来适配它。

标准库的 [`static_pointer_cast()`](https://en.cppreference.com/w/cpp/memory/shared_ptr/pointer_cast) 用于创建 `std::shared_ptr` 的新实例，它存储的指针通过 `static_cast` 转换实参存储的指针取得。

由于 `enable_shared_from_this` 存储的指针类型，并不是派生类类型，类似于 `static_pointer_cast` 语义，需要进行类型转换。我们可以考虑拿到 `enable_shared_from_this` 存储的指针，转换到期望的类型，因此可以扩展 `static_pointer_cast` 来达到目的。

扩展的 `static_pointer_cast()`，利用参数依赖查找机制获取对象的实际类型，检查对象是否实际派生于 `enable_shared_from_this` 以确保可以取得它存储的指针，然后再使用 `std::static_pointer_cast` 转换到符合要求的类型。

因此，也可以直接使用 `std::static_pointer_cast<T>(enable_from_this())` 获取，只是相比 `stdpatch::static_pointer_cast(this)` 要麻烦一些。
