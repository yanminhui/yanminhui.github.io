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

为了解决前面的问题，在实际工作中，可以看到类似上面的代码，引入多继承来解决。这也存在一些问题：
- `ssl_session` 无法通过继承复用 `session` 的功能，只能通过聚合 `session` 作为成员变量处理。
- 当继承链长时，通过聚合访问里层函数需要长的名字引用（e.g. `pssl->psession->...`）。

## 覆盖 `shared_from_this()`

[Run this code](https://godbolt.org/z/b7azhsvf4)
```.cpp
#include <iostream>
#include <memory>
#include <vector>

struct base_session
    : std::enable_shared_from_this<base_session>
{
    template <class T>
    static std::shared_ptr<T> shared_from_this(T* self) { // T* for ADL
        using base = std::enable_shared_from_this<base_session>;
        return std::static_pointer_cast<T>(self->base::shared_from_this());
    }
};

struct session : base_session
{
    virtual void connect() {
        std::shared_ptr<session> self = shared_from_this(this);
        // ... init async connect
    }
};

struct ssl_session : session
{
    void connect() override {
        std::shared_ptr<ssl_session> self = shared_from_this(this);
        // ... init async connect
    }
};

int main() {
    auto pssl = std::make_shared<ssl_session>(); // OK
    auto psession = std::make_shared<session>(); // OK
    
    using session_ptr = std::shared_ptr<base_session>;
    std::vector<session_ptr> v = {pssl, psession};  // OK
}
```

利用参数依赖查找机制获取对象的实际类型，在基类中声明同名的成员函数 `shared_from_this()` 来覆盖原始的函数。