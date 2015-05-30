# backUs
Backup system written in bash for mysql, postgresql and directories


backUs its a backup script to backup:
	- mysql databases
	- postgres databases
	- directories using a version control system
The main feature of the script is to make the backup automatized as posible
and be able to configure and make diferential backups.

The dependencies are:
	+ rdiff (to make diferential backups)
	+ bzr (version control system) or
	+ git (version control system)
	+ mail (to be able to send mails)

TODO:
This script is a work in progress (May 2015) so there are some feature that 
will be checked and some will be added . 


 
