# XRayGUI
**Dependencies:** systemd gtk2 fping wget p7zip zenity  
  
A small and nimble GUI + [XRay-core](https://github.com/XTLS/Xray-core) - all in one rpm package: launch, find `VMESS`, `VLESS`, `SS (Shadowsocks without obfs)` or `Trojan` configurations on the network, copy to the buffer, paste into `XRayGUI` (`Paste` button) and click `Start`. If the green indicator lights up and the logs run, the connection is established. In the browser, set the SOCKS5 - `127.0.0.1`:`1080` proxy and redirect DNS via proxy (check the box there). The list of configurations can be saved to a file and downloaded from a file (PopUp Menu). You can check your new location here: https://whoer.net  

**Support:**
+ Shadowsocks
+ VMESS, VMESS TLS, VMESS + WS, VMESS + WS + TLS, VMESS + KCP
+ VLESS, VLESS TLS, VLESS + WS, VLESS + WS TLS, VLESS + gRPC, VLESS + gPRC + TLS, VLESS + KCP
+ Trojan, Trojan + WS, Trojan + gRPC
  
**Note:** Starting with XRayGUI-v1.1, the binary `xray-core` removed from the rpm package is downloaded and updated directly from the developer's GitHub to the directory `~/.config/xraygui/xray`.  
  
![](https://github.com/AKotov-dev/XRayGUI/blob/main/ScreenShots/XRayGUI-4.png)  
  
Tested in Mageia-8/9 and LUbuntu-22.04.
