Faucet HTTP
===========

This is Faucet HTTP, a set of GML scripts by Andrea Faulds (ajf) which
implements a minimal subset of HTTP/1.1 and provides a simple and easy-to-use
API for making HTTP requests in Game Maker 8.0. It uses MedO's
[Faucet Networking extension](https://github.com/Medo42/Faucet-Networking-Extension).
It is distributed under the ISC license (as is Faucet Networking), which is
short and simple enough that I don't have to explain it, just read the LICENSE
file.

The primary advantage of Faucet HTTP is its simplicity and its integration with
Faucet Networking. Response bodies are returned as Faucet Networking buffers,
for example. Faucet HTTP is written in GML, not as a DLL, which means that you
can hopefully find bugs in my code more easily ;), but also that it can use
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
(https://github.com/Medo42/Faucet-Networking-Extension/releases)), make sure you
install Faucet Networking first, then go to Scripts->Import Scripts... and
choose the faucet-http.gml file.

Can be downloaded here:
https://github.com/TazeTSchnitzel/Faucet-HTTP-Extension/releases

Version 1.0 should be largely stable.

Editing
-------

Import the scripts into a GM game and add the Faucet Networking extension. Edit
to your heart's content, then right-click the faucet-http folder in Scripts and
choose "Export Group of Scripts..." to save back to the faucet-http.gml file.
