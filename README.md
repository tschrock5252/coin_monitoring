# coin_monitoring

## Purpose
This repository was created so I could monitor crypto locslly in my environment with a VM and get email alerts when it started to become more profitable.

While you can technically do this with apps and alerts on your phone, the apps get overloaded from time to time and I've also found they have some interesting ways of manipulating the price. 

The data crypto.com shows seems accurate (on page load), but I think they play with their prices using their javascript and other tools to manipulate the market a bit.

I wanted that fluctuation taken out of the equation with my purchasing decision(s). 

## Architecture Diagram(s)
![alt text](https://github.com/tschrock5252/coin_monitoring/blob/master/coin_monitoring.png?raw=true)

## Requirement(s)

### Infrastructure
You will have to dedicate a VM or some form of infrastructure to this. I am sure you can get it to work in a container as well, but I have not tested that out yet.

I am running this at present on an Ubuntu 20.04.3 VM and am having no issues with the configuration. YMMV on other operating systems.

### Cron Daemon
You will need to configure a cron job to execute the [coin-monitor.sh](https://github.com/tschrock5252/coin_monitoring/blob/master/scripts/coin-monitor/coin-monitor.sh) script on a consistent basis.

I am running this multiple times per minute on staggered cron jobs to pull data at a _**VERY**_ consistent basis.

An example cron is set up in this repository for you to view at the following location: [./example.cron](https://github.com/tschrock5252/coin_monitoring/blob/master/example.cron)

### Script(s)
This project's heart is currently built into a script that lives within the repository at [./scripts/coin-monitor/coin-monitor.sh](https://github.com/tschrock5252/coin_monitoring/blob/master/scripts/coin-monitor/coin-monitor.sh)

You will need to set this up in order for this project to be a success. The script will create the required directories for everything each coin you are monitoring to run successfully.

#### Configurable Variables
The script has a large number of variables that you can configure and change if you want to.

I try to use variables heavily in all shell scripts I write. It makes configuration much easier for folks later.

To make this functional you at least have to change one that is in the script: **EMAIL_TO**

This variable configures where your alerts are going to be sent to when the price(s) of your monitored coin(s) start to rise.

I also recommend you take a look at the following: 

```
COIN_LOWER1=${2};
COIN_LOWER2=${3};
COIN_LOWER3=${4};
COIN_LOWER4=${5};
```

These are the values that are passed in from the command line with regards to the monitoring metrics for each coin.

When each of these is crossed, new alert messages are emailed to you.

It is worth noting, you will receive 5 daily emails for each coin you monitor at the start of the day - to give you a baseline of where the coin's price is.

Once that has been crossed, you should not be nagged anymore until you reset the counters for each coin - or a new day passes.

I only set the script up to monitor a total of four values via loop(s) at this time. More can be set up, but this is still a work in progress.

I will wait to see if I want something that alerts more.

### SSMTP
Your infrastructure needs to have SSMTP set up on it. This is a requirement for the [coin-monitor.sh](https://github.com/tschrock5252/coin_monitoring/blob/master/scripts/coin-monitor/coin-monitor.sh) script to work.

**Ubuntu Installation**:
```
# Install SSMTP
sudo apt install ssmtp
```
**RHEL/CentOS Install**:
```
# Remove postfix in case it is there
yum remove postfix

# Install SSMTP
yum install ssmtp --enablerepo=epel
```

You will also need to set up appropriate configuration for SSMTP.

**Ubuntu/RHEL/CentOS Location**: /etc/ssmtp/ssmtp.conf

An example of that is set up in this repository at the following location for you to reference: [./etc/ssmtp/ssmtp.conf](https://github.com/tschrock5252/coin_monitoring/blob/master/etc/ssmtp/ssmtp.conf)

#### SSMTP Configuration Notes

The email account that you are tying this to via config is not who you are _sending_ this to. 

The account you are tying this to via config is a relay account. The flow of data looks like this for mail.

**Local Server ---> GMail Relay Account ---> Target Email User Inbox**

It's important to keep this in mind in case mail relay starts failing.