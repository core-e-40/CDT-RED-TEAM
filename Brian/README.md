# Party Rocket (Flagfinder + CredHarvester + SSH Creds Beacon)
#### DISCLAIMER: This tool is to only be used for educational cybersecurity red teaming purposes and can never be used for illegal action. Any knowledge gained through this tool is never to be used maliciously.
## 1. Tool Overview
### This tool is fully deployed through Ansible and contains a flag finder, credential harvester and beacon. The tool starts with the flag finder, which goes through directories on all boxes with the given IPs and looks for text relating to the predetermined flag structure. Next it runs through the credential harvester, which goes through files like the flag finder but instead looks for sensitive data like usernames and passwords for services. It also gives information on open ports through nmap scans. Lastly, the heart of the tool is the beacon. This is deployed in a hidden file on each box, is immutable, and redeploys itself after a minute if somehow deleted. This beacon stores credentials used to login to any of these boxes in a file, and we can watch that file from our red team boxes to get updated ssh credentials every minute by using the watch Linux function. This tool was designed for Linux, but may branch to other systems in the future. This tool is useful for Red Team especially if we get a head start into the Blue Team's boxes because it allows us to get as many flags and credentials as possible before they get the chance to protect their services. Also when they inevitably login to their boxes through ssh, we will have gained a way to directly access their machines. This tool fits into the information gathering and beacon categories.


## 2. Requirements & Dependencies
### This tool was mainly tested on Ubuntu 22.04 and 24.04 machines, but will work on most Linux based operating systems. It uses the bash language to run commands so Linux is required, but it may not work as well in other Linux systems if the file structure is very different because of the file searching capabilities. Ansible, nmap, and sshpass are required packages for this tool. Root privileges are not specifically required to run this tool, but may be depending on how the system is setup through ssh. You must be on the same network as the target IPs to be able to run this tool. You must also have ssh credentials for the ansible to run.
   
## 3. Installation Instructions
### The first step is to clone this repository on your deployment box (red team workstation) using this command:


~~~
    git clone https://github.com/BrianVanini/redteamtool.git
~~~


###    Once the github project is cloned, we will need to install our required dependencies using the command below:
~~~
    sudo apt update && sudo apt install -y nmap ansible sshpass
~~~
###    After the packages download, we need to configure the IPs and credentials of the target boxes. Set the target IPs in your desired inventory file in the inventory folder, and fill in the user and password in the fields. We can then run the tool using the command below. The -K function allows us to type the sudo password if needed.
~~~
    ansible-playbook -i inventory/[inventory filename].ini playbook.yml -K
~~~
###    If the playbook goes through without any errors, the tool has been deployed successfully. You should see any flags or credentials found as it runs.


## 4. Usage Instructions
###    After the playbook runs successfully, you can view the logged ssh credentials in the loot file on the local directory of your deployment machine. Run the command below to view it:
~~~
    cat ~/redteamtool/ansible/loot/ssh.txt
~~~
###    Additionally, you can watch the credentials live as they update every minute using the command below:
~~~
    watch -n 60 'ansible all -i inventory/greyblue.ini -o -m shell \
  -a "echo -n \"LAST: \"; cat /var/lib/systemd/ssh-service.log.old 2>/dev/null; \
      echo -n \"\nNEW: \"; cat /var/lib/systemd/ssh-service.log 2>/dev/null; \
      cp /var/lib/systemd/ssh-service.log /var/lib/systemd/ssh-service.log.old 2>/dev/null; \
      > /var/lib/systemd/ssh-service.log" \
  --become --extra-vars "ansible_become_pass=Cyberrange123!" | sed "s/\\\\n/\n/g" | tee -a ~/redteamtool/ansible/loot/ssh.txt'
~~~

### The output will look similar to the screenshot below:
![alt text](image.png)
## 5. Operational Notes
###    Step 4 contains all commands to run for this tool. This tool creates the beacon file within /usr/local/bin/ssh-auth-check and the log file for credentials can be found within /var/lib/systemd/ssh-service.log. The local loot file is found on the deployment box with the file path /redteamtool/ansible/loot/ssh.txt. A risk with this tool are that the files can be found and deleted, but reappear after being run again, so this risk is low that it breaks something. The main risk is that if the ansible isn't configured correctly, it may not work correctly or run at all. Preventing this is difficult as Ansible is picky with its credentials but ensures that the user, password, and ips are correct for all related systems. The last big risk is that Blue Team may see traffic with this tool are firewall off our IP, but if it is run fast enough, we should get all the credentials, flags, and ports we need, and our beacon will be able to feed us credentials if they are changed because it uses PAM instead of ssh.


###   You can uninstall the tool as you desire using the command below:
~~~
    ansible-playbook -i inventory/[inventory filename].ini nuke.yml -K
~~~
## 6. Limitations


###   The tool cannot see any active directory logins, so if the Blue Team solely uses that we won't get any use of the beacon. The tool is best when used with a terminal dedicated to watching the ssh logins live, so that takes some time to set up. It also relies on flags being named a specific way and requires internal IPs and ssh credentials for target boxes, so it has to be deployed immediately before Blue Team can lock us out of potential use for this tool. There are no known bugs for this tool, but an issue is that it may take longer for this tool to function if one of the IP connections fails since it waits for every box to connect. The solution to this is to update the credentials of the failed box connections in the inventory file and make sure it is correct, otherwise the other best option is to take the failed box IPs out of the inventory file so it runs smoother and lose out on potential gain from the failed boxes. A future consideration is to make this project more flexible to different configurations and be more forgiving when it comes to connection failures.
## 7. Credits & References
### This tool was developed with the intellect of Brian Vanini and the help of Gemini AI for some of the coding.
