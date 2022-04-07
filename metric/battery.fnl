(fn battery [name]
  (let [name (.. "/sys/class/power_supply/" name  "/uevent")]
    (with-open [f (io.open name :r)]
      (let [fields {}]
        (each [line #(f:read "*l")]
          (let [(name value) (line:match "([^=]+)=(.+)")]
            (tset fields (: (name:gsub "_" "-") :lower) value)))
        fields))))

{ :new
 (fn [name]
   {
    :read #(battery name)
    })
 }
