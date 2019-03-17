---

layout: post
title: 'Python-FacePP'
subtitle: 'Python-FacePP for Facial Recognition'
date: 2019-02-24
categories: 'GitHub仓库'
tags: ['GitHub仓库', 'Python']
locations: github

---

Python-FacePP is a library for communicating with a 
[Face++](https://www.faceplusplus.com)
facial recognition service. Face++ exposes some of it's data via 
[Web API](https://console.faceplusplus.com/documents/6329584) for which 
Python-FacePP provides a simple but powerful Pythonic API inspired by a 
well-known [Django ORM](https://docs.djangoproject.com/en/dev/topics/db/queries/):

[Example:](https://www.faceplusplus.com/scripts/demoScript/images/demo-pic6.jp)

```py
>>> from facepplib import FacePP

>>> facepp = FacePP(api_key='eFWami68yL25RPrSuG0oi0lFfYRle26L', 
...                 api_secret='Zf_obifstMlZTPmejoY1MHNKyioD_Jtz')
>>> image = facepp.image.get(image_url='https://www.faceplusplus.com/scripts/demoScript/images/demo-pic6.jpg', 
...                          return_attributes=['smiling', 'age'])

>>> image.image_id
'8g2nrvINBnpyFseprStfyA=='

>>> len(image.faces)
3

>>> image.faces
<facepplib.resultsets.ResourceSet object with Face resources>

>>> image.faces[0]
<facepplib.resources.Face "f149db9d57149d538f386d390d6d8c5e">

>>> image.faces[0].age['value']
32

>>> image.faces[0].smile
{'threshold': 50.0, 'value': 100.0}
```

*More example in* [__main__.py](https://github.com/yanminhui/python-facepp/blob/master/facepplib/__main__.py)

## Features

* Supports Python 2.7, 3.4 - 3.7
* Supports different request engines
* Extendable via custom resources and custom request engines
* Provides ORM-style Pythonic API
* And many more...

## Installation

The recommended way to install is from Python Package Index (PyPI) with 
[pip](http://www.pip-installer.org):

```sh
$ pip install python-facepp
```

Check **facepplib**:

```sh
$ python -m facepplib
```

## Contacts

If you have questions regarding the library, I would like to invite you to 
[open an issue at GitHub](https://github.com/yanminhui/python-facepp/issues/new). 
Opening an issue at GitHub allows other users and contributors to this library 
to collaborate.

## License

<img align="right" 
src="http://opensource.org/trademarks/opensource/OSI-Approved-License-100x137.png">

The class is licensed under the [MIT License](http://opensource.org/licenses/MIT):

Copyright &copy; 2018 [yanminhui](mailto:yanminhui163@163.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

