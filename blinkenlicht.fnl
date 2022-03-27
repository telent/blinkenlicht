(local {: Gtk
        : GtkLayerShell
        : Gdk
        : GdkPixbuf
        : GLib
        : cairo } (require :lgi))

(local posix (require :posix))

(local {: view} (require :fennel))

(local icon-theme (Gtk.IconTheme.get_default))

(local HEIGHT 48)

(fn load-styles [pathname]
  (let [style-provider (Gtk.CssProvider)
        (success err) (style-provider:load_from_path pathname)]
    (if success
        (Gtk.StyleContext.add_provider_for_screen
         (Gdk.Screen.get_default)
         style-provider
         Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
        (print "failed to load stylesheet" err))))

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
  (let [pixbuf
        (if (= (name:sub 1 1) "/")
            ;; From a direct path
            (GdkPixbuf.Pixbuf.new_from_file_at_scale name HEIGHT -1 true)
            ;; From icon theme
            (find-icon-pixbuf name))]
    (Gtk.Image.new_from_pixbuf pixbuf)))

(fn find-icon [name]
  (let [icon (. found-icons name)]
    (or icon
        (let [(icon err) (load-icon name)]
          (if (not icon) (print err))
          (tset found-icons name icon)
          icon))))

(fn add-css-classes [widget classes]
  (let [context (widget:get_style_context)]
    (each [_ c (ipairs classes)]
      (context:add_class c))))

(fn clear-css-classes [widget]
  (let [context (widget:get_style_context)]
    (each [_ c (ipairs (context:list_classes))]
      (context:remove_class c))))

(fn indicator [{: wait-for
                : refresh
                : on-click}]
  (let [button (Gtk.EventBox { })]
    (fn update-indicator []
      (let [content (resolve refresh)]
        (when content
          (match (button:get_child) it (button:remove it))
          (match content
            {:icon icon} (button:add (find-icon icon))
            {:text text} (button:add (Gtk.Label {:label text})))
          (clear-css-classes button)
          (add-css-classes button ["indicator"])
          (match content
            {:classes classes} (add-css-classes button  classes))
          (button:show_all))))
    (update-indicator)

    {
     : button
     :update update-indicator
     :inputs (or wait-for.input [])
     :interval wait-for.interval
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

(fn bar [{ : anchor : orientation : indicators :  classes }]
  (let [window (Gtk.Window  {} )
        orientation (match orientation
                      :vertical Gtk.Orientation.VERTICAL
                      :horizontal Gtk.Orientation.HORIZONTAL)
        box (Gtk.Box { :orientation orientation})]
    (doto box
      (add-css-classes ["bar"])
      (add-css-classes (or classes [])))

    (table.insert bars { : window : anchor : indicators })
    (each [_ i (ipairs indicators)]
      (box:pack_start i.button false false 0))
    (window:add box)))

(fn gsource-for-file-input [file cb]
  (let [fd file.fileno]
    (doto (GLib.unix_fd_source_new fd  GLib.IOCondition.IN)
      (: :set_callback cb))))

(fn ready-to-update? [indicator now update-times]
  (if indicator.interval
      (> now (or (. update-times indicator) 0))))

(fn hcf [a b]
  (let [remainder (% a b)]
    (if (= remainder 0)
        b
        (hcf b remainder))))

(assert (= (hcf 198 360)  18))
(assert (= (hcf 10 15) 5))

(fn minimum-interval [intervals]
  (accumulate [min (. intervals 1)
               _ interval (ipairs intervals)]
              (hcf min interval)))

(assert (= (minimum-interval [ 350 1000 5000 ])  50))

(fn run []
  (var intervals [])
  (each [_ bar (ipairs bars)]
    (each [_ indicator (ipairs bar.indicators)]
      (if indicator.interval
          (table.insert intervals indicator.interval))
      (each [_ file (ipairs indicator.inputs)]
        (GLib.Source.attach
         (gsource-for-file-input
          file
          #(or (indicator:update) true))))))
  (let [update-times {}
        interval (minimum-interval intervals)]
    (when (< interval 100)
      (print (.. "required refresh interval is " interval "ms")))
    (GLib.timeout_add
     0
     (minimum-interval intervals)
     (fn []
       (let [now (/ (GLib.get_monotonic_time) 1000)]
         (each [_ bar (ipairs bars)]
           (each [_ indicator (ipairs bar.indicators)]
             (when (ready-to-update? indicator now update-times)
               (indicator:update)
               (tset update-times indicator (+ now indicator.interval))))))
       true)))
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
 :stylesheet load-styles
 }
