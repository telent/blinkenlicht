(local nl (require :netlink))
(local view (. (require :fennel) :view))
(print (string.format "All known netlink groups: %s"
                      (table.concat (nl.groups) ", ")))
(local nls (nl.socket))

;; when we have a default route, we get the ifname

;; $ grep DEVTYPE /sys/class/net/*/uevent
;; /sys/class/net/docker0/uevent:DEVTYPE=bridge
;; /sys/class/net/wlp4s0/uevent:DEVTYPE=wlan
;; /sys/class/net/wwp0s20f0u2i12/uevent:DEVTYPE=wwan
;; (ethernet and loopback devices don't have DEVTYPE)

;; if the type is wlan, we can get a signal strength indicator
;; from the  "quality - link" column of /proc/net/wireless

;; for wwan, need to determine how to get strength and carrier name



(fn netlunk []
  (let [links {}
        routes {}]
    (fn handle-event [event]
      (match event
        {:event :newlink}
        (match event.up
          "yes" (tset links event.index event)
          "no" (tset links event.index nil))

        {:event :newroute}
        (tset routes (or event.dst "default")
              (if (. links event.index)
                  event
                  nil))

        {} (print :unhandled event.event)
        ))
    (each [_ event (ipairs (nls:query ))]
      (handle-event event))

    {
     :refresh #(each [_ event (ipairs (nls:event))]
                 (handle-event event))
     :fd (nls:fd)
     :uplink (fn [self] routes.default)
     :wait #(nls:poll 1000)
     :interface (fn [self ifnum]  (. links ifnum))
     }
    ))

(let [nl (netlunk)]
  (while (or (nl:wait) true)
    (nl:refresh)
    (match (nl:uplink)
      {:index ifnum}
      (print "default route through " (. (nl:interface ifnum) :name))
      {}
      (print "no default route")
      )))



;; default route is newroute event without dst

;; look for newlink event with  :running "yes"
