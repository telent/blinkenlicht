(local {: bar : indicator : stylesheet  : run} (require :blinkenlicht))

(local {: view} (require :fennel))

(local iostream (require :iostream))
(local metric (require :metric))
(local uplink (require :uplink))
(local modem (require :modem))

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
                 #(let [current (. (metric.cpustat) :iowait)
                        delta (- current previous)
                        v (if (> delta 4) "" "  ")]
                    (set previous current)
                    {:text v})
                 }))

   (let [modem (modem.new)]
     (indicator {
                 :wait-for {
                            :interval (* 4 1000)
                            }
                 :refresh
                 #(let [{:m3gpp-operator-name operator
                         :signal-quality quality} (modem:value)]
                    {:text (.. operator
                               ;" " (. quality 1) "dBm"
                               )
                     })
                 }))

   (let [uplink (uplink.new)
         input (iostream.from-descriptor uplink.fd)]
     (indicator {
                 :wait-for {
                            :input [input]
                            }
                 :refresh
                 #(let [status (uplink:status)]
                    (if status
                        {:text (.. (or status.ssid status.name "?")
                                   " "
                                   (if status.quality
                                       ;; this is in dBm, allegedly.
                                       ;; typical values
                                       ;; -20 (good) -> -100 (awful)
                                       (tostring (+ status.quality 100))
                                       ""))}
                        {:text "no internet"}
                        ))
                    }))

   (indicator {
               :wait-for { :interval (* 1000 10) }
               :refresh
               #(let [{:power-supply-capacity percent
                       :power-supply-status status}
                      (metric.battery "axp20x-battery")
                      icon-code (battery-icon-codepoint
                                 status (tonumber percent))]
                  {:text
                   (string.format "%s %d%%" (utf8.char icon-code) percent)
                   :classes ["battery" (if (< (tonumber percent) 20) "low" "ok")]
                   })
               })
   (indicator {
               :wait-for { :interval 4000 }
               :refresh #{:text (os.date "%H:%M")}
               })

   ]})

(run)
