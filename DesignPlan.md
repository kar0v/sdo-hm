## Table of Contents
- [Destination Database](#destination-database)
- [Migration Methods](#migration-methods)
- [Network and security](#network-and-security)
- [Migration plan](#migration-plan)
# Destination Database
The two main options is to run MSSQL either on a self-hosted set of EC2 instances or RDS. I would choose RDS anytime over EC2 instances unless there are client specific configurations that are not supported in RDS. <br><br> 
**RDS** is easily scalable, configurable, manageable and monitorable as opposed to self-hosting clusters. It interracts with a ton of other AWS Services flawlessly. <br><br>
The migration process will need to be tested throughly before being done on production, so a migration scenario to a test environment should be used in the first place.<br>
Once all testing has been done in the testing environment, the same process can be applied to the production environment. 

[Back to top](#table-of-contents)
# Migration Methods

Exploring the 3 main methods for migration. 
1. **Backup and restore** <br>
This option requires the downtime equivalent of the cumulative time of multiple tasks - backing up the databases, encrypting the database archives, transferring them, decrypting the archives and restoring them. <br>
If this is done in an online fashion, then the gap between the backed-up state and the current state might be quite large. <br><br>
I would choose this option, when downtime is not a problem. <br><br>

1. **Data replication** / Data sync <br>
![alt text](images/DesignPlan/data-replication.svg) <br>
This option requires the use of a VM and the data is not streamed, so there is high latency. Also the throughput is dependent on the VM resources with the need to get a better disk. <br><br>
I would choose this option if we can't use DMS. <br><br>

1. **AWS DMS** <br>
The Data Migration Service, which AWS offers, provides synchronous transactional replication with capturing data changes. Creates the destination resources by itself, which could be configured as well. 
<br><br>
Limitations: AWS DMS needs to use MS-CDC for tables with or without primary keys, as I have chosen to use RDS. More info here: https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.CDC.html#CHAP_Source.SQLServer.Configuration


[Back to top](#table-of-contents)
# Network and security
Lets explore some networking connectivity from Azure to AWS. 

Azure Networks 
- VNAT 10.10.0.0/16
- GatewaySubnet 10.10.255.0/24
- Virtual Network Gateway
- Local Network Gateway
- Network Security Groups
- Azure Firewall within its own VNAT

AWS Network 
- VPC 10.20.0.0/16
- rds-a subnet 10.20.0.0/24
- rds-b subnet 10.20.1.0/24
- rds-c subnet 10.20.2.0/24
- Customer Gateway
- Private VPN Gateway
- S2S vpn connection

# Migration plan


1. Create a full backup of the database in Azure. 


