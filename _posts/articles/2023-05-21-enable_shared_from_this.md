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

## 自定义 `shared_from`

[Run this code](https://godbolt.org/z/czqKGWPPn)
```.cpp
#include <cassert>
#include <concepts>
#include <iostream>
#include <memory>
#include <type_traits>
#include <vector>

// concept: derived_from_enable_shared_from_this<T>
template <class T>
concept derived_from_enable_shared_from_this = requires(T obj) {
    obj.shared_from_this();
    requires std::derived_from<
        std::remove_cvref_t<T>, std::enable_shared_from_this<
            std::remove_cvref_t<typename decltype(obj.shared_from_this())::element_type>>>;
};

// cpo: shared_from(T* p)
//      shared_from_with_dynamic_cast(T* p)
template <bool with_dynamic_cast = false>
struct shared_from_t 
{
    template <derived_from_enable_shared_from_this T>
    constexpr std::shared_ptr<T> operator()(T* p) const 
    {
        assert(p);
        auto sp = p->shared_from_this();
        if constexpr (std::same_as<T, typename decltype(sp)::element_type>) {
            return sp;
        } else if constexpr (with_dynamic_cast) {
            return std::dynamic_pointer_cast<T>(sp); 
        } else {
            return std::static_pointer_cast<T>(sp);
        }
    }
};

constexpr shared_from_t shared_from;
constexpr shared_from_t<true> shared_from_with_dynamic_cast;


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
        std::shared_ptr<session> self = shared_from(this); // OK
        // ... init async connect
    }
};

struct ssl_session 
    : session
{
    void connect() override 
    {
        std::shared_ptr<ssl_session> self = shared_from_with_dynamic_cast(this); // OK
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

既然 `shared_from_this()` 无法达到要求，那就写个函数来适配它。`shared_from` 利用参数依赖查找机制获取对象的实际类型，检查对象是否实际派生于 `enable_shared_from_this`，再进行强制类型转换到符合要求的类型。

> 也可以直接使用 `auto self = std::static_pointer_cast<T>(enable_from_this());` 获取，相比 `auto self = shared_from(this)` 要冗长一些。