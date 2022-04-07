(fn parse-cpu-stat-line [line]
  (let [labels [:user :nice :system :idle :iowait
                :irq :softirq :steal :guest :guest_nice]
        vals (icollect [field (line:gmatch "([%d.]+)")]
                 (tonumber field))]
    (collect [i label (ipairs labels)]
      label (. vals i))))

(fn cpustat [proc-stat-handle]
  (let [f proc-stat-handle]
    (f:seek :set 0)
    (accumulate [ret nil
                 line #(f:read "*l")
                 :until ret]
                (if (= (string.sub line  1 (# "cpu ")) "cpu ")
                    (parse-cpu-stat-line line)
                    ret))))
{
 :new
 #(let [handle (io.open "/proc/stat" :r)]
    {
     :read #(cpustat handle)
     })
 }
