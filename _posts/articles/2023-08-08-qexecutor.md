---

layout: post
title: 'Qt: 子线程与UI线程的交互'
subtitle: 'Qt: 子线程与UI线程的交互'
date: 2023-08-08
categories: [article]
tags: ['QT', 'Multithreading'] 

---

在 Qt 中只允许 UI 线程操作界面组件，但我们的应用程序一般是多线程的，必然会涉及到 UI 线程与子线程的交互的问题。

Qt 中提供了一些线程安全的方法来来实现这个目的：

1. **信号槽** 在 [`QObject::connect`](https://doc.qt.io/qt-6/qobject.html#connect) 函数中，当 `ConnectionType` 为 `Qt::QueuedConnection` 时，槽函数将会在接收者的线程中执行。
2. **QMetaObject::invokeMethod** 每个 `QObject` 的对象都有关联一个线程对象，使用 [`invokeMethod`](https://doc.qt.io/qt-6/qmetaobject.html#invokeMethod) 调用将促使函数在这个关联的线程中执行。 
3. **QApplication::postEvent** 通过自定义事件触发 UI 线程执行特定的操作。

接下来，我将使用 `QMetaObject::invokeMethod` 实现一个更通用的操作，类似于线程池，可以把一个任务放到 UI 线程执行，而不必依赖 `QObject`。

```.cpp
#include <functional>

#include <QCoreApplication>
#include <QThread>

namespace detail {

struct QExecutorOperationImpl : QObject
{
    using fn_t = std::function<void()>;

    Q_OBJECT

public slots:
    void run(fn_t f)
    {
        f();
    }
};

} // namespace detail

template <class F, class... Args>
void qPost(F&& f, Args&&... args)
{
    static detail::QExecutorOperationImpl executor_op{};
    static auto _ = []() {
        auto app = qApp;
        Q_ASSERT(app);

        auto ui_thrd = app->thread();
        Q_ASSERT(ui_thrd);

        executor_op.moveToThread(ui_thrd);
        return 0;
    }(); // call once

    if constexpr (sizeof...(args) > 0) {
        auto op = std::bind(std::forward<F>(f), std::forward<Args>(args)...);
        QMetaObject::invokeMethod(&executor_op, "run",
                                  Q_ARG(detail::QExecutorOperationImpl::fn_t, std::move(op)));
    } else {
        QMetaObject::invokeMethod(&executor_op, "run",
                                  Q_ARG(detail::QExecutorOperationImpl::fn_t, std::forward<F>(f)));
    }
}
```

使用示例：

```.cpp
int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    std::thread thrd([](){
        Q_ASSERT(qApp->thread() != QThread::currentThread());
        qPost([](){
            Q_ASSERT(qApp->thread() == QThread::currentThread());
        });
    });

    QTimer::singleShot(1000, &a, SLOT(quit()));
    a.exec();
    thrd.join();
    return 0;
}
```

若考虑调用者已经是 UI 线程可原地执行，则可增加 `qDispatch` 函数：

```.cpp
template <class F, class... Args>
void qDispatch(F&& f, Args&&... args)
{
    auto app = qApp;
    if (app && QThread::currentThread() == app->thread()) {
        std::forward<F>(f)(std::forward<Args>(args)...);
        return ;
    }
    qPost(std::forward<F>(f), std::forward<Args>(args)...);
}
```