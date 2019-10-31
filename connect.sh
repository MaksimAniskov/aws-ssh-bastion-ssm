#!/bin/bash

if [ "$#" -lt 1 ]
then
  cat >&2 << EOT
Connects EC2 instance over SSH over SSM Sessions with an one-time key leveraging Amazon EC2 Instance Connect.

Usage: $0 user-name@instance-id [ssh options ...]

EOT
  exit 1
fi

IFS='@'
read -ra params <<< "$1"
userName=${params[0]}
instanceId=${params[1]}
if [ -z "$instanceId" ]
then
  echo "Instance id not set"
  exit 2
fi

az=`aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[0].Instances[0].Placement.AvailabilityZone" --output text`
retVal=$?
if [ $retVal -ne 0 ]; then
    exit $retVal
fi

keyFileName="ec2instconnect.$RANDOM"
ssh-keygen -f $keyFileName -q

aws ec2-instance-connect send-ssh-public-key --instance-id $instanceId --availability-zone $az --instance-os-user $userName --ssh-public-key file://$keyFileName.pub
#>/dev/null
retVal=$?
if [ $retVal -ne 0 ]; then
    rm $keyFileName $keyFileName.pub
    exit $retVal
fi

shift
ssh -i $keyFileName $* $userName@$instanceId

rm $keyFileName $keyFileName.pub
