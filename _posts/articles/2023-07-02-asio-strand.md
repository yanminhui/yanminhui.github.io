---

layout: post
title: 'ASIO 串行队列'
subtitle: 'ASIO Strand'
date: 2023-07-02
categories: [article]
tags: ['C++', 'ASIO', 'Multithreading', 'DesignPatterns'] 

---

## Naked Thread

一般情况下，通常我们使用传统的多线程编程模式，线程之间通常通过共享数据来进行信息交换和通信，使用 `mutex` 等机制对共享数据进行同步。然而，共享数据会引发许多问题，比如竞争条件、死锁等。另外，线程之间还需要相互等待对方完成某个操作，这样会导致整个应用程序的性能下降。

## Active Object

在之前的工作中，我们是基于 [Grand Central Dispatch](https://dirtmelon.github.io/Knowledge/iDev/Multithreading/Grand-Central-Dispatch.html) 进行并发编程的。在项目中存在有些同事写的类是不允许我们直接访问的，所有要访问这些类的代码，必须放到 Serial 线程执行。这其实是使用了 Active Object 的思想，只是没有对其类接口进行处理，需要调用者遵守约定。

[主动模式](https://www.slideshare.net/jeremiahdjordan/active-object-design-pattern)通过引入一个中间层（Active Object），将方法调用与执行隔离，由单独的执行线程执行。这样做可以避免线程直接对共享数据进行访问，从而避免了竞争条件和死锁等问题。同时，由于代码的执行是由单独的线程来完成的，所以不会阻塞调用线程，提高了应用的响应性和并发性能。

然而，当它使用独占线程时，可能导致执行线程一直空闲，无法被其它人使用。或者当它与其他对象共用一个 Serial 线程时，无法充分利用 CPU 的并发性。所以，最主要的特点是它能提升响应性，不会阻塞调用者的线程。

## ASIO Strand

Strand 事实上是 executor 的适配器，当我们使用 `executor.post()` 时，它可以并发执行，而 strand 在用户代码与 executor 之间强制顺序约束，但并不会强制 strand 在特定的线程中执行，可以与其它对象共享线程池来提升并发性。

那么它是怎么做的呢？

其实挺简单的，它就像一个代理。当用户提交一个任务过来，被加入到一个等待队列（waitting_queue），然后检查需要串行执行的任务是否在执行中，如果没有执行，它就触发执行。否则只需要加入到等待队列就可以，正在执行串行任务的 `strand_invoker` 执行完**一批**（注意这是一批）任务后，会检查是否还有任务需要执行，有的话继续触发执行 (`defer`)，否则就完成。

如此循环，strand 扮演了一个缓冲区的角色，把用户提交的任务先缓存起来，待前面的任务执行完后再执行。而且，这些任务是一批一批的作为一个任务集合放在 `executor` 中执行，这个过程通过 `strand_invoker` 来完成。

![Strand](https://www.plantuml.com/plantuml/svg/ZLJDRjD04BxlKunwQa6En3KoKJbmw04XyGBMOe_ZLPnTTxrEWlWHGbK5LQ1580vmoW72eO8S448AKH-6ECcDLy0RUrt74OLJTcU--NQ-RoRUZnMLAkc6XBWXZME8bQJSSsAKFUOYUKW002pe9We7uDnnreSyQB2i6uNNTCvdCbRaCIcAmNvaMNL2ajqJLrLhYqUk0rMYorp73sbRquN2xHIP-qA4EYIHUW-Ac8YSmmGJj4M4aYecU4j3-fGfnjjvxWgeOQi2QyrgKUPi03N9aSJUNr8S1zgCIXWQZLRjYIOaCPgBlPbhRTJQZSPMRHzf1m8HUgMjTxc30wQCfMLJl2SwA7LVvamAn9EYP7SlQvOBXI1PEr0WV4FMR1eC0KWdnw0jllGOvZzEbk-FvjDfUZ9QpSwNusdwV08LSt__71A0vT7tzEpLV7QnVFiPFFHHmchyAJrzdLTc5AkBizLe-ElfC_tEx4qUNxmOPy7qop1ZMNpujdWtAKS7Dy6dOOoGaHPA8JtzEfz-J8zVBiv7DNhDbDDZ1jHIZMqrc-pR0tGJ9MIhz16BYDCNidEPrwteY74xe18z9rBITfpAy3HkVJ2czmJp85z68NVtrjvlzW0xDtRqlkZVwcerzKNmTZxsAshCyE3UhOC3OBpotEP_VKkj1IQYspRAyzI_9PPArbrOrdyfs5PRYcf2bCG1A56k7Ho22f23J3WmNm_IR0GX-yWz_JNx0m00)
