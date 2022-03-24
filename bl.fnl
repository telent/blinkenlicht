(local {: bar : indicator : run} (require :blinkenlicht))

(fn loadavg []
  (with-open [f (io.open "/proc/loadavg" :r)]
    (tonumber (: (f:read "*a") :match "[0-9.]+" ))))

(fn disk-free-percent []
  83)

(fn battery-status [path]
  (let [name (.. (or path "/sys/class/power_supply/BAT0") "/uevent")]
    (with-open [f (io.open name :r)]
      (let [fields {}]
        (each [line #(f:read "*l")]
          (let [(name value) (line:match "([^=]+)=(.+)")]
            (tset fields (: (name:gsub "_" "-") :lower) value)))
        fields))))

(fn spawn []
  true)

(bar
 {
  :anchor [:top :right]
  :orientation :horizontal
  :indicators
  [
   (indicator {
               :interval 200
               :icon #(if (> (loadavg) 2) "face-sad" "face-smile")
               })
   ;; (let [f (io.open "/tmp/statuspipe" "r")]
   ;;   (indicator {
   ;;               :poll [f]
   ;;               :text #((f:read):sub 1 10)
   ;;               }))
   (indicator {
               :interval (* 10 1000)
               :text #(let [{:power-supply-energy-full full
                             :power-supply-energy-now now}
                            (battery-status)]
                        (string.format "BAT %d%%"
                                       (math.floor (* 100 (/ (tonumber now) (tonumber full))))))
               })
   (indicator {
               :interval 5000
               :text #(.. (disk-free-percent "/") "%")
               :on-click #(spawn "baobab")
               })
   (indicator {
               :interval 1000
               :text #(os.date "%X")
               })
   ]})

(run)
