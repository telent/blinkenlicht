(local {: view} (require :fennel))

(fn loadavg []
  (with-open [f (io.open "/proc/loadavg" :r)]
    (let [line (f:read "*a")
          (one five fifteen) (line:match "([%d.]+) +([%d.]+) +([%d.]+)")]
      (values (tonumber one) (tonumber five) (tonumber fifteen)))))

(fn battery [name]
  (let [name (.. "/sys/class/power_supply/" name  "/uevent")]
    (with-open [f (io.open name :r)]
      (let [fields {}]
        (each [line #(f:read "*l")]
          (let [(name value) (line:match "([^=]+)=(.+)")]
            (tset fields (: (name:gsub "_" "-") :lower) value)))
        fields))))

(fn parse-cpu-stat-line [line]
  (let [labels [:user :nice :system :idle :iowait
                :irq :softirq :steal :guest :guest_nice]
        vals (icollect [field (line:gmatch "([%d.]+)")]
                 (tonumber field))]
    (collect [i label (ipairs labels)]
      label (. vals i))))

(var  proc-stat-handle nil)

(fn cpustat [path]
  (if proc-stat-handle
      (proc-stat-handle:seek :set 0)
      (set proc-stat-handle (io.open "/proc/stat" :r)))
  (let [f proc-stat-handle]
    (accumulate [ret nil
                 line #(f:read "*l") ]
                (if (= (string.sub line  1 (# "cpu ")) "cpu ")
                    (parse-cpu-stat-line line)
                    ret))))

{: loadavg
 : battery
 : cpustat
 }
