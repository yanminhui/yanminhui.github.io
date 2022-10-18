---

layout: post
title: '四人帮的 23 种设计模式'
subtitle: 'The 23 Gang of Four Design Patterns'
date: 2022-10-12
categories: [article]
tags: 'Design Patterns' 

---

## 设计原则

1. **开闭原则** 一个软件实体，如类、模块和函数应该对扩展开放，对修改关闭。
2. **里氏替换原则** 所有引用基类的地方必须能透明地使用其子类的对象。
3. **迪米特原则（最少知识原则）** 一个对象应该对其他对象有最少的了解。
4. **单一职责** 不要存在多于一个导致类变更的原因。
5. **接口分离** 客户端不应该依赖它不需要的接口；类间的依赖关系应该建立在最小的接口上。
6. **依赖倒置** 高层模块(稳定)不应该依赖于低层模块(变化)，二者都应该依赖于抽象(稳定)。抽象(稳定)不应该依赖于实现细节(变化)，实现细节应该依赖于抽象(稳定)。
7. **组合/聚合复用** 尽量采用组合(contains-a)、聚合(has-a)的方式而不是继承(is-a)的关系来达到软件的复用目的。

## 23 种设计模式

### 创建型模式

创建型模式抽象了实例化过程。一个 **类创建型模式** 使用继承改变被实例化的类，而一个 **对象创建型模式** 将实例化委托给另一个对象。

1. **抽象工厂** 提供一个创建一系列相关或相互依赖对象的接口，而无需指定它们的具体类。
2. **生成器** 将复杂对象的构造与其表示分离，以便相同的构造过程可以创建不同的表示。
3. **工厂方法** 定义一个用于创建对象的接口，但让子类决定要实例化哪个类。工厂方法允许类将实例化推迟到子类。
4. **原型** 使用原型实例指定要创建的对象的种类，并通过复制此原型来创建新对象。
5. **单例** 确保一个类只有一个实例，并提供一个全局访问点。

### 结构型模式

结构型模式涉及到如何组合类和对象以获得更大的结构。 **结构型类模式** 采用继承机制来组合接口或实现，而 **结构型对象模式** 描述了对一些对象进行组合。

1. **适配器** 将一个类的接口转换为客户期望的另一个接口。Adapter 让那些因为接口不兼容而无法协同工作的类可以一起工作。
2. **桥接** 将抽象与其实现分离，以便两者可以独立变化。
3. **组合** 将对象组合成树结构以表示“部分-整体“的层次结构。Composite 让客户可以统一处理单个对象和对象的组合。
4. **装饰器** 动态地给一个对象添加一些额外的职责。装饰器为扩展功能提供了一种灵活的替代子类的方法。
5. **外观** 为系统中的一组接口提供统一的接口。Façade 定义了一个更高级别的接口，使子系统更易于使用。
6. **享元** 使用共享有效地支持大量细粒度对象。享元是可以同时在多个上下文中使用的共享对象。享元在每个上下文中充当独立对象，它与未共享的对象实例无法区分。
7. **代理** 为其它对象提供一种代理以控制对这个对象的访问。

### 行为模式

行为模式涉及到算法和对象职责的分配。 **行为类模式** 使用继承机制在类间分派行为，而 **行为对象模式** 使用对象复合而不是继承。

1. **责任链** 使多个对象都有机会处理请求，从而避免将请求的发送者与其接收者之间的耦合关系。将这些对象连成一条链，并沿着这条链传递传递该请求，直到有一个对象处理它为止。
2. **命令** 将请求封装为对象，从而使你可用不同的请求对客户进行参数化；对请求排队或记录请求日志，以及支持可撤消的操作。
3. **解释器** 给定一种语言，定义其语法的表示，并定义一个解释器并使用该表示来解释该语言中的句子。
4. **迭代器** 提供一种在不暴露其底层表示的情况下按顺序访问聚合对象的元素的方法。
5. **中介者** 用一个中介对象来封装一系列的对象交互。中介者使各对象不需要显示地相互引用，从而使其耦合松散，而且可以独立地改变它们之间的交互。
6. **备忘录** 在不破坏封装的情况下，捕获一个对象的内部状态，并在该对象之外保存这个状态，以便以后可以将对象恢复到原先保存的状态。
7. **观察者** 定义对象之间的一对多依赖关系，这样当一个对象改变状态时，它的所有依赖项都会得到通知并自动更新。
8. **状态** 允许对象在其内部状态发生变化时改变其行为。对象看起来似乎修改了它的类。
9.  **策略** 定义一系列算法，封装每个算法，并使它们可互换。策略模式使算法可独立于使用它的客户而变化。
10. **模板方法** 在操作中定义算法的骨架，将一些步骤推迟到子类。模板方法让子类在不改变算法结构的情况下重新定义算法的某些步骤。
11. **访客者** 表示一个作用于某对象结构中的各元素操作。Visitor 允许您定义一个新的操作，而无需更改它所操作的元素的类。