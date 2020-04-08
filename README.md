# SSH Surfer
Bash SSH connection tool

### Required Packages
- awk
- cat
- ssh

### Installing
First start by cloning this repository

```
cd <your-git-folder>
git clone https://github.com/geodavies/ssh-surfer.git
```
Next we need to configure which servers you want to connect to. This script will look for the file *servers.csv* in your .ssh directory
for the configuration of the servers by default. This location can be changed by updating the location at the top of the script.

The *example-servers.csv* file inside this repository can be used as a starting point. The below commands for your system 
will move the *example-servers.csv* file to your home .ssh directory and change the location in the script. If you already
have a *servers.csv* file in your home .ssh directory it will be replaced, so make sure you back it up first or skip the second command.

**Linux**
```
cd ssh-surfer
cp example-servers.csv /home/$USER/.ssh/servers.csv
sed -i 's/^input=.*$/input="\/home\/$USER\/.ssh\/servers.csv"/g' ssh-surfer.sh
```
**MacOS**
```
cd ssh-surfer
cp example-servers.csv /Users/$USER/.ssh/servers.csv
sed -i '' 's/^input=.*$/input="\/Users\/$USER\/.ssh\/servers.csv"/g' ssh-surfer.sh
```
You can now execute the script directly from the git repository directory if you choose but you may want to
create a symlink to the script so it can be executed from anywhere in the terminal.
```
sudo ln -s $PWD/ssh-surfer.sh /usr/local/bin/ss
```
The script can now be run from anywhere by using the command '*ss*

### Usage
To get usage instructions run the script without any arguments
```
ss
```
```
Usage: [command] [name]
    1: The command to perform on the server (eg. ls/connect/deploy)
    2: The name of the server (eg. server-name)
```
Servers can either be directly referenced by their name (eg. SERV0001). For the ls command though the name is optional.

Servers can also be referred to by any of their tags. If for example you want to list all servers which contain both the *dev* and *example* tags
then you can run 'ss ls dev example'. Note that when starting by tag all tags provided must be present in the spreadsheet record.

### Commands

#### List (ls)
This will list all of the servers in the spreadsheet filtered by any optional tags specified

```
ss ls
```
```
Tags                                     | Server Name               | Server IP       | Username
-----------------------------------------+---------------------------+-----------------+----------------------
dev example 1                            | SERV0001                  | 123.123.123.123 | myuser
test example 2                           | SERV0002                  | 987.987.987.987 | otheruser
```

```
ss ls dev example
```
```
Tags                                     | Server Name               | Server IP       | Username
-----------------------------------------+---------------------------+-----------------+----------------------
dev example 1                            | SERV0001                  | 123.123.123.123 | myuse
```

#### Connect (connect)
Connects to a given server, you can either specifiy the server name directly eg. 'SERV0001' or a combination of tags. Note that
if you are using tags to filter the server to connect to then it must filter down to exactly one server otherwise an error will occur.
```
ss connect dev example 1
```
```
Connecting to SERV0001 at 123.123.123.123 as user myuser...
```

#### Deploy (deploy)
Deploys SSH keys from the local machine onto the remote machine. This allows the server to be logged onto in the future without
a password being required.

You will be prompted for your password to the server at this point and once complete the connect command will no longer prompt for it.
```
ss deploy test example 2
```
```
Deploying SSH keys for passwordless login to SERV0002 at 987.987.987.987 as user otheruser...
Type in your password for the server when prompted.
```
