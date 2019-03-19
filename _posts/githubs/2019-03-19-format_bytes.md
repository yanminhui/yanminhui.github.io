---

layout: post
title: 'Misc: format_bytes'
subtitle: '格式化字节数演进过程'
date: 2019-02-19
categories: ['github', 'article']
tags: ['GitHub仓库', 'C++']

---

Given a byte count, converts it to human-readable format 
and returns a string consisting of a value and a units indicator.

Depending on the size of the value, the units part is bytes, 
KB (kibibytes), MB (mebibytes), GB (gibibytes), TB (tebibytes), 
or PB (pebibytes)...

## [Function Prototype](https://github.com/yanminhui/misc/blob/master/cpp/format_bytes.hpp)

```.cpp
template<typename CharT, typename ByteT>
CharT const* format_bytes(std::basic_string<CharT>& repr             // (1)
                        , ByteT const bytes
                        , std::size_t const decimal=2u
                        , std::size_t const reduced_unit=1024u);

template<typename CharT, typename ByteT, typename IndicatorT
       , typename = typename std::enable_if<!std::is_integral<IndicatorT>::value>::type>
CharT const* format_bytes(std::basic_string<CharT>& repr             // (2)
                        , ByteT const bytes
                        , IndicatorT&& indicator
                        , std::size_t const decimal=2u
                        , std::size_t const reduced_unit=1024u);

template<typename CharT, typename ByteT, typename InputIt>
CharT const* format_bytes(std::basic_string<CharT>& repr             // (3)
                        , ByteT const bytes
                        , InputIt first, InputIt last
                        , std::size_t const decimal=2u
                        , std::size_t const reduced_unit=1024u);

template<typename CharT, typename ByteT
       , typename InputIt, typename IndicatorT>
CharT const* format_bytes(std::basic_string<CharT>& repr             // (4)
                        , ByteT const bytes
                        , InputIt first, InputIt last
                        , IndicatorT&& indicator
                        , std::size_t const decimal=2u
                        , std::size_t const reduced_unit=1024u);
```

## Usage

```.cpp
using namespace ymh::misc;

std::string s;
std::cout << format_bytes(s, 18446640) << std::endl;
```

equal to:

```.cpp
std::wstring wcs;  // unicode
auto indicators = { "Bytes", "KB", "MB", "GB" };
format_bytes(s, 18446640
           , std::begin(indicators), std::end(indicators)
           , "MB", 2u, 1024u);
```

## Output

```.sh
17.60 MB
```

## 自问自答

