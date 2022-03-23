(local {: Gtk
        : Gdk
        : GdkPixbuf
        : GLib
        : cairo } (require :lgi))

(local {: view} (require :fennel))

(local icon-theme (Gtk.IconTheme.get_default))

(local HEIGHT 48)

(fn resolve [f]
  (match (type f)
    "string" f
    "function" (f)))

(fn find-icon-pixbuf [name]
  (var found nil)
  (each [_ res (pairs [HEIGHT 128 64 48]) :until found]
    (let [pixbuf (icon-theme:load_icon
                  name res
                  (+ Gtk.IconLookupFlags.FORCE_SVG
                     Gtk.IconLookupFlags.USE_BUILTIN))]
      (when pixbuf
        (set found (pixbuf:scale_simple
                    HEIGHT (* pixbuf.width (/ HEIGHT pixbuf.height))
                    GdkPixbuf.InterpType.BILINEAR)))))
  found)

(fn find-icon [name]
  (if (= (name:sub 1 1) "/")
      ;; From a direct path
      (GdkPixbuf.Pixbuf.new_from_file_at_scale name HEIGHT -1 true)
      ;; From icon theme
      (Gtk.Image.new_from_pixbuf (find-icon-pixbuf name))))

(fn update-button [button icon text]
  (match (button:get_child) it (button:remove it))
  (let [i (resolve icon)]
    (print :update i (resolve text))
    (if i
        (button:add (find-icon i))
        (button:add (Gtk.Label {:label (resolve text)})))
    (button:show_all)
    ))

(fn indicator [{: interval
                : icon
                : poll
                : text
                : on-click}]
  (let [button
        (Gtk.Button { :relief  Gtk.ReliefStyle.NONE})
        update #(update-button button icon text)]
    (update)
    {
     : interval
     : poll
     : button
     : update
     }))

(local bars [])

(fn bar [{ : anchor : orientation : indicators }]
  (let [window (Gtk.Window  {} )
        orientation (match orientation
                      :vertical Gtk.Orientation.VERTICAL
                      :horizontal Gtk.Orientation.HORIZONTAL)
        box (Gtk.Box { :orientation orientation})]
    (table.insert bars { : window : anchor : indicators })
    (each [_ i (ipairs indicators)]
      (box:pack_start i.button false false 0))
    (window:add box)))

(fn run []
  (GLib.timeout_add
     0
     1000
     (fn []
       (print :update)
       (each [_ bar (ipairs bars)]
         (each [_ indicator (ipairs bar.indicators)]
           (indicator:update)))
       true))
  (each [_ b (ipairs bars)]
    (b.window:show_all))
  (Gtk.main))

{
 : bar
 : indicator
 : run
 }
