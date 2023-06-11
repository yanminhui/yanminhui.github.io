---

layout: post
title: '模板元编程'
subtitle: 'Template Metaprogramming'
date: 2023-06-10
categories: [article]
tags: 'C++' 

---

## 函数模板

支持完全特化与重载，但不支持部分特化。一般情况下，不要使用完全特化。

[Run this code](https://godbolt.org/z/PfnsY85zY)
```.cpp
template <typename T>
void print(T) {
    fmt::print("Generic");
};

// BAD: full specialization before base template
//      Overload resolution considers only base templates.
template<>
void print(double*) { 
    fmt::print("specialization"); 
};

template <typename T>
void print(T*) {
    fmt::print("overload");
}
```

函数模板的默认参数不必放在最后。

[Source insight](https://cppinsights.io/s/135e38c1)
```.cpp
template <class R = std::string_view, class T>
R to_string(T obj, R defaultv = "default") {
    try {
        static auto cache = std::to_string(obj);
        return {cache};
    } catch (...) {
        return defaultv;
    }
}
```

## [显示实例化](https://en.cppreference.com/w/cpp/language/class_template)

[Source insight](https://cppinsights.io/s/943f2d41)
```.cpp
// \file xxx.h
// Explicit instantiation declaration
extern template class std::vector<int>;

// \file xxx.cpp
// Explicit instantiation definition
template class std::vector<int>;
```

## 延迟计算(Lazy Computation)

[Run this code](https://godbolt.org/z/6hq3j5G61)
```.cpp
template <int n>
struct fib : conditional_t<n<0, fib<0>, integral_constant<int, (fib<n-1>::value + fib<n-2>::value)>>
{
};

template <>
struct fib<1> : integral_constant<int, 1>
{
};

template <>
struct fib<0> : integral_constant<int, 0>
{
};

static_assert(fib<6>::value == 8);
static_assert(fib<-1>::value == 0); // fatal error: template instantiation depth exceeds maximum of 900
```

当输入 `n < 0` 时，产生 `fatal error: template instantiation depth exceeds maximum of 900` 错误。计算 `fib<n>` 时， `fib<n>::value` 被求值导致无穷递归。

[Source insight](https://cppinsights.io/s/a61187fd)
```.cpp
template <class ...Ts>
struct sum;

template <int n>
struct fib : conditional_t<n<0, fib<0>, sum<fib<n-1>, fib<n-2>>>
{
};

template <>
struct fib<1> : integral_constant<int, 1>
{
};

template <>
struct fib<0> : integral_constant<int, 0>
{
};

template <class T, T ...N>
struct sum<fib<N>...> : integral_constant<T, (fib<N>::value + ...)>
{
};

static_assert(fib<6>::value == 8);
static_assert(fib<-1>::value == 0);
```

在表达式中避免计算内嵌类型 `type_identity::type` 或内嵌值 `value_identity::value`。

## BUG: [Pack expansion into fixed alias template parameter list](https://www.open-std.org/Jtc1/sc22/wg21/docs/cwg_active.html#1430)

Originally, a pack expansion could not expand into a fixed-length template parameter list, but this was changed in N2555. This works fine for most templates, but causes issues with alias templates.

In most cases, an alias template is transparent; when it's used in a template we can just substitute in the dependent template arguments. But this doesn't work if the template-id uses a pack expansion for non-variadic parameters. For example:

    template<class T, class U, class V>
    struct S {};

    template<class T, class V>
    using A = S<T, int, V>;

    template<class... Ts>
    void foo(A<Ts...>);

There is no way to express A<Ts...> in terms of S, so we need to hold onto the A until we have the Ts to substitute in, and therefore it needs to be handled in mangling.

Currently, EDG and Clang reject this testcase, complaining about too few template arguments for A. G++ did as well, but I thought that was a bug. However, on the ABI list John Spicer argued that it should be rejected.

引入间接层来解决该问题：

    template <class T, class U, class V>
    struct S {};

    template <class T, class V>
    using A = S<T, int, V>;

    template <template <class...> class C, class... Ts>
    struct defer {
        using type = C<Ts...>;
    };

    // 别名模板参数与 defer 一致
    template <template <class...> class C, class... Ts>
    using defer_t = typename defer<C, Ts...>::type;

    template <class... Ts>
    void foo(defer_t<A, Ts...>);
