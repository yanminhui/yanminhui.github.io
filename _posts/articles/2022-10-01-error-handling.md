---

layout: post
title: 'C++ 错误处理'
subtitle: 'C++ Error Handling'
date: 2022-10-01
categories: [article]
tags: 'C++' 

---

## C 标准库

当我们调用 C 函数时，一般会返回一个错误代码，如果想知道错误代码的含义，库一般也会提供一个检索错误字符串的函数 `strerror` 来获取错误描述。

这种方式麻烦的是，当我们基于其它库开发新的库时，库的错误代码与基础库的错误代码产生冲突，需要处理这种情况。

```.cpp
void perror_demo() {
  if (FILE* f = fopen("unexist.ent", "rb")) {
    fclose(f);
    return;
  }
  std::cerr << errno << ": " << strerror(errno) << std::endl;
}

// 2: No such file or directory
```

## C++ 异常机制

到了 C++ 时代，其语言提供了异常机制 `try...catch` 让调用者可以捕获异常，但是我们只能通过异常对象类型和 `what()` 获取错误描述，没有了错误代码。

在 C++ 中难免需要调用遗留的 C 代码库，这时难以将错误代码传递给调用者，只能定义一个异常类传递错误字符串。或者，在自定义的异常类中存储错误代码。

有很多 C++ 代码库并不使用异常，仍使用 C 标准库类似的方式返回错误代码，反而是在调用 C++ 标准库抛出异常时，将其映射到一个自定义的错误代码。

```.cpp
void except_demo() {
  std::ifstream f;
  f.exceptions(std::ifstream::failbit | std::ifstream::badbit);
  try {
    f.open("unexist.ent", std::ifstream::in | std::ifstream::binary);
    f.close();
  } catch (const std::exception& e) {
    std::cerr << e.what() << std::endl;
  }
}

// ios_base::clear: unspecified iostream_category error
```

## C++11 错误代码

自从 C++11 开始，C++ 标准库引入了 `boost.system_error`，在这个库里可以将错误分类 `error_category`，用户可以派生它实现自己的错误类别，在这个类里存储了错误类别的名字，以及错误代码和错误描述的映射。然后，调用者可以通过 `error_code` 访问其中的信息，也可以用异常机制来捕获 `system_error`。

用户可以通过错误类别区分是哪种类型或哪个模块产生的错误，只是需要库编写 `error_category` 来映射错误。

使用 [`system_error`](https://en.cppreference.com/w/cpp/header/system_error) 一般有两种形式，一种是通过类似 C 标准库的方式在函数原型中增加一个错误代码的参数来存储错误，一种是使用 C++ 的异常机制来捕获异常。

```.cpp
void return_error_code(std::error_code& ec) {
  ec = std::make_error_code(std::errc::no_such_file_or_directory);
}

void error_code_demo() {
  std::error_code ec;
  return_error_code(ec);
  if (ec) {
    std::cerr << ec.value() << ": " << ec.message() << std::endl;
  }
}

// 2: No such file or directory

void throw_system_error() {
  throw std::system_error(
      std::make_error_code(std::errc::no_such_file_or_directory));
}

void system_error_demo() {
  try {
    throw_system_error();
  } catch (const std::system_error& e) {
    std::cerr << e.code().value() << ": " << e.what() << std::endl;
  }
}

// 2: No such file or directory
```

## LEAF 轻量级错误处理增强框架

Boost 1.75 开始引入了 [LEAF](https://boostorg.github.io/leaf/)，我个人认为这个库牛逼的地方在于它利用了模板实现例化的特性，当你不需要获取具体错误时，你能够判断是否产生了错误，但它不会实例化错误对象。

LEAF 能够兼容处理各种错误，但你需要在 `try_handle_some/all` 等中定义一系列错误处理函数，这意味兼容性强了，但处理错误的地方变复杂了，因为你需要知道库里面是有哪些错误类型，不像 `errorno` 或 `error_code` 能够很简单一致性的访问错误。

```.cpp
boost::leaf::result<void> return_leaf_result() {
  return boost::leaf::new_error(
      std::make_error_code(std::errc::no_such_file_or_directory));
}

void leaf_result_demo() {
  [[maybe_unused]] auto r = boost::leaf::try_handle_some(
      return_leaf_result, [](const std::error_code& ec) {
        std::cerr << ec.value() << ": " << ec.message() << std::endl;
      });
}

// 2: No such file or directory

void throw_system_error() {
  throw std::system_error(
      std::make_error_code(std::errc::no_such_file_or_directory));
}

void leaf_except_demo() {
  boost::leaf::try_catch(throw_system_error, [](const std::system_error& e) {
    std::cerr << e.code().value() << ": " << e.what() << std::endl;
  });
}

// 2: No such file or directory
```

## 线程间的错误传递

我们知道，当我们在子线程中抛出异常时需要在子线程中处理，否则将导致程序崩溃。而当我们使用线程池时，往往希望在父线程中统一处理子线程的异常，C++11 引入 [`exception_ptr`](https://en.cppreference.com/w/cpp/error/exception_ptr) 使得我们可以将子线程中的异常转移出来统一处理。

```.cpp
void worker() {
  try {
    std::this_thread::sleep_for(std::chrono::seconds(1));
    throw std::runtime_error("To be passed between threads");
  } catch (...) {
    teptr = std::current_exception();
  }
}

int main() {
  std::thread thrd(worker);
  thrd.join();

  if (teptr) {
    try {
      std::rethrow_exception(teptr);
    } catch (const std::exception& ex) {
      std::cerr << "Thread exited with exception: " << ex.what() << "\n";
    }
  }
}
```