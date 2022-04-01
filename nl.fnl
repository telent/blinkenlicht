(local nl (require :netlink))
(local view (. (require :fennel) :view))
(print (string.format "All known netlink groups: %s"
                      (table.concat (nl.groups) ", ")))
(local nls (nl.socket))
(print "File descriptor:" (nls:fd))

;; (local links
;;        (collect
;;            [_ l (ipairs  (nls:query {:link true}))]
;;          l.name l))
;; (print (view links))

;; ;; (local routes (nls:query {:route true}))
;; ;; (print "Query route status:" (view routes))

;; (print :routes (view (nls:query {:route true})))
;; (print :route6 (view (nls:query {:route6 true})))

;; ;; (each [_ entry (pairs routes)]
;; ;;   (local eth (nl.ethtool entry.name))
;; ;;   (when eth.speed
;; ;;     (print "ETH:" entry.name (view eth))))
;; (print "GROUPS:" (view (nls:groups)))

;; when we have a default route, we get the ifname

;; $ grep DEVTYPE /sys/class/net/*/uevent
;; /sys/class/net/docker0/uevent:DEVTYPE=bridge
;; /sys/class/net/wlp4s0/uevent:DEVTYPE=wlan
;; /sys/class/net/wwp0s20f0u2i12/uevent:DEVTYPE=wwan
;; (ethernet and loopback devices don't have DEVTYPE)

;; if the type is wlan, we can get a signal strength indicator
;; from the  "quality - link" column of /proc/net/wireless
;; and network name from `iwgetid wlan0 --raw`
;; or directly using an ioctl http://papermint-designs.com/dmo-blog/2016-08-how-to-get-the-essid-of-the-wifi-network-you-are-connected-to-#

;; for wwan, need to determine how to get strength and carrier name

(fn find [predicate tbl]
  (accumulate [found nil
               _ el (ipairs tbl)]
              (if (predicate el) el found)))

(print (find #(= $1 "hey") [:one :two :hey :three]))

(fn netlunk []
  (let [links {}
        routes {}]
    (fn handle-event [event]
;      (print :event (view event))
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
     :interface (fn [self ifnum] (print :lookup ifnum (view links)) (. links ifnum))
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
