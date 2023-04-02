---

layout: post
title: 'C++ 匿名函数惯用法'
subtitle: 'C++ Lambda Idioms'
date: 2023-04-02
categories: [article]
tags: 'C++' 

---

## Unary plus trick

```.cpp
auto f = +[](int i){ return i * i; };  // explicit conversion to function pointer
static_assert(std::is_same_v<decltype(f), int(*)(int)>);
```

## Immediately Invoked Function Expressions (IIFE)

```.cpp
const Foo foo = [&]{
    if (hasDatabase) {
        return getFooFromDatabase();
    } else {
        return getFooFromElsewhere();
    } 
}();
```

`Foo` 没有默认的构造函数，或者定义为常量需要立即初始化，这个初始化依赖一些逻辑的情况。

## Call-once Lambda

```.cpp
static auto _ = []{
    std::cout << "called once!";
    return 0; 
}();
```

[what is the difference between std::call_once and function-level static initialization](https://stackoverflow.com/questions/17407553/what-is-the-difference-between-stdcall-once-and-function-level-static-initiali)

## Init capture optimisation

```.cpp
const std::vector<std::string> vs = {“apple", "orange", "foobar", "lemon"};
const std::string prefix = "foo";

auto result = std::find_if(vs.begin(), vs.end(),
    [&prefix](const std::string& s) {
        return s == prefix + "bar";
    });

// optimisation
auto result = std::find_if(vs.begin(), vs.end(),
    [str = prefix + "bar"](const std::string& s) {
        return s == str;
    });
```

## Lambda overload set

```.cpp
template <typename... Ts>
struct overload : Ts... {
    using Ts::operator()...;
};


overload f = {
    [](int i){ std::cout << "int thingy"; },
    [](float f){ std::cout << "float thingy"; }
};

f(2);     // prints int thingy
f(2.0f);  // prints float thingy
```