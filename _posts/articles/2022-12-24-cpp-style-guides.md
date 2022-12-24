---

layout: post
title: 'C++ 编码风格指南'
subtitle: 'C++ Style Guides'
date: 2022-12-24
categories: [article]
tags: 'StyleGuides' 

---

## 文件扩展名

[如果你的项目还没有遵从一种约定，那么应使用 `.cpp` 作为代码文件的扩展名和 `.h` 作为接口文件的扩展名。](http://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#Rl-file-suffix)

这是一种长期的习惯，但是一致性更重要，如果你的项目使用其它约定，遵守它。

这个约定反应了一种通用的使用模式：C和C++一起编译时，头文件与C共享，通常使用 `.h`，而且对所有的头文件以 `.h` 命名也比那些仅仅为了与C共享就用不同的扩展名来得容易（注：比如C++使用 `.hpp` 为了与C共享的部分就使用 `.h`）。而实现文件很少会与C共享，所以通常与 `.c` 文件区分开来，因此一般最好为所有的C++实现文件使用其他扩展名（比如：`.cpp`）。
 
并不要求特地命名为 `.h` 和 `.cpp` （只是默认推荐），其他的名称也被广泛使用。例如 `.hh`、`.C`、`.cxx`，使用这些名称也是一样的。

## 变量初始化

[初始化的最佳实践:](https://abseil.io/tips/88#best-practices-for-initialization)

* 对于字面值、容器内容、智能指针、结构体等直观内容，使用赋值语法法形式。

```.cpp
int x = 2;
std::string foo = "Hello World";
std::vector<int> v = {1, 2, 3};
std::unique_ptr<Matrix> matrix = NewMatrix(rows, cols);
MyStruct x = {true, 5.0};
MyProto copied_proto = original_proto;
```

* 当初始化时要执行一些逻辑而不是简单地把值组合起来时，使用传统的构造语法（带圆括号）。

```.cpp
Frobber frobber(size, &bazzer_to_duplicate);
std::vector<double> fifty_pies(50, 3.14);
```

* 当没办法使用上述选项时，使用统一初始化语法（带花括号）。

```.cpp
class Foo {
public:
  Foo(int a, int b, int c) : array_{a, b, c} {}

private:
  int array_[5];
  // Requires {}s because the constructor is marked explicit
  // and the type is non-copyable.
  EventManager em{EventManager::Options()};
};
```

## 隐藏友元

[隐藏友元不仅使编译速度更快，而且能够避免意外的隐式转换。](https://www.justsoftwaresolutions.co.uk/cplusplus/hidden-friends.html)

所谓的隐藏友元是指在类定义中定义为 `friend` 的自由函数（通常是运算符重载）内联，这样通过常规的符号查找就找不到此函数，但可以通过[参照依赖查找](https://en.cppreference.com/w/cpp/language/adl)发现它。

```.cpp
#include <iostream>
#include <string>

using namespace std::literals::string_literals;

struct X {
  X(int n) : _n{n} {}
  X(const std::string& s) : _n{std::stoi(s)} {}
  void print() const {
    std::cout << _n << std::endl;
  }
  int _n;

  // 隐藏友元 #1
  friend X operator*(const X& lhs, const X& rhs) {
    return lhs._n * rhs._n;
  }

  // 友元声明 #2
  // friend X operator*(const X& lhs, const X& rhs);
};

// 友元实现 #2
// X operator*(const X& lhs, const X& rhs) {
//   return lhs._n * rhs._n;
// }

int main() {
  // #1:
  // <source>:31:19: error: invalid operands to binary expression ('basic_string<char>' and 'basic_string<char>')
  // auto x = "2"s * "3"s;
  //          ~~~~ ^ ~~~~
  // #2: 输出 6，但两个字符串相乘这是个意外，不应该让它通过编译。
  auto x = "2"s * "3"s;
  x.print();
}
```
[link](http://coliru.stacked-crooked.com/a/0218511354bdf0a1)
