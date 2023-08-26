---

layout: post
title: 'HTTP Proxy vs. HTTPS Proxy vs. SOCKS Proxy'
subtitle: 'HTTP Proxy vs. HTTPS Proxy vs. SOCKS Proxy'
date: 2023-08-26
categories: [article]
tags: ['Chromium'] 

---

## HTTP PROXY

```txt
browser                    http proxy                   http server
   |                           |                            |    
   | --------- TCP ----------> |                            |
   | <------------------------ |                            |
   | ------ HTTP GET --------> | ---------- TCP ----------> |
   |                           | <------------------------- |
   |                           | -------  HTTP GET -------> |
   | <-------- HTTP ---------- | <--------- HTTP ---------- |
```

```txt
browser                    http proxy                  httpS server
   |                           |                            |    
   | --------- TCP ----------> |                            |
   | <------------------------ |                            |
   | ----- HTTP CONNECT -----> | ---------- TCP ----------> |
   | <------------------------ | <------------------------- |
   | --------- SSL ----------> | ---------- SSL ----------> |
   | <------------------------ | <------------------------- |      
   | --------- HTTP ---------> | ---------- HTTP ---------> |
```

## HTTPS PROXY

```txt
browser                   httpS proxy                   http server
   |                           |                            |    
   | --------- SSL ----------> |                            |
   | <------------------------ |                            |
   | ------ HTTP GET --------> | ---------- TCP ----------> |
   |                           | <------------------------- |
   |                           | -------  HTTP GET -------> |
   | <-------- HTTP ---------- | <--------- HTTP ---------- |
```

```txt
browser                   httpS proxy                  httpS server
   |                           |                            |    
   | --------- SSL ----------> |                            |
   | <------------------------ |                            |
   | ----- HTTP CONNECT -----> | ---------- TCP ----------> |
   | <------------------------ | <------------------------- |
   | --------- SSL ----------> | ---------- SSL ----------> |
   | <------------------------ | <------------------------- |      
   | --------- HTTP ---------> | ---------- HTTP ---------> |
```

## SOCKS PROXY

```txt
browser                   socks proxy                 http/S server
   |                           |                            |    
   | -------- SOCKS ---------> |                            |
   | <------------------------ |                            |
   | ------- CONNECT --------> | ---------- TCP ----------> |
   | <------------------------ | <------------------------- |
   | ------ HTTP/S GET ------> | ------- HTTP/S GET ------> |
   | <------- HTTP/S --------- | <-------- HTTP/S --------- |
```

## 比较

* 安全：HTTPS Proxy > HTTP/SOCKS Proxy
* 功能：SOCKS Proxy > HTTP/HTTPS Proxy
* 性能：HTTP Proxy > SOCKS Proxy > HTTPS Proxy

一般而言，首先 HTTPS Proxy，防止代理用户名/密码泄露。