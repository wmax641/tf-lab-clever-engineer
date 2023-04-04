# Interview Lab - Clueless Engineer

## Scenario 
A crafty engineer has a requirement to make the system logs of their app available via unauthenticated API over the public internet, as that's the fastest way to deliver their project. 

As a clever Security Engineer, they know well enough to protect their app's sensitive logs by using **base64** encryption before exposing them on the internet.

You are an even more clever Security Engineer who has stumbled on these protected logs, and has found a credential leakage issue. You've decided to help out by taking over the adminstration of the exposed server to <s>use it for your own purpose</s> help prevent abuse by other would-be crafty <s>hackers</s> security researchers.

## Task

You will be given the API endpoint to request the logs

* Find the exposed credentials and server information in the logs
* Take control over the exposed **Linux** server, and lock down access 

Explain how you completed the above 2 tasks, exhibiting any code/scripts written.

### Notes / Restrictions
* The server is owned and controlled by the interviewer, you have permission to log onto it and try to secure it.
* The server has no outbound internet connectivity, so there is no need nor expection to install software
* There is no need nor expectation to run any technical exploits or to gain privilege escalation
