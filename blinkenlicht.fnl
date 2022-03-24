(local {: Gtk
        : GtkLayerShell
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

(local found-icons {})

(fn load-icon [name]
  (if (= (name:sub 1 1) "/")
      ;; From a direct path
      (GdkPixbuf.Pixbuf.new_from_file_at_scale name HEIGHT -1 true)
      ;; From icon theme
      (Gtk.Image.new_from_pixbuf (find-icon-pixbuf name))))

(fn find-icon [name]
  (let [icon (. found-icons name)]
    (or icon
        (let [icon (load-icon name)]
          (tset found-icons name icon)
          icon))))

(fn update-button [button icon text]
  (match (button:get_child) it (button:remove it))
  (let [i (resolve icon)]
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
  (var last-update -1)
  (let [button (Gtk.Button { :relief  Gtk.ReliefStyle.NONE})
        update (fn [now]
                 (when (and interval (> now (+ last-update interval)))
                   (update-button button icon text)
                   (set last-update now)))]
    (update 0)
    {
     : interval
     : poll
     : button
     :update #(update $2)
     }))

(fn make-layer-shell [window layer exclusive? anchors]
  (let [s GtkLayerShell]
    (s.init_for_window window)
    (s.set_layer window (. {
                            :top GtkLayerShell.Layer.TOP
                            }
                           layer))
    (if exclusive? (s.auto_exclusive_zone_enable window))

    (each [edge margin (pairs anchors)]
      (let [edge (. {:top GtkLayerShell.Edge.TOP
                     :bottom GtkLayerShell.Edge.BOTTOM
                     :left GtkLayerShell.Edge.LEFT
                     :right GtkLayerShell.Edge.RIGHT}
                    edge)]
        (GtkLayerShell.set_margin window edge margin)
        (GtkLayerShell.set_anchor window edge 1)))))

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

;; we want to run each indicator's update function only when
;; more than `interval` ms has elapsed since it last ran


(fn run []
  (GLib.timeout_add
     0
     1000
     (fn []
       (let [now (/ (GLib.get_monotonic_time) 1000)]
         (each [_ bar (ipairs bars)]
           (each [_ indicator (ipairs bar.indicators)]
             (indicator:update now))))
       true))
  (each [_ b (ipairs bars)]
    (make-layer-shell b.window :top true
                      (collect [_ edge (ipairs b.anchor)]
                        edge 1))
    (b.window:show_all))
  (Gtk.main))

{
 : bar
 : indicator
 : run
 }
