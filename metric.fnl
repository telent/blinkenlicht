(local {: view} (require :fennel))


(fn loadavg []
  (with-open [f (io.open "/proc/loadavg" :r)]
    (let [line (f:read "*a")
          (one five fifteen) (line:match "([%d.]+) +([%d.]+) +([%d.]+)")]
      (values (tonumber one) (tonumber five) (tonumber fifteen)))))

(print (loadavg))

(fn battery [path]
  (let [name (.. (or path "/sys/class/power_supply/BAT0") "/uevent")]
    (with-open [f (io.open name :r)]
      (let [fields {}]
        (each [line #(f:read "*l")]
          (let [(name value) (line:match "([^=]+)=(.+)")]
            (tset fields (: (name:gsub "_" "-") :lower) value)))
        fields))))

{ : loadavg : battery }
