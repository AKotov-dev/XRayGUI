# XRayGUI
**Dependencies:** systemd gtk2 fping wget p7zip zenity lib64proxy-gnome lib64proxy-kde  
  
**Ports used:** `SOCKS` - 127.0.0.1:1080 (can be changed), `HTTP` - 127.0.0.1:8889 (fixed).
  
A small and nimble GUI for [XRay-core](https://github.com/XTLS/Xray-core): launch, find `VMESS`, `VLESS`, `SS (Shadowsocks)` or `Trojan` configurations on the network, copy to the buffer, paste into `XRayGUI` (`Paste` button) and click `Start`. If the green indicator lights up and the logs run, the connection is established. In the browser, set the SOCKS5 - `127.0.0.1`:`1080` proxy and redirect DNS via proxy (check the box there). The list of configurations can be saved to a file and downloaded from a file (PopUp Menu). You can check your new location here: https://whoer.net  

**Support (without obfs):**
+ Shadowsocks
+ VMESS, + TLS, + WS, + WS + TLS, + KCP
+ VLESS, + TLS, + WS, + WS + TLS, + gRPC, + gPRC + TLS, + KCP, + REALITY
+ Trojan, + WS, + gRPC

Starting with `XRayGUI-v1.6`, support for `XTLS-Reality` and a generator of simple but reliable Client-Server configurations have been introduced ("R" button).

System-Wide Proxy
--
Starting from `XRayGUI-v1.5`, it became possible to use the connection as a global proxy for the entire system (`SWP` checkbox). This allows you to redirect all traffic through Socks5 without manually interfering with browser settings. The mode is guaranteed to work in GNOME, Budgie, Cinnamon, MATE (package required: `lib64proxy-gnome`) and KDE-5 (package required: `lib64proxy-kde`).
  
**Note:** Starting with `XRayGUI-v1.1`, the binary `xray-core` removed from the rpm package is downloaded and updated directly from the developer's GitHub to the directory `~/.config/xraygui/xray`.  
  
![](https://github.com/AKotov-dev/XRayGUI/blob/main/Screenshot2.png)  
  
Tested in Mageia-9 and Linux Mint.
