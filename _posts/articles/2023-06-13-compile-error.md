---

layout: post
title: '定制编译期诊断信息'
subtitle: 'Customizing Compile-time Diagnostics'
date: 2023-06-13
categories: [article]
tags: 'C++' 

---

前不久，Eric Niebler 提升了 `stdexec` 的编译期诊断信息。他利用了 `concept` 在评估失败时编译器会打印出模板参数类型的特征，让那些查询类型属性的 `trait` 返回一个他定制的模板类，然后诊断消息命名成类名作为模板参数打印出来，而不是仅仅返回一个布尔值。

```.cpp
#include <type_traits>

// struct compile_error<What, With...>
//=====================================
struct none;

template <class What, class... With>
struct compile_error
{
};

template <>
struct compile_error<none>
{
};

// concept success<compile_error<...>>
//=====================================
namespace detail {

template <class T>
struct is_success : std::false_type
{
};

template <>
struct is_success<compile_error<none>> : std::true_type
{
};

template <class T>
inline constexpr bool is_success_v = is_success<std::remove_cvref_t<T>>::value;

} // namespace detail

template <class T>
concept success = detail::is_success_v<T>;

// Usage
//=======

struct NOT_CALLABLE;

template <class T>
struct WITH_SIGNATURE;

template <class T>
constexpr auto is_function()
{
    if constexpr(std::is_function_v<T>) {
        return compile_error<none>{};
    } else {
        return compile_error<NOT_CALLABLE, WITH_SIGNATURE<T>>{};
    }
}

int add(int a, int b) {
    return a + b;
}

template <class T>
#if defined(USE_COMPILE_ERROR)
    requires requires(T) {
        {is_function<T>()} -> success;
    }
#else
    requires std::is_function_v<T>
#endif
void foo(T f)
{
}

int main() {
    foo<int(int, int)>(add);
    foo(add);
}
```

* 改进前：仅仅告知在哪个地方诊断失败。
* 改进后：不仅告知在哪个地方诊断失败，也说明原因。

![diagnosatics](https://yanminhui.github.io/assets/img/diagnosatics.png)

这看起来很好，但是使用时有点受限，比如查询类型属性的模板参数不能用表达式（如：`decltype`）来推断模板参数类型，而且必须使用 `concept` 来触发条件评估。如下示例就无法达到目的：

```.cpp
template <class T>
requires detail::is_success_v<decltype(is_function<T>())>
void foo(T f) 
{
}
```

    % cc -std=c++20 diagnostics_example.cpp
    diagnostics_example.cpp:75:5: error: no matching function for call to 'foo'
        foo(add);
        ^~~
    diagnostics_example.cpp:69:6: note: candidate template ignored: constraints not satisfied [with T = int (*)(int, int)]
    void foo(T f)
        ^
    diagnostics_example.cpp:67:14: note: because 'detail::is_success_v<decltype(is_function<int (*)(int, int)>())>' evaluated to false
        requires detail::is_success_v<decltype(is_function<T>())>
                ^
    1 error generated.