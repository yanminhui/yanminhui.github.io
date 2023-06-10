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
static_assert(fib<-900>::value == 0); // fatal error: template instantiation depth exceeds maximum of 900
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
static_assert(fib<-900>::value == 0);
```

在表达式中避免计算内嵌类型 `type_identity::type` 或内嵌值 `value_identity::value`。