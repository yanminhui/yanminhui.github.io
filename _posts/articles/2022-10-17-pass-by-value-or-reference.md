---

layout: post
title: '优先传引用代替传值'
subtitle: 'Prefer pass-by-reference to pass-by-value'
date: 2022-10-17
categories: [article]
tags: 'C++' 

---

<<[Effective C++](http://aleda.cn/books/Effective_C++.pdf)>> 条款20 指出除非另外指定，否则应该尽量以指向实际参数的引用来传递参数，代替直接传实参的副本。

那么，哪些是另外指定的呢？以下情况应该按值传递。

## 内置类型

内置类型由 C++ 语言标准指定，内置于编译器中，是不可分拆分的基本数据类型，相当小。

## 迭代器

除了标准库算法使用迭代器作为函数参数外，一般工作中罕见使用迭代器作为函数参数类型，往往根据业务需要直接使用指向容器的引用。

## 函数对象

函数对象（包括 lambda 函数）习惯上被设计为按值传递，其实践者有责任检查它们是否高效且不受切割问题的影响，如下：[for_each](https://cplusplus.com/reference/algorithm/for_each/)

```.cpp
template<class InputIterator, class Function>
  Function for_each(InputIterator first, InputIterator last, Function fn)
{
  while (first!=last) {
    fn (*first);
    ++first;
  }
  return fn;      // or, since C++11: return move(fn);
}
```

从 C++11 开始，可以考虑使用前向转发引用（`fowarding reference`），但应确保算法只调用函数对象一次，否则可能引入副作用，见 [How do correctly use a callable passed through forwarding reference?](https://stackoverflow.com/questions/55786775/how-do-correctly-use-a-callable-passed-through-forwarding-reference)

我们可以看到 STL 算法库通常会调用传入的谓词参数多次，所以使用拷贝，而像 `std::invoke` 只会调用可调用对象一次，所以使用前向转发引用。

_**错误做法：** 在工作中许多程序员忽略了这一点，往往将其按引用传递，如下：_

```.cpp
void do_for_each(const std::vector<int>& v, const std::function<void(int)>& func) {
    // ...
}
```

## string_view

C++17 引入了 `string_view`，Arthur O’Dwyer 写了一篇关于 `string_view` 应按值传递的博文：[Three reasons to pass std::string_view by value](https://quuxplusone.github.io/blog/2021/11/09/pass-string-view-by-value/)。

## weak_ptr

`weak_ptr` 被实现为类似原始指针，应以内置类型来对待，按值传递。如下：[Is it useful to pass std::weak_ptr to functions?](https://isocpp.org/blog/2018/12/quick-q-is-it-useful-to-pass-stdweak-ptr-to-functions)

```.cpp
struct PointerObserver {
    std::weak_ptr<int> held_pointer;
 
    void observe(std::weak_ptr<int> p) {
        held_pointer = std::move(p);
    }
 
    void report() const {
        if ( auto sp = held_pointer.lock() ) {
            std::cout << "Pointer points to " << *sp << "\n";
        } else {
            std::cout << "Pointer has expired.\n";
        }
    }
};
```

_**错误做法：** 在工作中有时我们需要在内层类中引用外部类，使用 `weak_ptr` 来打破循环引用，然而许多程序员将函数参数声明为 `shared_ptr` 来初始化 `weak_ptr`，个人建议应声明为 `weak_ptr` 以明确函数语义。_

## 智能指针

Sutter’s Mill 写了一篇博文 [GotW #91 Solution: Smart Pointer Parameters](https://herbsutter.com/2013/06/05/gotw-91-solution-smart-pointer-parameters/) 指出如何将智能指针作为函数参数。应优先考虑传原始值的引用或裸指针，不要让智能指针作为函数参数，除非是操纵智能指针本身，比如共享或转移所有权。

在需要使用智能指针作为函数参数的情况下：
* 函数需要存储或共享堆对象，使用 `shared_ptr<T>`，比如作为线程函数参数。
* 为了修改智能指针本身，使用 `shared_ptr<T>&`，比如重新绑定新的对象。
* 不确定是否需要拷贝或共享所有权，使用 `const shared_ptr<T>&`。

当在构造函数中初始化 `shared_ptr` 成员变量时，应该考虑声明为 `shard_ptr<T>` 并使用移动语义，如下：

```.cpp
template <typename T>
struct PointerHolder {
    std::shared_ptr<T> pointer;

    explicit PointerHolder(std::shared_ptr<T> p)
        : pointer(std::move(p)) {} 
};
```

_**错误做法：** 在之前的工作中，一些同事可能受 [djinni](https://github.com/dropbox/djinni/blob/master/example/handwritten-src/cpp/sort_items_impl.cpp) 生成代码的影响，一律声明为 `const shared_ptr<T>&`，这不应受到鼓励。_

```.cpp
SortItemsImpl::SortItemsImpl(const std::shared_ptr<TextboxListener>& listener) {
    this->m_listener = listener;
}
```

_如上，`const shared_ptr<T>&` 产生了间接引用，实现中拷贝时增加一次引用计数，若改为如下，能够避免产生间接引用，并且仍保持拷贝时增加一次引用计数。_

```.cpp
SortItemsImpl::SortItemsImpl(std::shared_ptr<TextboxListener> listener) {
    this->m_listener = std::move(listener);
}
```
