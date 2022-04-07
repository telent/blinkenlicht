(local { : GLib }  (require :lgi))
(local dbus (require :dbus_proxy))
(local { : view } (require :fennel))
(local GV GLib.Variant)
(local variant dbus.variant)

;; https://www.freedesktop.org/software/ModemManager/api/latest/ref-dbus.html

(fn  modem-manager []
  (dbus.Proxy:new
   {
    :bus dbus.Bus.SYSTEM
    :name "org.freedesktop.ModemManager1"
    :interface "org.freedesktop.DBus.ObjectManager"
    :path "/org/freedesktop/ModemManager1"
    }))

;; this is a function because the path to the modem may change
;; (e.g. due to suspend/resume cycles causing services to be stopped
;; and started)

(fn modem-interface [manager]
  (let [modem-path (next (: (assert manager) :GetManagedObjects))]
    (dbus.Proxy:new
     {
      :bus dbus.Bus.SYSTEM
      :name "org.freedesktop.ModemManager1"
      :interface "org.freedesktop.ModemManager1.Modem.Simple"
      :path modem-path
      })))

(fn new-modem-status []
  (let [manager (modem-manager)]
    {
     :read #(let [m (modem-interface manager)]
              (variant.strip (m:GetStatus)))
     }))

(comment
(let [ctx (: (GLib.MainLoop) :get_context)
      s (new-modem-status)]
  (while true
    (ctx:iteration)
    (print (view (s:value) )))))

{ :new new-modem-status }
