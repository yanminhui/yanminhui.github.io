---

layout: post
title: 'Python-FacePP'
subtitle: 'Python-FacePP for Facial Recognition'
date: 2019-02-24
categories: 'github'
tags: ['GitHub仓库', 'Python']

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

