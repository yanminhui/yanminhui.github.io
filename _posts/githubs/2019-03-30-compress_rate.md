---

layout: post
title: 'Misc: compress_rate'
subtitle: '测算压缩率'
date: 2019-03-30
categories: ['github', 'article']
tags: ['GitHub仓库', 'Python']

---

[Measure compression rate](https://github.com/yanminhui/misc/blob/master/py/compress_rate.py). `zlib`, `gzip`, `bz2`, `lzma` is supported.

## Useage

```console
usage: compress_rate.py [-h] [--verbose]
                        [--chunk-size {4,8,16,32,64,128,256,512}]
                        [--name {all,zlib,gzip,bz2,lzma}]
                        [--level {-2,-1,0,1,2,3,4,5,6,7,8,9}]
                        file

Measure compression rate.

positional arguments:
  file                  file or directory

optional arguments:
  -h, --help            show this help message and exit
  --verbose             print progress status (default: None)
  --chunk-size {4,8,16,32,64,128,256,512}
                        data chunk's size (metric: KB) (default: 16)
  --name {all,zlib,gzip,bz2,lzma}
                        compression algorithm's name (default: all)
  --level {-2,-1,0,1,2,3,4,5,6,7,8,9}
                        controlling the level of compression, all = -2,
                        default = -1 (default: -2)
```

## Example

```console
$ python3 compress_rate.py --level=-1 --verbose /usr/local/
File: /usr/local/, Length: 525.48 MB, Chunk Size: 16.0 KB
NAME  LEVEL OUTSIZE    EXPIRED    %RATE SPEED        MULTI %PROG REMAIN
 zlib     -1 170.54 MB  42.71 secs 67.55 12.3 MBps     3.08 100.0 0.0 secs
 gzip      9 170.93 MB  57.98 secs 67.47 9.06 MBps     3.07 100.0 0.0 secs
 bz2       9 132.79 MB  1.32 mins  74.73 6.65 MBps     3.96 100.0 0.0 secs
 lzma      0 101.92 MB  8.07 mins   80.6 1.09 MBps     5.16 100.0 0.0 secs
```

