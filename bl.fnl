(local {: bar : indicator : stylesheet  : run} (require :blinkenlicht))
(local {: view} (require :fennel))

(local iostream (require :iostream))
(local metric (require :metric))

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
  :anchor [:top :right]
  :orientation :horizontal
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

   (let [f (iostream.open "/tmp/statuspipe" :r)]
     (indicator {
                 ;; this is a guide to tell blinkenlicht when it might
                 ;; be worth calling your `content` function. Your
                 ;; function may be called at other times too
                 :wait-for { :input [f] }

                 ;; the `content` function should not block, so e.g
                 ;; don't read from files unless you know there's data
                 ;; available. it returns a hash
                 ;; { :text "foo" } - render "foo" as a label
                 ;; { :icon "face-sad" } - render icon from theme or pathname
                 ;; { :classes ["foo" "bar"] - add CSS classes to widget
                 :refresh
                 #(let [l (f:read 1024)]
                    (if l
                        {:text l}))
                 }))

   (indicator {
               :wait-for { :interval 2000 }
               :refresh
               #{:icon (if (> (metric.loadavg) 2) "face-sad" "face-smile")}
               })

   (indicator {
               :wait-for { :interval (* 1000 10) }
               :refresh
               #(let [{:power-supply-energy-full full
                       :power-supply-energy-now now
                       :power-supply-status status} (metric.battery)
                      percent (math.floor
                               (* 100
                                  (/ (tonumber now) (tonumber full))))
                      icon-code (battery-icon-codepoint status percent)]
                  {:text
                   (string.format "%s %d%%" (utf8.char icon-code) percent)
                   :classes ["yellow"]
                   })
               })
   (indicator {
               :wait-for { :interval 1000 }
               :refresh #{:text (os.date "%H:%M:%S")}
               })
   (indicator {
               :wait-for { :interval 4000 }
               :refresh #{:text (os.date "%H:%M:%S")}
               })
   ]})

(run)
