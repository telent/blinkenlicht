# Blinkenlicht

Yet another "bar" program for wlroots-basd Wayland compositors, but
this one is written in [Fennel](https://fennel-lang.org/) and
therefore better than all the others because it is more niche.

More seriously: you might prefer this over another status bar program
if you want fine-grained control over what is shown in your bar and
you are happy to exert that control in a Lua-based Lisp language.

## Current status and usage

Not quite dogfood-ready yet, but fast approaching.

* bl.fnl is an example, using licht.css for its styling

* blinkenlicht.fnl is the module that parses `bar` and `indicator`
  forms and does all the UI

* metric.fnl is a collection of functions that read metrics (load
  average, battery status etc) from the system, for indicators to
  display.

Use the `default.nix` for guidance as to libraries and other setup
required - or just use it, of course.

    nix-shell
    lua $fennel bl.fnl

The funny symbols in bl.fnl are code points that exist only in the
"Font Awesome" font, and render to handy icons like "battery, half
empty".  You need to install Font Awesome to see them; however due to
the Gtk font fallback system - at least, that's what I think is doing
it - you don't actually need to specify that font in your CSS because
Gtk will find it anyway. Magic.


## Plan

* [X] use gtk-layer-shell to put it in a layer
* [X] update only at relevant intervals
* [X] cache icon pixbufs
* [ ] update image/label widget instead of destroying
* [ ] allow height customisation
* [ ] add some mechanism for indicators that wait for events instead of polling
* [ ] set poll interval based on indicators' requested intervals
* [X] set indicator background colour (use css for this?)
* [ ] allow indicator to change styles based on status
