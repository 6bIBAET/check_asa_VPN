<h1 align="left">
  Icinga2 plugin to check amount of VPN connection on ASA
</h1>

Checked on ASA 5500
# 📚 Manual:

# 💻 Installation:
Download and add to icinga plugin dir

# 📋 Configuration:
Add to files:

- **commands.conf** 
```bash
object CheckCommand "check_vpn" {
  import "plugin-check-command"
  command = [ PluginDir + "/check_vpn.sh" ]
  arguments = {
    "-H" = "$host.address$"
    "-A" = "$rsa_file$"
    "-U" = "$sshuser_name$"
    "-P" = "$ciscoenable_password$"
    "-C" = "$vpn_check$"
  }
        vars.rsa_file = "/path/to/.ssh/id_rsa"
        vars.sshuser_name = "USERNAME"
        vars.ciscoenable_password = "PASSWORD"
        vars.vpn_check = "$service.vars.vpncheckcommand$"
}
```

- **service.conf**

```bash
apply Service "VPN Amount" {
   display_name = "Number of VPN sessions"
   import "check_vpn"
   check_command = "check_vpn"
   vars.vpncheckcommand = "vpnamount"
   assign where host.vars.vpnconnect == "true"

}


apply Service "VPN Users" {
   display_name = "List of connected VPN users"
   import "check_vpn"
   check_command = "check_vpn"
   enable_perfdata = false
   vars.vpncheckcommand = "vpnusers"
   assign where host.vars.vpnconnect == "true"

}
```

- **Add to asa host config**
```bash
object Host "ASA-01" {
.....
vars.vpnconnect = "true"
.....
```