- **原型需求如何演进**

  - 将字节数转换成易读形式字符串在界面上显示
    
    ```.cpp
    std::string format_bytes(std::size_t bytes);
    ```
    
  - **需求** 增加格式化小数精度和转换单位大小
  
    ```.cpp
    std::string format_bytes(std::size_t bytes
                           , std::size_t decimal=2u
                           , std::size_t reduced_unit=1024u);
    ```
  
  - **需求** 现在需要转换到某个单位

    ```.cpp
    std::string format_bytes(std::size_t bytes
                           , std::size_t decimal=2u
                           , std::size_t reduced_unit=1024u);
    std::string format_bytes(std::size_t bytes
                           , std::string const& indicator
                           , std::size_t decimal=2u
                           , std::size_t reduced_unit=1024u);
    ```
   
  - **BUG** 字节数溢出

    不同数据类型可支持范围、精度不同，指定哪个类型都可能导致调用实参类型被转换。
    使用模板来避免数据类型被转换。

    | 类型 | 字节数 | 最大范围 |
    |:---:|:---:|:---:|
    | `std::size_t` | 8 | 16 EB |
    | `unsigned long long` | 8 | 16 EB |
    | `double` | 8 |  1.5e+284 YB |
    | `long double` | 16 | 9.8e+4907 YB | 
    
    ```.cpp
    template<typename ByteT>
    std::string format_bytes(ByteT bytes
                           , std::size_t decimal=2u
                           , std::size_t reduced_unit=1024u);
    template<typename ByteT>
    std::string format_bytes(ByteT bytes
                           , std::string const& indicator
                           , std::size_t decimal=2u
                           , std::size_t reduced_unit=1024u);
    ```
   
  - **需求** 支持 Unicode
   
    有些模块的代码使用窄字符，有的使用宽字符，
    对于原来的形式使用者需要对编码进行转换。
    
    同样使用模板进行适配，无法对函数返回类型进行推断，将返回值转移到形参上，
    得以支持实参推断返回类型。同时，带来一个避端不再兼容原来的函数原型。
    
    想要解决兼容问题，给新的实现一个新的名字是一种方式（比如，`format_bytes_ex`），
    让原来的函数来调用，并使用 
    [函数属性](https://zh.cppreference.com/w/cpp/language/attributes/deprecated) 
    标记废除，由编译器来提示用户逐步调用新名字。
    
    ```.cpp
    template<typename CharT, typename ByteT>
    void format_bytes(std::basic_string<CharT>& repr
                    , ByteT bytes
                    , std::size_t decimal=2u
                    , std::size_t reduced_unit=1024u);
    template<typename CharT, typename ByteT>
    void format_bytes(std::basic_string<CharT>& repr
                    , ByteT bytes
                    , std::basic_string<CharT> const& indicator
                    , std::size_t decimal=2u
                    , std::size_t reduced_unit=1024u);
    ```
   
  - **优化** 使用框架字符串类型
  
    新的要求是可能应用使用 Qt 界面框架，统一使用 `QString` 表示字符串，
    现在的形式要求先用 `std::string` 去调用，再将结果转换到目标形式。
    
    ```.cpp
    auto bytes = 18446640;
    std::string repr;
    
    format_bytes(repr, bytes);
    QString qrepr(repr.c_str());
    ```
    
    优化一下，让函数也返回字符串指针，使用起来简洁一点。
    
    ```.cpp
    auto bytes = 18446640;
    std::string repr;
    
    QString qrepr = format_bytes(repr, bytes);
    ```
    
  - **BUG** 将字面量字符串传给 `indicator` 时报错
    
    ```.cpp
    auto bytes = 18446640;
    std::string repr;
    
    std::cout << format_bytes(repr, bytes, "MB") << std::endl;
    ```
  
    字面量字符串是个数组类型，无法直转换到 `std::string`，
    但是数组变量是可以的，它可以直到转换到指向数组元素的指针，
    这样就可以构造 `std::string`。
    
    C++11 诞生了右值引用，使用模板有一个特例是支持模板参数引用折叠，
    可以达到保持参数类型转发。
    
    结合以上两点，就给它声明为右值引用吧。
    
    ```.cpp
    template<typename CharT, typename ByteT, typename IndicatorT>
    void format_bytes(std::basic_string<CharT>& repr
                    , ByteT bytes
                    , IndicatorT&& indicator
                    , std::size_t decimal=2u
                    , std::size_t reduced_unit=1024u);
    ```
   
   - **BUG** 实例化第三个形参发生歧义
   
    修正前一个 BUG 的时候，潜在的引用入了一个新的 BUG，第三个形参是模板类型
    可能实例化为 `std::size_t`，这时重载的两个函数都是候选函数，为了使它们
    可以重载，使用 `std::enable_if` 对模板参数类型进行限定。
    
    ```.cpp
    template<typename CharT, typename ByteT, typename IndicatorT
           , typename = typename std::enable_if<!std::is_integral<IndicatorT>::value>::type>
    CharT const* format_bytes(std::basic_string<CharT>& repr
                            , ByteT const bytes
                            , IndicatorT&& indicator
                            , std::size_t const decimal=2u
                            , std::size_t const reduced_unit=1024u);
    ```
    
  - **需求** 软件在不同的场景下要使用不同的单位表示
  
    字节的表示有不同的标准和形式，比如：`17.50 MB`，`17.50 MiB` 等，为此，
    单位也要定制了，标准库的一般做法是传递一个前闭后开的递代器范围 [first, last)，
    也可以不这么做，未来也许 `range` 变得流行是一个更棒的方式。
    
    ```.cpp
    template<typename CharT, typename ByteT
           , typename InputIt, typename IndicatorT>
    CharT const* format_bytes(std::basic_string<CharT>& repr
                            , ByteT const bytes
                            , InputIt first, InputIt last
                            , IndicatorT&& indicator
                            , std::size_t const decimal=2u
                            , std::size_t const reduced_unit=1024u);
    ```
