# Blinkenlicht

Yet another "bar" program for wlroots-basd Wayland compositors, but
this one is written in [Fennel](https://fennel-lang.org/) and
therefore better than all the others because it is more niche.

More seriously: you might prefer this over another status bar program
if you want fine-grained control over what is shown in your bar and
you are happy to exert that control in a Lua-based Lisp language.

```fennel
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
