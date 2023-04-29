---

layout: post
title: 'Conan 2.0 打包开发流程'
subtitle: 'Conan 2.0 Package Development Flow'
date: 2023-04-29
categories: [article]
tags: '开发工具' 

---

![conanfile](https://www.plantuml.com/plantuml/svg/VP4nRiCm34LtdK90bsG8iZjBnewzWS7Qj4jOfbI9AbeKldiJouWRnWWdYU_purCw9u4eUNHcFfW0KKZ8isqy0n-QY21unE_Wenp2qDjVOo-bTU-PNBkmBKwS19oxAKfL5zXHN_jmbUxsfosQ8pwGY9-P8ex8aXxWdAL-Ala2Hoq8Qg1Z9vzZWslgrS71ZyzodTU8EhlxFtqiRxYtye5SrAfUNhsy4GzL6TWoHMwfk-jEznlro1ZLHfFHcPQFqf4seiowOgOJ5DigG3D0ZqMptclYpj-QWadgXPpCP9BuOCx8RHxT7m00)

| NAME               | WHAT TO DO                                                               |
| :----------------- | :----------------------------------------------------------------------- |
| config_options     | Configure options while computing dependency graph                       |
| configure          | Allows configuring settings and options while computing dependencies     |
| requirements       | Define the dependencies of the package                                   |
| build_requirements | Defines tool_requires and test_requires                                  |
| validate           | Define if the current package is invalid (cannot work) with the current  |
| layout             | Defines the relative project layout, source folders, build folders, etc. |
| source             | Define the dependencies of the package                                   |
| generate           | Generates the files that are necessary for building the package          |
| build              | Contains the build instructions to build a package from source           |
| package            | Copies files from build folder to the package folder.                    |
| package_info       | Provide information for consumers about libraries, folders, etc.         |
