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
1. A public Load Balancer has been created and its public IP address mapped to the target domain, e.g. `example.com`. You may follow the steps outlined in this [blog post](https://fuzziebrain.com/content/id/2005/) to create and configure a load balancer for the [Oracle Application Express](https://apex.oracle.com) (APEX) instance running on an [Oracle Autonomous Database](https://www.oracle.com/autonomous-database/).
1. Downloaded the latest release of this repository and uploaded the ZIP file to the `/tmp/` directory on the Compute instance.

> **IMPORTANT**
>
> As stated in the [LICENSE](./LICENSE) file, the code in this repository is provided as-is and **without warranty and support**. You are expected to have basic Linux and OCI proficiency to perform these tasks, adapt the instructions to your environment and ability to troubleshoot any potential issues.

## OCI Requirements

### Identity Access Management

1. [Create a dynamic group](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingdynamicgroups.htm#ariaid-title9), e.g. *WebServers*, and assign the instance that where the scripts will run on.
1. [Create a policy](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingpolicies.htm#ariaid-title6), e.g. *LoadBalancerManagementPolicy*, to allow the dynamic group to create certificates and update load balancer's listeners in the specified compartment. The simplest statement to get started with, is this:
    ```
    allow dynamic-group WebServers to use load-balancers in compartment MyCompartment
    ```

   > **NOTE**
   >
   > I will update this document with the minimal required policy statements at a later time.

### Load Balancer

The script assumes that you have a public load balancer created. In addition, you **must**:

1. [Create a listener](https://docs.cloud.oracle.com/iaas/Content/Balance/Tasks/managinglisteners.htm#ariaid-title5) that supports the `HTTP` protocol and listens on port `80`.
1. [Create a backend set](https://docs.cloud.oracle.com/iaas/Content/Balance/Tasks/managingbackendsets.htm#ariaid-title6) that uses the Compute instance where the scripts will be deployed to.
    * For the health check policy, set this to use the `TCP` protocol and then specify SSH port (usually `22`). Make sure that the security lists are updated to allow communication between the load balancer and Compute instance's subnets.
    * [Add a backend server](https://docs.cloud.oracle.com/iaas/Content/Balance/Tasks/managingbackendservers.htm#ariaid-title6), the Compute instance, to the backend set, specifying the port number that [*Certbot*](https://certbot.eff.org/) will use for certificate verification, e.g. `8000`. For simplicity, allow the OCI console to create the security list rules automatically.
1. [Create a Path Route Set](https://docs.cloud.oracle.com/iaas/Content/Balance/Tasks/managingrequest.htm#ariaid-title9) **and associate it with the HTTP listener** created in the earlier step.
    * The path route set must contain one rule with the following properties:
        * **Match Style** - Force Longest Prefix Match
        * **URL String** - `/.well-known`
        * **Backend Set Name** - *Specify the backend set created earlier*

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
1. Change the working directory:
    ```bash
    cd $APP_HOME
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

1. Create a file, e.g. `example-com.env`. This file must be created in the directory defined by `APP_HOME` and should have the following variables defined:
    ```
    DOMAIN=example.com,www.example.com
    EMAIL=johndoe@example.com
    DEPLOY_TARGET=LB
    LB_OCID=ocid1.loadbalancer.oc1...
    LISTENER_NAME=listener_https
    DRY_RUN=Y
    ```

    > **IMPORTANT**
    >
    > * If you don't already have a listener setup for HTTPS, then exclude the `LISTENER_NAME` variable for now. Once the certificate has been deployed to the load balancer specified by the OCID, you may use that certificate to create the required listener supporting SSL communications.
    > * You may add more than one domains to the certificate. Assign them as a comma-delimited list to the `DOMAIN` variable.
1. Generate and deploy the certificate. If the `LISTENER_NAME` is defined, then the new certificate will be assigned to the listener as well.
    ```bash
    $APP_HOME/cert-manager.sh -a generate -f example-com.env -p 8000
    ```

## Renew Certificates

1. Add to the crontab as *root*:
    ```
    0 2 * * * opc cd /opt/docker/oci-le-cert-manager && ./cert-manager.sh -a renew -f example-com.env -p 8000 >> ./logs/le-example-com.log
    ```

## TODO

* Support automatic updating of Web Appllication Firewalls.
* Support generating wildcard SSL certificates.
