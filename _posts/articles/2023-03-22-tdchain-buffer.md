---

layout: post
title: 'Telegram 链式缓冲区'
subtitle: 'Telegram Chain Buffer'
date: 2023-03-22
categories: [article]
tags: 'Telegram' 

---

当我们从网络中一段段的读取数据来组成完整的数据包，如果简单的使用类似 `std::string` 一直往上叠加数据时，将导致频繁的重复 `alloc -> copy -> free` 过程，Telegram 设计了一个[链式的缓冲区](https://github.com/tdlib/td/blob/master/tdutils/td/utils/buffer.h)来处理完整数据包的片段。

![ChainBuffer](https://www.plantuml.com/plantuml/svg/ZLJ1ZXen3BtFLqHxWbLPQTjhXLRRKm-jglRGGrL59l4maK869HxOjjf_BvDOmrW4BLm0sx6Vdv_zb0WY3JlVD8dYO4Wz3ssByJiSrRz6dJx9_KLDoWA1ph_drWrkNH0M35OtsU02VNYl8hRQ12encxxtgeEaZz4HnfdnU39618kHNmyXkMr0gqm7iLJ_zVYxUMqQuo4bzSCxWmnnfKmV4fNG-wJPo8Wy1Zszu_RaQsuvb_z6KMtoVv56jBeIpRusyvntZtVgVhLQvnyJboBauM5Tu4jCFpCd3EhBGB3nM1xi8-uXeXw_CTZ5CeSSUcV7nbiNTvEBWOrV9Ueo6oIzA_zr6WsSxdfPs5-hoXvHL72QUnASCblikKBN9CPF7RXGp5zxonCJCymjPEjvVW5Vve9BVuBHhOVjM5rchCvBp6OM_vam0lLnqetCXMS07O9bgGYmh73sP701qUgCK4ghRzk4915F22Hg2QE6l21Zt7c2kUBHKSUhoDETJP8jKWeHeIg4RB_G7Xl07Y0ON8ZEtacjMKoK7rLWcu7qoAXCC2cjmezOrce01ilkgaO4127JS5VB9pY_TPtbzdGkqFAjO0saFK8YGVRjYrbX5ryeWY6-lekbgcsmueDT5_vvomcSrxTiXw1PN8D-ebc-lnOkTfSzbx7vw5uqBm_my-0yhqbj5SGcCsidpvby9ltYEftdawTPZwcopaTJadz0GttyE4knLjJpoDy8AlKp-x9d5dY5okO9Wnrs_Zy0)

## BufferRaw

`BufferRaw` 是操作内存的原始对象，它会通过 `unique_ptr` 被持有，但不是只有一个对象持有，它能有一个可写的对象，可以有多个可读的对象来引用它。

`data_size_` 与我们平常使用标准库容器 [`capacity`](https://cplusplus.com/reference/string/basic_string/capacity/) 的语意是一样的，指示当前对象申请的存储空间大小，而 `begin_` 与 `end_` 指示当前写入数据的范围。

## ChainBufferWriter

当我们要写入数据时，可以使用 `ChainBufferWriter` 来操纵它，一般的操作是准备一块内存 `prepare_append`，然后将数据复制到这块内存上，然后再确认写入的数据量 `confirm_append`。

## ChainBufferReader

当我们要从其它线程中读取 `ChainBufferWriter` 写入的数据时，可以通过 `ChainBufferWriter::extract_reader` 来获取 `ChainBufferReader` 对象。

一般情况下，我们先通过 `sync_with_writer` 来与 `ChainBufferWriter` 同步，然后使用 `prepare_read` 来获取数据，再使用 `confirm_read` 来移除读过的数据。

## BufferBuilder

`ChainBufferWriter` 是一个前向的列表，以字符流的方式写入数据，而 `BufferBuilder` 提供了一种方式可在列表前插入数据的方式。