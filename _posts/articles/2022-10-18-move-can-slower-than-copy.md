---

layout: post
title: '移动操作可能比拷贝更慢'
subtitle: 'Move Can Be Much Slower Than Copy'
date: 2022-10-18
categories: [article]
tags: 'C++' 

---

《[C++ Primer, 5th Edition](https://zhjwpku.com/assets/pdf/books/C++.Primer.5th.Edition_2013.pdf)》中在讲到移动对象一章（Copy-and-Swap Assignment Operators and Move）时例举了一个例子 `HasPtr`，得出结论：单一的赋值运算符就能得到拷贝赋值运算符和移动赋值运算符两种功能。

```.cpp
class HasPtr {
public:
    // added move constructor
    HasPtr(HasPtr &&p) noexcept : ps(p.ps), i(p.i) {p.ps = 0;}
    // assignment operator is both the move- and copy-assignment operator
    HasPtr& operator=(HasPtr rhs)
                    { swap(*this, rhs); return *this; }
    // other members as in § 13.2.1 (p. 511)
};
```

For example, assuming both hp and hp2 are `HasPtr` objects:

```.cpp
hp = hp2; // hp2 is an lvalue; copy constructor used to copy hp2
hp = std::move(hp2); // move constructor moves hp2
```

由此，可能就有人写出如下代码，实现类似功能，如：[Why is value taking setter member functions not recommended](https://stackoverflow.com/questions/26261007/why-is-value-taking-setter-member-functions-not-recommended-in-herb-sutters-cpp)

```.cpp
// BAD:
class employee {
    std::string name_;
public:
    void set_name(std::string name) noexcept { name_ = std::move(name); }
};
```

虽然，`set_name` 集拷贝赋值运算符和移动赋值运算符于一体，但 Herb Sutter 在 [CppCon 2014](https://github.com/CppCon/CppCon2014/blob/7b15ec44ac01de0ff3e65a7194b84aca2d4e2366/Presentations/Back%20to%20the%20Basics!%20Essentials%20of%20Modern%20C++%20Style/Back%20to%20the%20Basics!%20Essentials%20of%20Modern%20C++%20Style%20-%20Herb%20Sutter%20-%20CppCon%202014.pdf) 第32页说它是一种反面模式（`anti-pattern`），性能会比参数声明为常引用（`void set_name(const std::string&)`）差，原因在于:

1. 当传一个 `std::string` 左值时，如果目标字符串有足够的空间来持有要拷贝的数据时，`std::string` 拷贝例程将重用目标字符串已经分配的存储。
2. 当传一个 `std::string` 右值时，移动赋值操作将释放目标字符串已存在的存储，然后接管源字符串的存储。

`void set_name(std::string)` 被调用时：调用者传左值时，先调用形参拷贝构造申请存储来存放实参源字符串，然后执行 `name_ = std::move(name)` 时释放目标字符串已经分配的存储，再接管形参字符串的存储。

`void set_name(const std::string&)` 被调用时：调用者传左值时，先使形参字符串指向实参源字符串，然后执行 `name_ = name` 时能够重用已经分配的存储，将形参指向的内容拷贝进来，**避免形参申请存储和释放目标存储**。

所以，更好的代码应该是下面这个样子：

```.cpp
// GOOD:
class employee {
    std::string name_;
public:
    void set_name(const std::string& name) { name_ = name; }
    void set_name(std::string&& name) noexcept { name_ = std::move(name); }
};
```

上述所述的是针对当 `set_name` 作为成员函数时的场景，当 `std::string` 为作为构造函数的形参时就不存在该问题，因为在构造过程中成员变量不存在已经分配的存储，总是需要申请存储来存放源字符串，或接管源字符串的存储。

```.cpp
// GOOD：
// There is one place where this is a good idea: Constructors.
class employee {
    std::string name_;
    std::string addr_;
    std::string city_;
public:
    void employee(std::string name, std::string addr, std::string city)
        : name_{std::move(name)}, addr_{std::move(addr)}, city_{std::move(city)} {}
};
```

Move can be much slower than copy – always incurs a full copy, prevents reusing
buffers/state (e.g., for vectors & long strings, incurs memory allocation 100% of the time), **also problematic for noexcept**.

