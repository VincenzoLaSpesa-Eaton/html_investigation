# Preliminary Investigation on a library to be used for rendering html pages with XV303 and XV102 

Galileo 10.x supported the displaying of simple HTML pages embedded in a Galileo application on the device XV-300 (Windows Embedded Compact 7).
This control is called “HTML Viewer”. It supported only displaying of simple HTML pages and was not intended to be a full-featured browser. The main purpose of this control was to display help pages and/or manuals.
Here we compare 3 different framework that can be used for rendering html

## RmlUI

https://github.com/mikke89/RmlUi

The project seems active, and it can be compiled easily using our toolchain.

### XV303
It compiles on xv303 X11+OpenGL2 as backend.

the compiled library is 60Mb, the heaviest benchmark runs at 5fps ( it could probably be a little better with no x11 in between )

### XV102
on xv102 we have to use SDL as backend. The compilation with SDL requires the packages SDL2_image::SDL2_image that we currently not have in our sdk or in the galileo externals

## LiteHtml

[litehtml/litehtml: Fast and lightweight HTML/CSS rendering engine](https://github.com/litehtml/litehtml)

The project seems active, even if it relies on gumbo-parser for the html parsing and the project is not maintained anymore ([google/gumbo-parser: An HTML5 parsing library in pure C99](https://github.com/google/gumbo-parser)) since 2023.
The project comes with no complete backend, there is some adapter for using pango and cairo for rendering the objects. Both pango and cairo are included in our sdk.

It is easy to compile since everything is already in the sdk. The compiled library ( with no backend) is 67Mb big.

The library expects us to write an implementation of [document_container](https://github.com/litehtml/litehtml/wiki/document_container "https://github.com/litehtml/litehtml/wiki/document_container") that can draw the primitives on our backend. The procedure is documented here [How to use litehtml · litehtml/litehtml Wiki](https://github.com/litehtml/litehtml/wiki/How-to-use-litehtml "https://github.com/litehtml/litehtml/wiki/How-to-use-litehtml")

We need to write an implementation for SDL, but the documentation is not clear on how to.
A full implementation is provided with gtk+ as backend but it is not possible to compile on the devices as it requires a lot of dependencies from the gnome project. 


# Google Webkit

Actively maintained, seems very promising.
There is a version of it specifically targeted for embedded devices: [WPE – WebKit](https://trac.webkit.org/wiki/WPE)

I was not able to build it for any platform ( including a standard linux).
The compilation toolchain is created by putting the sdk in many flatpacks. After downloading more than 40GB of libraries the compilation failed on my wsl.

They have another building infrastructure that uses Yocto [Igalia/meta-webkit: Yocto / OpenEmbedded layer for WebKit based engines and browsers](https://github.com/Igalia/meta-webkit)



