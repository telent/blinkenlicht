# Blinkenlicht

Yet another "bar" program for wlroots-basd Wayland compositors, but
this one is written in [Fennel](https://fennel-lang.org/) and
therefore better than all the others because it is more niche.

More seriously: you might prefer this over another status bar program
if you want fine-grained control over what is shown in your bar and
you are happy to exert that control in a Lua-based Lisp language.

## Current status and usage

Not quite dogfood-ready yet, but fast approaching.

* bl.fnl is an example

* blinkenlicht.fnl is the module that parses `bar` and `indicator`
  forms and does all the UI

* also in bl.fnl but needs extracting to a home of its own, all the
  glue that looks up load average, wifi signal strength, time of day
  etc for indicators to use

Use the `default.nix` for guidance as to libraries and other setup
required - or just use it, of course.

    nix-shell
    lua $fennel bl.fnl


## Plan

* [X] use gtk-layer-shell to put it in a layer
* [X] update only at relevant intervals
* [X] cache icon pixbufs
* [ ] update image/label widget instead of destroying
* [ ] allow height customisation
* [ ] add some mechanism for indicators that wait for events instead of polling
* [ ] set poll interval based on indicators' requested intervals
* [ ] set indicator background colour (use css for this?)

```fennel

;; your status bar specification might look something like this

(bar
 {
  :anchor [:top :right]
  :orientation :horizontal
  :indicators
  [
   (indicator {
               :interval 200
               :icon #(if (> loadavg 2) "sad-face" "happy-face")
               })
   (let [f (io.open "/tmp/statuspipe" "r")]
     (indicator {
                 :poll [f]
                 :text #(f:read:sub 1 10)
                 }))
   (indicator {
               :interval 5000
               :text #(.. (disk-free-percent "/") "%")
               :on-click #(spawn "baobab")
               })
   (indicator {
               :interval 1000
               :text #(os.date "%X")
               })
   ]})
```
