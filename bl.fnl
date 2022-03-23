(local {: bar : indicator : run} (require :blinkenlicht))

(fn loadavg []
  (with-open [f (io.open "/proc/loadavg" :r)]
    (tonumber (: (f:read "*a") :match "[0-9.]+" ))))

(fn disk-free-percent []
  83)

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
               :text "HI!"
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
