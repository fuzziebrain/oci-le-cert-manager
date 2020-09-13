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
1. A public Load Balancer has been created and its public IP address mapped to the target domain, e.g. `example.com`. For the purpose of this documentation, we will use the steps outlined in this [blog post](https://fuzziebrain.com/content/id/2005/) that creates and configures a load balancer for the [Oracle Application Express](https://apex.oracle.com) (APEX) instance running on an [Oracle Autonomous Database](https://www.oracle.com/autonomous-database/).
1. Downloaded the latest release of this repository and uploaded the ZIP file to the `/tmp/` directory on the Compute instance.

> **IMPORTANT**
>
> As stated in the [LICENSE](./LICENSE) file, the code in this repository is provided as-is and **without warranty and support**. You are expected to have basic Linux and OCI proficiency to perform these tasks, adapt the instructions to your environment and ability to troubleshoot any potential issues.

## OCI Requirements

### Identity Access Management

1. [Create a dynamic group](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingdynamicgroups.htm#ariaid-title9), e.g. *WebServers*, and assign the instance that where the scripts will run on.
1. [Create a policy](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingpolicies.htm#ariaid-title6), e.g. *LoadBalancerManagementPolicy*, to allow the dynamic group to create certificates and update load balancer's listeners in the specified compartment. The simplest statement to get started with, is this:
    ```
    allow dynamic-group WebServers to manage load-balancers in compartment MyCompartment
    ```

   > **NOTE**
   >
   > I will update this document with the minimal required policy statements at a later time.

### Load Balancer


## Setup

1. Obtain your [tenancy OCID](https://docs.cloud.oracle.com/iaas/Content/General/Concepts/identifiers.htm#tenancy_ocid) and [region](https://docs.cloud.oracle.com/iaas/Content/General/Concepts/regions.htm) information and then set the following enviroment variables:
    ```bash
    APP_HOME=/opt/docker/oci-le-cert-manager
    TENANCY_OCID=ocid1.tenancy.oc1.....
    REGION=us-ashburn-1
    ```
1. Extract the contents of the ZIP file and place them into the `APP_HOME` directory. You should have the following:
    ```
    /opt/docker/oci-le-cert-manager
    ├── Dockerfile
    ├── LICENSE
    ├── README.md
    ├── app
    │   ├── cert-manager
    │   ├── deploy-cert-to-lb
    │   └── requirements.txt
    ├── build.sh
    ├── cert-manager.sh
    ├── domain.env.sample
    └── logs
    ```
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
1. Finally, build the Docker image using the provided shell script:
    ```bash
    ./build.sh
    ```

## Generate Certificates

1. Create environment file `example-com.env` with the following contents:
    ```
    DOMAIN=example.com,www.example.com
    EMAIL=johndoe@example.com
    LB_OCID=ocid1.loadbalancer.oc1...
    LISTENER_NAME=listener_https
    DEPLOY_TARGET=LB
    DRY_RUN=Y
    ```


## Renew Certificates

1. Add to the crontab as *root*:
    ```
    0 2 * * * opc /opt/docker/oci-le-cert-manager/cert-manager.sh -a renew -f apex-example-com.env -p 8000 >> /opt/docker/oci-le-cert-manager/logs/le-apex-example-com.log
    ```

## TODO

* Support automatic updating of Web Appllication Firewalls.
* Support generating wildcard SSL certificates.