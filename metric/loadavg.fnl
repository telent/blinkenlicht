(fn loadavg []
  (with-open [f (io.open "/proc/loadavg" :r)]
    (let [line (f:read "*a")
          (one five fifteen) (line:match "([%d.]+) +([%d.]+) +([%d.]+)")]
      (values (tonumber one) (tonumber five) (tonumber fifteen)))))

{:new #{
        :read #(loadavg)
        })
