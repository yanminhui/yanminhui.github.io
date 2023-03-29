---

layout: post
title: '虚指针的内存布局'
subtitle: 'Memory Layout for Virtual Pointers'
date: 2023-03-29
categories: [article]
tags: 'C++' 

---

## 单继承

```.cpp
struct Top {
    virtual ~Top() = default;  // virtual destructor
    int a = 1;
};
struct Left : public Top {
    int b = 2;
};

struct Bottom : public Left {
    int c = 3;
};
```

sizeof(Bottom): 24  
vptr: 	      0xe3b2b0  

| variable |   address    |
| :------- | :----------: |
| top      | **0xe3b2b0** |
| top.a    |   0xe3b2b8   |
| left     |   0xe3b2b0   |
| left.b   |   0xe3b2bc   |
| bottom   |   0xe3b2b0   |
| bottom.c |   0xe3b2c0   |

```.cpp
struct Top {
    int a = 1;
};
struct Left : public Top {
    virtual ~Left() = default;  // virtual destructor
    int b = 2;
};

struct Bottom : public Left {
    int c = 3;
};
```
sizeof(Bottom): 24  
vptr: 	      0x20842b0  

| variable |    address    |
| :------- | :-----------: |
| top      | **0x20842b8** |
| top.a    |   0x20842b8   |
| left     |   0x20842b0   |
| left.b   |   0x20842bc   |
| bottom   |   0x20842b0   |
| bottom.c |   0x20842c0   |

由于 `Top` 没有虚函数，其地址指向 `Bottom` 所在分量，与 `Bottom` 对象的地址不同, 也无法执行 `dynamic_cast<Bottom*>(ptop)` 执行运算（source type is not polymorphic）。

> 注: `vptr` 仍被安插在最前面。

## 多继承

```.cpp
struct Left {
    int a = 1;
};

struct Right {
    int b = 2;
};

struct Bottom : public Left, public Right {
    int c = 3;
};
```

sizeof(Bottom): 12  
vptr: 	      0x1c592b0  

| variable |    address    |
| :------- | :-----------: |
| left     | **0x1c592b0** |
| left.a   |   0x1c592b0   |
| right    | **0x1c592b4** |
| right.b  |   0x1c592b4   |
| bottom   |   0x1c592b0   |
| bottom.c |   0x1c592b8   |

虽然 `Right` 可以与 `Bottom` 进行类型转换，并进行地址转换，但由于不是多态，无法使用 `dynamic_cast`。

```.cpp
struct Left {
    virtual ~Left() = default;  // virtual destructor
    int a = 1;
};

struct Right {
    virtual ~Right() = default;  // virtual destructor
    int b = 2;
};

struct Bottom : public Left, public Right {
    int c = 3;
};
```

sizeof(Bottom): 32  
vptr: 	      0x21e02b0  

| variable |    address    |
| :------- | :-----------: |
| left     | **0x21e02b0** |
| left.a   |   0x21e02b8   |
| right    | **0x21e02c0** |
| right.b  |   0x21e02c8   |
| bottom   |   0x21e02b0   |
| bottom.c |   0x21e02cc   |

`Left` 与 `Right` 具有不同的 `vptr`。`Right` 与 `Bottom` 进行类型转换时，将会进行地址转换，`Right` 不能与 `Left` 进行类型转换。

> 注：`Right` 的 `vptr` 在 `left.a` 之后。

## 虚基类

```.cpp
struct Top {
    virtual ~Top() = default;  // virtual destructor
    int a = 1;
};

struct Left : virtual public Top {
    int b = 2;
};

struct Right : virtual public Top {
    int c = 3;
};

struct Bottom : public Left, public Right {
    int d = 3;
};
```

sizeof(Bottom): 48  
vptr: 	      0x232d2b0  

| variable |    address    |
| :------- | :-----------: |
| left     | **0x232d2b0** |
| left.b   |   0x232d2b8   |
| right    | **0x232d2c0** |
| right.c  |   0x232d2c8   |
| bottom   |   0x232d2b0   |
| bottom.d |   0x232d2cc   |
| top      | **0x232d2d0** |
| top.a    |   0x232d2d8   |

如果 `Top` 没有虚函数，由于没有派生类的类型信息，将无法与派生类进行类型转换。

> [**A `static_cast` can never be used to cast from a virtual base, in which case you always need `daynamic_cast`.**](https://stackoverflow.com/questions/7484913/why-cant-static-cast-be-used-to-down-cast-when-virtual-inheritance-is-involved)

## 其它

### 指针的比较

```.cpp
Bottom* pbtm = new Bottom();
Left* pleft = pbtm;
if (pleft == pbtm) {  // equal to `if (pleft == static_cast<Left*>(pbtm))`
    // ...
}
delete pbtm;
```

### 转换为 void*

编译器必须保证一个指针转换为 void 类型的指针时指向对象的顶部，但必须使用 `dynamic_cast` 进行运算。

相应的，void 类型的指针只能转换到对象的地址，没有类型信息，无法使用 `dynamic_cast`。