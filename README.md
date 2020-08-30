# Let's Encrypt Certificate Manager for the Oracle Cloud Infrastructure


## Assumptions

1. Familiar the following OCI concepts:
    * Compute
    * Networking
    * Load Balancing
    * Identity and Access Maangement
        * Policies
        * Instance Principals
    * Obtaining the necessary OCID of these resources as required.
1. An OCI Compute instance has been provisioned with the Oracle Linux 7 operating system.
1. [Docker](https://docker.com) is installed on the Compute instance.
1. A public Load Balancer has been created and its public IP address mapped to the target domain, e.g. `apex.example.com`.
1. Downloaded the latest release of this repository and uploaded the ZIP file to the `/tmp/` directory on the Compute instance.

> **IMPORTANT**
>
> As stated in the [LICENSE](./LICENSE) file, the code in this repository is provided as-is and **without warranty and support**. You are expected to have basic Linux and OCI proficiency to perform these tasks, adapt the instructions to your environment and ability to troubleshoot any potential issues.

## OCI

1. Add Dynamic Group and assign instances.
1. Add Policy to allow Dynamice Group to create certificates and update load balancer's listeners.


## Setup

APP_HOME=/opt/docker/oci-le-cert-manager
TENANCY_OCID=ocid1.tenancy.oc1.....
REGION=us-ashburn-1


1. Extract the contents of the ZIP file and place them into the `APP_HOME` directory.
1. Create the `.oci` directory for storing the required OCI configuration file:
    ```bash
    mkdir -p $APP_HOME/.oci
    ```
1. Create the OCI configuration file (`.oci/config`) with the required information:
    ```
    cat << EOF > $APP_HOME/.oci/config
    [DEFAULT]
    tenancy=$TENANCY_OCID
    region=$REGION
    EOF
    ```
1. Ensure the `.oci` directory and its contents have the correct permissions:
    ```bash
    chmod -R go-rwx $APP_HOME/.oci
    ```
1. Create environment file

```
DOMAIN=example.com
EMAIL=johndoe@example.com
LB_OCID=ocid1.loadbalancer.oc1...
LISTENER_NAME=listener_https
DEPLOY_TARGET=LB
DRY_RUN=Y
```

## Generate Certificates



## Renew Certificates

1. Add to the crontab as *root*:
    ```
    0 2 * * * opc /opt/docker/oci-le-cert-manager/cert-manager.sh -a renew -f apex-example-com.env -p 8000 >> /opt/docker/oci-le-cert-manager/logs/le-apex-example-com.log
    ```

## TODO

* Support automatic updating of Web Appllication Firewalls.
* Support generating wildcard SSL certificates.