---

layout: post
title: 'ASIO 服务管理'
subtitle: 'ASIO Services Management'
date: 2023-07-01
categories: [article]
tags: ['C++', 'ASIO'] 

---

## 实践中遇到的问题

之前，我们开发的应用也是基于异步服务的，在应用中存在大量命名为 `xxx_service` 的单例让用户使用，至少存在两个问题：

* **大量的 `shared_ptr` 实例**: 过度的使用 `shared_ptr`，对性能也是一种影响，详见 [GotW #91 Solution: Smart Pointer Parameters](https://herbsutter.com/2013/06/05/gotw-91-solution-smart-pointer-parameters/)。

* **未能释放资源**: 由于单例是个静态存储对象，分散在各个地方，未能在收尾时释放资源。遇到会出现问题的 `xxx_service` 需要写入一个称为 `factory_service` 的工厂进行处理，导致在这个类源代码中引入大量 `#include "xxx_service.h"` 指令，在一定程度上引入了代码耦合。

## ASIO 的解决方案

我们开发的应用的模式看起来跟 ASIO 是非常相似的，都是基于异步服务进行交互的。

ASIO 引入了一个 `execution_context` 来统一管理各种 `xxx_service`，这个 `execution_context` 可以是单例（e.g. `system_executor_impl`），也可以是个在寄宿在 `main` 函数内的对象（e.g. `io_context`），这看起来跟一般 Qt 应用，需要一个 `QApplication` 是一样的。当应用退出前，便会虚构这个对象，值此之际便可以处理管理的所有服务。

我们之前使用的各个 `xxx_service` 单例，在 ASIO 中如何拿到实例呢？

ASIO 使用按需创建的方式来获取，使用 `use_service<T>()`，既可以按需创建服务实例并注册到 `execution_context`，也可以检索到寄宿在 `execution_context` 上服务。 

ASIO 服务管理的结构如下所示：

![execution_context](https://www.plantuml.com/plantuml/svg/ZL9DRvmm4BtxLumsKfIq8LAlcoYAr5CFlULkKJFRZ08sjSVRHUd-zwxDi1JMKdD1m_jWtiD-3bnxZbshqCOETiw_QToZPVMk07gFVUtnBesrFw5fCg_KDkgeb6dh422WtvF1h0Uu0ZoWYKpEQkCiuu6lGOQRsop9ZmhsZXe8hv4Rzzjg-Of8XBMEQJVe5EfcJWPugqHLsAM_JxDeUEXHazsvJucZHc1Pc44xgtyuroPe2ZRtlDW5KldpXy9UhGel_ucm3GRsRfZ9gMWNJ-yfLnuA5NRa0sj1Jg4lqzxVFy6Sgo3OVDc0gohOsCtqwIqaiYORpgSz1CPEZsxdDNLzU_uFxu5h9dCiggxXcptnDXroCU3ZdwegEgVT7ckJiFd67PNCetaj41zJXsTGmbw8yyqHJ1IZxrV4Y8_wQ-lCsntebmI--9euF2LBfjT1bXiNR-aSYYstuF4d1Pw25Moho5k80ITmKLPAheAKI-Jh8ug7VsowTsGvaNZeoGyFwZX6-d-3TNqn2Rv8lvG-esrYr_u5)

## 异构应用的问题

由于我们的库应用在不同的端上，既可以应用在服务端，也可以应用在客户端。这可能会遇到一个问题，比如定义的 `xxx_service` 在不同端上的行为是不同的，这时就会分化成 `xxx_service_for_client` 和 `xxx_serivice_for_server` 来实现各自的行为。

对于使用这个服务的其它 `other_service` 不应该察觉到该变化是最佳的，比如仍然使用 `use_service<xxx_service>` 来取得该服务。ASIO 使用了模板元编程最基本的方式 *Traits* 来解决该问题。

> *Traits*: class templates that have a nested type alias called (by convention) type.

```.cpp
template <class _Service>
struct service_void_type
{
  typedef void _Type;
};

template <class _Service, class = void>
struct service_key_type
{
  typedef _Service _Type;
};

template <class _Service>
struct service_key_type<_Service,
  typename service_void_type<typename _Service::key_type>::_Type>
{
  typedef typename _Service::key_type _Type;
};
```

这样，只需要在类内嵌入一个  `using key_type = xxx_service`, 以下形式得到结果都是一样的:

- `use_service<xxx_service>()`
- `use_service<xxx_service_for_client>()`，但是避免使用，以免误注册。
- `use_service<xxx_service_for_server>()`，但是避免使用，以免误注册。

`other_service` 不需要做任何变化，依然使用 `use_service<xxx_service>()` 来获取服务，但是有一点需要注意的是要确保在 `other_service` 之前注册 `xxx_service`，那怎么做呢：

- 让 `xxx_service` 成虚基类，使得无法被实例化，这样在 `other_service` 就不会误注册 `xxx_service`。
- 在 `other_service` 之前注册 `xxx_service`，比如在 `execution_context` 的初始化过程中，而且应当使用 `make_service<T>()` 来代替 `use_service<T>()`，因为它会检测自己是否是第一个注册 `xxx_service` 的地方，如果不是将抛出异常，说明程序硬逻辑错误。

所以，在这种情况下，不应让用户知道 `xxx_service_for_client` 或 `xxx_service_for_server` 的存在，这个工作由实现者来处理，比如把它放到私有命名空间内，让用户意识到不能直接使用这些类。

