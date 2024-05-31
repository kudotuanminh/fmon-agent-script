# fmon-agent-script

curl -s https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/main/telegraf/linux-online/telegraf.sh | bash -s -- -v -c https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/main/telegraf/example.conf

curl -s https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/main/fluent-bit/linux-online/fluent-bit.sh | bash -s -- -v -c https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/main/fluent-bit/example.conf

(iwr -useb https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/main/telegraf/windows-online/telegraf.ps1 -OutFile "telegraf.ps1"); (.\telegraf.ps1 -v -c https://raw.githubusercontent.com/kudotuanminh/fmon-agent-script/main/telegraf/example.conf)
