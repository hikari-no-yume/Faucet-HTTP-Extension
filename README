Faucet HTTP
===========

This is Faucet HTTP, a Game Maker extension by Andrea Faulds (ajf) which
implements a minimal subset of HTTP/1.1 and provides a simple and easy-to-use
API for making HTTP requests in Game Maker. It is written in GML and uses Medo's
[Faucet Networking extension](https://github.com/Medo42/Faucet-Networking-Extension).
It is distributed under the ISC license (as is Faucet Networking), which is
short and simple enough that I don't have to explain it, just read the LICENSE
file.

The primary advantage of Faucet HTTP is its simplicity and its integration with
Faucet Networking. Response bodies are returned as Faucet Networking buffers,
for example. Faucet HTTP is written in GML, not as a DLL, which means that you
can hopefully find bugs in my code more easily (`;)`), but also that it can use
native GML data types. For example response headers and request headers just use
a plain `ds_map`.

It was intially created, like Faucet Networking, for Gang Garrison 2.

Usage
-----

Faucet HTTP does not yet have full documentation. However, there are lengthy
comments at the top of each function's script defining the function, its
parameters, return value, and behaviour. Have a look in `faucet-http.gml`. You
can import that file into Game Maker as a set of scripts for easier reading.

Full documentation in future, perhaps? :D

As for using it in GM, download it along with Faucet Networking ([here]
(https://github.com/Medo42/Faucet-Networking-Extension/releases)), install it
and add it to your project. It relies on Faucet Networking, so installing that
first might be a good idea.

Download here: https://github.com/TazeTSchnitzel/Faucet-HTTP-Extension/releases

However, **DON'T USE v1.0**. The names of all API functions will change soon,
and this library isn't very polished yet. There is a lack of proper
documentation, too, so you will likely make mistakes when using it. v1.1 will be
better, hopefully ;)

Creating the .gex
-----------------

For this task you need the GM Extension Maker, which you can download from
http://www.yoyogames.com/make/extensions . Open the extension description file
(faucethttp.ged) in the main project directory. You'll have to adapt it to work
for you, so click on the faucet-http.gml file and switch to the "Misc" tab.
Change the "Original Name" to the pathname where the .gml file is located.

Now you should be able to build the extension (File->Build Package...)
