# Lab - Clueless Engineer

API doco located on Github Pages for this repo

## Lab Setup

To prep the lab, first create an AMI with the desired settings. 

At the bare minimum, it needs to `yum -y install jq`. This AMI is then referenced by the data module in `instances/ec2.tf` to be used to instantiate lab instances.

## Scenario 
A clever Security Engineer is under pressure to deliver an upcoming deadline to provide system logs via a HTTP API. To meet these requirements in time, they've simply published the unauthenticated API onto the public internet, but they knew well enough to manage that risk by protecting the sensitive data using base64 encryption.

You are an even more clever Security Engineer who has stumbled on these protected logs, and has noticed a credential leakage issue. You've decided to help out by taking over the administration of the exposed server to use for your own purposes help prevent abuse by would-be hackers.

## Task

You will be given the HTTP API endpoint and parameters to request the logs

* Find the exposed "**password**" and host details from the logs
* Take control over the exposed **Linux** server, and lock down **user access** to protect the system from other intruders

Explain how you completed the above 2 tasks, exhibiting any code/scripts used.

### Notes
* The server is owned and controlled by the interviewer, you have permission to log onto it and secure it.

* There is no need nor expectation to install software on the server (server has no internet connectivity)

* There is no need nor expectation to execute technical exploits or run malware

* There is no need nor expectation to use any AWS services

