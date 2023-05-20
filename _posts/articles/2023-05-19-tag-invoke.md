---

layout: post
title: 'tag_invoke'
subtitle: 'tag_invoke'
date: 2023-05-19
categories: [article]
tags: 'C++' 

---

## [Argument Dependent Lookup](https://en.cppreference.com/w/cpp/language/adl)

[Run this code](https://godbolt.org/z/EaxGE1ajY)
```.cpp
#include <iostream>

namespace lib1 {

template <class T>
void print(T const& t) {
    std::cout << "lib1::print()" << std::endl;  
}

} // namespace lib1
namespace lib2 {

struct w {
    int x_;
};

void print(w const&) {
    std::cout << "lib2::print()" << std::endl;
}

} // namespace lib2

lib2::w x;
lib1::print(x); // #1 lib1::print -- NOT EXPECTED
lib2::print(x); // #2 lib2::print

using namespace lib1;
print(x);       // #3 lib2::print -- ADL
```

当我们在基础库 `lib1` 中定义 `print` 方法后，希望用户可以根据自己的需要自定义 `print` 的行为。如上述代码，期望以限定名 `lib1::print(x)` 调用时可以调用用户自定义的代码，然而并没有达到期望。

## [Customization Point Object](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4381.html)

[Run this code](https://godbolt.org/z/f1G1hrMs6)
```.cpp
#include <iostream>

namespace lib1 {
namespace cpo {

struct print_t {
    template <class T>
    friend void print(T const& t) {
        std::cout << "lib1::print()" << std::endl;  
    }

    template <class T>
    constexpr void operator()(T&& t) const {
        return print(t);
    }
};

} // namespace cpo

constexpr cpo::print_t print;

} // namespace lib1

// ... lib2 code ...

lib2::w x;
lib1::print(x); // #1 lib2::print -- EXPECTED
lib2::print(x); // #2 lib2::print

using namespace lib1;
print(x);       // #3 lib2::print -- EXPECTED
```

为了解决以限定名 `lib1::print(x)` 调用时，可以调用用户自定义的代码，Eric Niebler 在他的 range-v3 中提出了 CPO 的想法。当把函数提升为对象后可以避免参数依赖查找，然后在对象内正确处理需要调用的函数，如上述代码。

后来，Eric Niebler 在实践 [libunifex](https://github.com/facebookexperimental/libunifex) 过程中，发现太多需要自定义的地方，导致用户在用户的命名空间内大量声明 libunifex 要求的函数，污染了用户命名空间，于是对 CPO 进行改进，提出了 `tag_invoke`。

## [tag_invoke](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p1895r0.pdf)

[Run this code](https://godbolt.org/z/K8d5bbcdE)
```.cpp
#include <iostream>
#include <type_traits>

namespace lib1 {

constexpr struct tag_invoke_t {
    template <class CPO, class T>
    constexpr void operator()(CPO&& cpo, T&& t) const {
        return tag_invoke(std::forward<CPO>(cpo), std::forward<T>(t));
    }
} tag_invoke;

namespace cpo {

struct print_t {
    template <class T>
    friend void tag_invoke(print_t, T const& t) {
        std::cout << "lib1::print()" << std::endl;  
    }

    template <class T>
    constexpr void operator()(T&& t) const {
        return tag_invoke(print_t{}, std::forward<T>(t));
    }
};

} // namespace cpo

constexpr cpo::print_t print;

} // namespace lib1
namespace lib2 {

// ... struct w ...

void tag_invoke(std::remove_cvref_t<decltype(lib1::print)>, w const&) {
    std::cout << "lib2::print()" << std::endl;
}

} // namespace lib2

lib2::w x;
lib1::print(x); // #1 lib2::print -- EXPECTED

using namespace lib1;
print(x);       // #2 lib2::print -- EXPECTED
```

`tag_invoke` 本质上仍为 CPO，然后用个 CPO 通过将需要自定义的 CPO 提升为函数参数来统一自定义函数的名称。

## [Customisable Function Prototype](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2022/p2547r0.pdf)

CFP 提出了语法级别上支持自定义函数的方案，目前还不支持，详见 [P2547R0](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2022/p2547r0.pdf)。