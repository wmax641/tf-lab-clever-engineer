# Lab - Clueless Engineer

## Scenario 
A clever Security Engineer has a requirement to provide system logs via a HTTP API, and they know well enough to protect the sensitive data using **base64** encryption. Due their tight deadlines, they've published the system logs via an unauthenticated API on the public internet to deliver their project as soon as possible.

You are an even more clever Security Engineer who has stumbled on these protected logs, and has noticed a credential leakage issue. You've decided to help out by taking over the administration of the exposed server to <s>use for your own purposes</s> help prevent abuse by would-be hackers.

## Task

You will be given the HTTP API endpoint and parameters to request the logs

* Find the exposed "**password**" and host details from the logs
* Take control over the exposed **Linux** server, and lock down **user access** to protect the system from other intruders

Explain how you completed the above 2 tasks, exhibiting any code/scripts used.

### Notes / Restrictions
* The server is owned and controlled by the interviewer, you have permission to log onto it and secure it.
* The server can be destroyed and re-deployed via the API as well. The new instance will have the same initial config with only the server's public IP address being changed. Subsequent logs requested from the API will reflect the changed IP address.
* There is no need nor expectation to install software on the server (it has no internet connectivity)
* There is no need nor expectation to execute technical exploits or run malware
* There is no need nor expectation to use any AWS services
