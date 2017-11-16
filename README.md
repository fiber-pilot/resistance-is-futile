# resistance-is-futile
#A short powershell script that parses through, netflow, pcap and memory files using variety of tools, 
#this is semi specific to a given instance but could be modified with little trouble to become a bit more powerful


#fairly simple to run just make sure you can run powershell scripts on your local machine, if your not admin you can run:

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

#that will allow you to run as the current user 
# when ran this will ask for some file locations, bad IP address and UTC offset, it will parse all the files looking for all things
# related to that IP address and IPs that are two degrees seperated (this will return alot of worthless junk) but it is necessary to
# be accurate
