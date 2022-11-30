---

layout: post
title: 'Google 基准测试'
subtitle: 'Google Benchmark'
date: 2022-11-30
categories: [article]
tags: '开发工具' 

---

[google benchmark](https://github.com/google/benchmark) 是一个类似于单元测试的，用于测试程序性能的 C++ 开发的基准测试框架。

## 基本用法

```.cpp
#include <benchmark/benchmark.h>

static void BM_StringCreation(benchmark::State& state) {
  for (auto _ : state) { // 基于 range-based for 循环
    std::string empty_string;
  }
  // 已迭代次数 必须在退出 for 循环后才能调用
  std::cout << "iterationed count: " << state.iterations() << std::endl;
}

// 把 BM_StringCreation 注册为基准测试
BENCHMARK(BM_StringCreation);

BENCHMARK_MAIN();
```

或

```.cpp
#include <benchmark/benchmark.h>

static void BM_StringCreation(benchmark::State& state) {
  while (state.KeepRunning()) { // 是否需要继续迭代?
    std::string empty_string;
    auto proccessedCount = 10;
    if (state.KeepRunningBatch(processedCount)) {
      // 让迭代器往前迭代 processedCount 次
    }
  }
  // 已迭代次数 必须在退出 for 循环后才能调用
  std::cout << "iterationed count: " << state.iterations() << std::endl;
}

// Iterations(n): 控制 for 循环多少次，而不是让 benchmark 来确定，这样 BM_StringCreation 就不会被执行多回以确定迭代次数。
// Repetitions(n): 控制 BM_StringCreation 应重复执行多少次。
BENCHMARK(BM_StringCreation)->Iterations(1024)->Repetitions(10);

BENCHMARK_MAIN();
```

benchmark 会运行 `BM_StringCreation` 多次来确定进行基准测试中 `for` 循环应当迭代多少次，以便更准确地计算出 `for` 内代码的性能。

## 自定义名称

```.cpp
static void BM_StringCreation(benchmark::State& state) {
  for (auto _ : state) {
    std::string empty_string;
  }
  state.SetLabel("<LABEL TEXT>"); // 为测试标记一个标签
}

BENCHMARK(BM_StringCreation)->Name("<BENCHMARK NAME>"); // 自定义名称
```

结果:

```.bash
-------------------------------------------------------------
Benchmark                   Time             CPU   Iterations
-------------------------------------------------------------
<BENCHMARK NAME>         11.5 ns         11.5 ns     55318476 <LABEL TEXT>
```

## 传递范围参数

```.cpp
static void BM_StringCreation(benchmark::State& state) {
  for (auto _ : state) {
    std::string str(state.range(0), '-'); // 获取 x->Arg(256) 传进来的参数
  }
}

BENCHMARK(BM_StringCreation)->Arg(256); // 传递参数给 BM_StringCreation
```

性能测试常常要覆盖不同的问题规模，为此一种机制来传递问题规模的参数，benchmark 针对此问题提供了一系列方法：

1. **Arg(n)** 通过 `state.range(0)` 获取 `n`
2. **Args(vector& args)** 通过 `state.range(index)` 获取对应 `args[index]` 的值
3. **RangeMultiplier(n)** 和 **Range(start, end)** 在 `[start, end]` 范围内以 `n` 倍数递增产生一系列 `Arg(start), Arg(start * n^1), Args(start * n^2) ... Args(end)`
4. **DenseRange(start, end, step)** 在 `[start, end]` 范围内以 `n` 步长递增产生一系列 `Arg(start), Arg(start + n*1), Args(start + n*2) ... Args(end)`
5. **Ranges(vector<pair<int64_t, int64_t>>& rngs)** 对 `rngs` 中的 `pair` 参数迪卡尔积产生一系列 `Args(v[0].first, v[1].first), Args(v[0].second, v[1].first), Args(v[0].second, v[1].second), Args(v[0].second, v[1].second)`
6. **ArgsProduct(vector\<vector\> & arglists)** 参数迪卡尔积
7. **Apply(void (*func)(Benchmark* benchmark))** 自定义生成

## 传递任意参数

```.cpp
template <class ...Args>
void BM_takes_args(benchmark::State& state, Args&&... args) {
  auto args_tuple = std::make_tuple(std::move(args)...);
  for (auto _ : state) {
    std::cout << std::get<0>(args_tuple) << ": " << std::get<1>(args_tuple)
              << '\n';
    [...]
  }
}

// Registers a benchmark named "BM_takes_args/int_string_test" that passes
// the specified values to `args`.
BENCHMARK_CAPTURE(BM_takes_args, int_string_test, 42, std::string("abc"));

// Registers the same benchmark "BM_takes_args/int_test" that passes
// the specified values to `args`.
BENCHMARK_CAPTURE(BM_takes_args, int_test, 42, 43);
```

## 计算渐进复杂度(Big O)

```.cpp
static void BM_StringCreation(benchmark::State& state) {
  for (auto _ : state) {
    for (auto i = 0; i < state.range(0); ++i) {
      std::string empty_string;
    }
  }
  state.SetComplexityN(state.range(0)); // 设置问题规模
}

BENCHMARK(BM_StringCreation)->Arg(1<<10)->Complexity(); // 计算复杂度
```

## 自定义计数器

```.cpp
static void UserCountersExample1(benchmark::State& state) {
  double numFoos = 0;
  for (auto _ : state) {
    // ... count Foo
  }

  state.counters["Foo"] = Counter(numFoos, benchmark::Counter::kIsRate); // 自定义计数器的形式
  state.SetBytesProcessed(bytes); // 计数器便利函数
  state.SetItemsProcessed(items); // 计数器便利函数
}
```

## 多线程基准测试

```.cpp
static void BM_MultiThreaded(benchmark::State& state) {
  if (state.thread_index() == 0) {
    // Setup code here.
  }
  for (auto _ : state) {
    // Run the test as normal.
  }
  if (state.thread_index() == 0) {
    // Teardown code here.
  }
}
BENCHMARK(BM_MultiThreaded)->Threads(2);
```

多个线程同时运行 `BM_MultiThreaded`，并在 `for` 循环等待所有线程都到达相同位置后启动 `for` 循环。然后当有的线程还在执行，而有的已经执行完 `for` 时仍然要相互等待，一起退出 `for` 循环。

**注意：** _当参与测试的代码中含有代码自己的线程的情况下，统计的 CPU 时间是不准确的，用户线程运行的时间没有被包含在内。此时，可以考虑用另一种统计方法，使用 `MeasureProcessCPUTime()` 来统计此过程中整个进程所消耗的时间，这样用户线程运行的时间就被统计进来了。_

**注意：** _对自定义的计数器统计的数据，比如速率等需要用到的时间，默认情况下使用的是 CPU 时间，而当参与测试的代码中含有代码自己的线程的情况下，这个 CPU 时间是不准确，这个时候一般使用墙上时钟 `UseRealTime()` 来代替 CPU 时间。_

## 控制定时器

```.cpp
static void BM_ControllingTimer(benchmark::State& state) {
  for (auto _ : state) {
    state.PauseTiming(); // 停止计时
    // ... 此时不被计时
    state.ResumeTiming(); // 恢复计时
    // ... 此时被计时
  }
}
```

## 遇到错误退出

```.cpp
static void BM_test(benchmark::State& state) {
  while (state.KeepRunning()) {
    auto data = resource.read_data();
    if (!resource.good()) {
      state.SkipWithError("Failed to read data!"); // 遇到错误退出
      break; // Needed to skip the rest of the iteration.
    }
    do_stuff(data);
  }
}
```

## 阻止优化

```.cpp
static void BM_vector_push_back(benchmark::State& state) {
  for (auto _ : state) {
    std::vector<int> v;
    v.reserve(1);
    benchmark::DoNotOptimize(v.data()); // Allow v.data() to be clobbered.
    v.push_back(42);
    benchmark::ClobberMemory(); // Force 42 to be written to memory.
  }
}
```

`DoNotOptimize(<expr>)` forces the result of `<expr>` to be stored in either memory or a register.

`ClobberMemory()` forces the compiler to perform all pending writes to global memory.

## 其它

Fixture、Fixture 模板、Fixture 模板函数、定制时间单位、定制统计等相关内容见 [用户手册](https://github.com/google/benchmark/blob/main/docs/user_guide.md)。