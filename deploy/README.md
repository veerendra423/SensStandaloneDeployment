# Deploy new infrastructure

This guide lists out the steps to deploy new infrastructure

## Setup

Add azure credentials in the file named `credentials`

## Creating the VM
Run `deploy.sh`

```sh
./deploy.sh
```

## Destroying the infrstructure

```
./destroy.sh
```

## Login to the new VM
To login to new VM:
```
ssh -i <Private Key file> -l nference <IP Address>
```
