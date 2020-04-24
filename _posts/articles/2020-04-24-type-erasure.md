---

layout: post
title: 'C++ 类型擦除'
subtitle: 'any_iterator'
date: 2020-04-24
categories: [article]
tags: '摘录文章' 

---

在面向用户开发 SDK 应用时，我们期望使接口尽可能简单，暴露的类型尽可能的少，便于用户使用，后期的维护。

- `boost.any` 提供了变量的抽象
- `std.function` 提供了可调用物的抽象
- `any_iterator` 提供了迭代器的抽象
- `any_range` 基于 `any_iterator` 提供了范围抽象

## any_iterator

- [On the Tension Between Object-Oriented and Generic Programming in C++](https://www.artima.com/cppsource/type_erasure.html)
- [Type Erasure for C++ Iterators](http://thbecker.net/free_software_utilities/type_erasure_for_cpp_iterators/any_iterator.html)

注：对标准库的迭代器的重新分类是必备的，详见 [boost.iterator](https://www.boost.org/doc/libs/1_72_0/libs/iterator/doc/index.html)。

## any_range

`range-v3` 基于可迭代对象，在使用迭代器对容器与算法之间进行桥接之后，提供间接层，使得算法的接口更加统一。同时，支持延迟计算、流水线操作。

- [Eric Niebler](http://ericniebler.com)
- [range-v3](https://github.com/ericniebler/range-v3)
