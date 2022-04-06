(local nl (require :netlink))
(local view (. (require :fennel) :view))

;; $ grep DEVTYPE /sys/class/net/*/uevent
;; /sys/class/net/docker0/uevent:DEVTYPE=bridge
;; /sys/class/net/wlp4s0/uevent:DEVTYPE=wlan
;; /sys/class/net/wwp0s20f0u2i12/uevent:DEVTYPE=wwan
;; (ethernet and loopback devices don't have DEVTYPE)

(fn devtype [ifname]
  (with-open [f (io.open (.. "/sys/class/net/" ifname "/uevent") :r)]
    (accumulate [dtype nil
                 line #(f:read "*l")
                 :until dtype]
                (let [(name value) (line:match "([^=]+)=(.+)")]
                  (if (= name "DEVTYPE") value dtype)))))

;; if the type is wlan, we can get a signal strength indicator
;; from the  "quality - link" column of /proc/net/wireless

(fn wlan-link-quality [ifname]
  (with-open [f (io.open "/proc/net/wireless" :r)]
    (accumulate [strength nil
                 line #(f:read "*l")
                 :until strength]
                ;; "%6s: %04x  %3d%c  %3d%c  %3d%c  %6d %6d %6d "
                ;; "%6d %6d   %6d\n",
                ;; https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/net/wireless/wext-proc.c#n49

                (let [(name status link level)
                      (line:match "(.-): +(%x+) +(%S-)[ .] +(%S-)[ .]")]
                  (if (= name ifname)
                      (tonumber level)
                      strength)))))

(fn wlan-link-ssid [ifname]
  ;; could do this  directly using an ioctl
  ;; http://papermint-designs.com/dmo-blog/2016-08-how-to-get-the-essid-of-the-wifi-network-you-are-connected-to-#
  (with-open [f (io.popen (.. "iwgetid  " ifname " --raw") :r)]
    (f:read "*l")))

(fn get-network-info [event]
  ;; augments a newlink event with relevant information, if it's
  ;; sufficiently well-configured to have any

  ;; "up" => administratively up
  ;; "running" => can actually exchange packets
  (when (= event.running "yes")
    (let [dtype (devtype event.name)]
      (tset event :devtype dtype)
      (when (= dtype "wlan")
        (if (not event.ssid)
            (tset event :ssid (wlan-link-ssid event.name)))
        (tset event :quality (wlan-link-quality event.name)))
      (when (= dtype "wwan")
        ;; for wwan, need to determine how to get strength and carrier name
        true)
      ))
  event)

(fn uplink []
  (let [links {}
        routes {}
        sock (nl.socket)]
    (fn handle-event [event]
      (match event
        {:event :newlink}
        (tset links event.index
              (match event.up
                "yes" (get-network-info event)
                "no" event))

        {:event :newroute}
        ;; XXX there may be >1 route to any given destination,
        ;; (e.g wwan and wlan both have default route)
        ;; we probably need to store all of them and
        ;; distinguish by metric
        (let [dst (or event.dst "default")
              existing (. routes dst)]
          (if (or (not existing)
                  (< event.metric existing.metric))
              (tset routes dst event)))

        {} (print :unhandled event.event)
        ))
    (each [_ event (ipairs (sock:query ))]
      (handle-event event))

    {
     :refresh #(each [_ event (ipairs (sock:event))]
                 (handle-event event))
     :fd (sock:fd)
     :status (fn [self]
               (self:refresh)
               (let [defaultroute routes.default
                     interface (and defaultroute
                                    (. links defaultroute.index))]
                 (and interface (= interface.running "yes")
                      (get-network-info interface))))
     :wait #(sock:poll 1000)
     :interface (fn [self ifnum]
                  (. links ifnum))
     }
    ))

(comment
(let [nl (netlunk)]
  (while (or (nl:wait) true)
    (nl:refresh)
    (match (nl:uplink)
      interface
      (print "default route through " (view interface))
      nil
      (print "no default route")
      ))))

{
 :new uplink
 }
