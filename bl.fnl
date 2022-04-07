(local {: bar : indicator : stylesheet  : run} (require :blinkenlicht))

(local {: view} (require :fennel))

(local iostream (require :iostream))
(local modem (require :modem))

(local uplink (require :metric.uplink))
(local battery (require :metric.battery))
(local cpustat (require :metric.cpustat))

(stylesheet "licht.css")

(fn battery-icon-codepoint [status percent]
  (if (= status "Charging") 0xf0e7
      (> percent 90) 0xf240                ;full
      (> percent 60) 0xf241                ;3/4
      (> percent 40) 0xf242                ;1/2
      (> percent 15) 0xf243                ;1/4
      (>= percent 0)  0xf244                ;empty
      ; 0xf377         ; glyph not present in font-awesome free
      ))

(fn wlan-quality-class [quality]
  (if (< -50 quality) "p100"
      (< -67 quality) "p75"
      (< -70 quality) "p50"
      (< -80 quality) "p25"
      "p0"))

(fn spawn []
  true)

(bar
 {
  ;; bar must be full width to set up an "exclusive zone" (moves
  ;; other windows out of the way), otherwise it will display on
  ;; to of whatever's on the screen already
  :anchor [:top :right :left]
  :orientation :horizontal
  :gravity :end
  :classes ["hey"]
  :indicators
  [
   (let []
     (var previous 0)
     ;; on my laptop, adding this indicator has made the task
     ;; go from ~ 1% cpu to around 3%, which is not ideal
     (indicator {
                 :wait-for { :interval (* 1 500) }
                 :refresh
                 (let [stat (cpustat.new)]
                   #(let [current (. (stat:read) :iowait)
                          delta (- current previous)
                          v (if (> delta 4) "" "  ")]
                      (set previous current)
                      {:text v}))
                 }))

   (indicator {
               :wait-for {
                            :interval (* 4 1000)
                          }
               :refresh
               (let [modem (modem.new)]
                 #(let [{:m3gpp-operator-name operator
                         :signal-quality quality} (modem:read)]
                    {:text (.. operator
                               ;;" " (. quality 1) "dBm"
                               )
                     }))
                 })

   (let [uplink (uplink.new)
         input (iostream.from-descriptor uplink.fd)]
     (indicator {
                 :wait-for {
                            :input [input]
                            }
                 :refresh
                 #(let [status (uplink:read)
                        devtype status.devtype]
                    (if status
                        {:text (.. (or status.ssid status.name "?")
                                   " ")
                         :classes [devtype
                                   (and (= devtype "wlan")
                                        (wlan-quality-class status.quality))]
                         }
                        {:text "no internet"}
                        ))
                    }))

   (indicator {
               :wait-for { :interval (* 1000 10) }
               :refresh
               (let [battery (battery.new (or (os.getenv "BLINKEN_BATTERY")
                                              "axp20x-battery"))]
                 #(let [{:power-supply-capacity percent
                         :power-supply-status status}
                        (battery.read)
                        icon-code (battery-icon-codepoint
                                   status (tonumber percent))]
                    {:text
                     (string.format "%s %d%%" (utf8.char icon-code) percent)
                     :classes ["battery" (if (< (tonumber percent) 20) "low" "ok")]
                     }))
               })
   (indicator {
               :wait-for { :interval 4000 }
               :refresh #{:text (os.date "%H:%M")}
               })

   ]})

(run)
