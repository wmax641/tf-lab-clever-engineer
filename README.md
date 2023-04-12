# Interview Lab - Clueless Engineer

## Scenario 
A clever Security Engineer has a requirement to provide system logs via a HTTP API. They know well enough to protect the sensitive logs using **base64** encryption. Due their tight deadlines for delivery, they've published the system logs via an unauthenticated API on the public internet. 

You are an even more clever Security Engineer who has stumbled on these protected logs, and has noticed a credential leakage issue. You've decided to help out by taking over the administration of the exposed server to help prevent abuse by <s>other</s> would-be crafty hackers.

## Task

You will be given the HTTP API endpoint and parameters to request the logs

* Find the exposed "**password**" and host details from the logs
* Take control over the exposed **Linux** server, and lock down **user access** to protect the system from other intruders

Explain how you completed the above 2 tasks, exhibiting any code/scripts used.

### Notes / Restrictions
* The server is owned and controlled by the interviewer, you have permission to log onto it and secure it.
* If the server is rebooted or shutdown, it will be destroyed and automatically redeployed with the same initial config after a few minutes. However, the server's public IP address will be changed, and the logs from the API will reflect that.
* There is no need nor expection to install software on the server (it has no internet connectivity)
* There is no need nor expectation to execute technical exploits or run malware
* There is no need nor expectation to use any AWS services
