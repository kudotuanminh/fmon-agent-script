# fmon-agent-script

curl -s https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/master/telegraf/linux-online/telegraf.sh | bash -s -- -v -c https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/master/telegraf/example.conf

curl -s https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/master/fluent-bit/linux-online/fluent-bit.sh | bash -s -- -v -c https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/master/fluent-bit/example.conf

(iwr -useb https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/master/telegraf/windows-online/telegraf.ps1 -OutFile "telegraf.ps1"); (.\telegraf.ps1 -v -c https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/master/telegraf/example.conf)
