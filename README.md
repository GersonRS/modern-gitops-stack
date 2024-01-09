<!--
*** Thank you for viewing our README. if you have any suggestion
*** that can improve it even more fork the repository and create a Pull
*** Request or open an Issue with the tag "suggestion".
*** Thank you again! Now let's run this amazing project : D
-->

# Modern DevOps Stack

<!-- PROJECT SHIELDS -->

[![npm](https://img.shields.io/badge/type-Open%20Project-green?&style=plastic)](https://img.shields.io/badge/type-Open%20Project-green)
[![GitHub last commit](https://img.shields.io/github/last-commit/GersonRS/modern-devops-stack?logo=github&style=plastic)](https://github.com/GersonRS/modern-devops-stack/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/gersonrs/modern-devops-stack?logo=github&style=plastic)](https://github.com/GersonRS/modern-devops-stack/issues)
[![GitHub Language](https://img.shields.io/github/languages/top/gersonrs/modern-devops-stack?&logo=github&style=plastic)](https://github.com/GersonRS/modern-devops-stack/search?l=python)
[![GitHub Repo-Size](https://img.shields.io/github/repo-size/GersonRS/modern-devops-stack?logo=github&style=plastic)](https://img.shields.io/github/repo-size/GersonRS/modern-devops-stack)
[![GitHub Contributors](https://img.shields.io/github/contributors/GersonRS/modern-devops-stack?logo=github&style=plastic)](https://img.shields.io/github/contributors/GersonRS/modern-devops-stack)
[![GitHub Stars](https://img.shields.io/github/stars/GersonRS/modern-devops-stack?logo=github&style=plastic)](https://img.shields.io/github/stars/GersonRS/modern-devops-stack)
[![NPM](https://img.shields.io/github/license/GersonRS/modern-devops-stack?&style=plastic)](LICENSE)
[![Status](https://img.shields.io/badge/status-active-success.svg)](https://img.shields.io/badge/status-active-success.svg)

<p align="center">
  <img alt="logo" src=".github/assets/images/logo.png"/>
</p>

## Overview

The Modern DevOps Stack is composed of several Terraform modules used to deploy a Kubernetes cluster along with a stack of components that will allow you to deploy applications as well as monitor and troubleshoot your cluster.

The choice of the cluster module is dependant on the provider on which you wish to deploy your cluster. The Modern DevOps Stack currently supports only a local deployment using KinD. The modules that deploy the remaining components of the stack are as generic as possible, but in the future, some have provider-specific variants that deploy different resources depending on the platform.

As you’ll see in this project, after the cluster is deployed, a  Argo CD is installed to then deploy the rest of the components. After all the components have been deployed, this Argo CD instance can be used to deploy your applications (we also created modules to create and configure Argo CD Applications and ApplicationSets).

## Table of Contents

* [Objective](#objective)
* [Versioning Flow](#versioning-flow)
* [Tools](#tools)
* [Getting Started](#getting-started)
* [Requirements](#requirements)
* [Usage](#usage)
* [Project Structure](#project-structure)
* [Troubleshooting](#troubleshooting)
  + [Jupyterhub Login](#jupyterhub-login)
  + [Install libs Python](#install-libs-python)
* [Contributions](#sontributions)
* [License](#license)
* [Contact](#contact)
* [Acknowledgments](#acknowledgments)

## Objective

The purpose of this repository is to provide a framework and series of tools for data orchestration and DataOps, with the aim of facilitating the management of end-to-end data workflows. By leveraging Terraform and type, the project can be easily configured to provide a practical playground that includes tools capable of performing data extraction, transformation and loading, validation, and monitoring.

## Versioning Flow

We follow the [Semantic Versioning](https://semver.org/) and [gitflow](https://www.atlassian.com/br/git/tutorials/comparing-workflows/gitflow-workflow) for versioning this project. For the versions available, see the tags on this repository.

## Tools

The following tools are used in this project:

* **Terraform:** Infrastructure-as-Code tool used to automate the setup of the Kubernetes cluster and related resources.

* **Kubernetes (kind)**: A lightweight Kubernetes implementation that allows running Kubernetes clusters inside Docker containers.

* **MetalLB**: A Load Balancer for Kubernetes environments, enabling external access to services in the local environment.

* **ArgoCD**: A GitOps Continuous Delivery tool for Kubernetes, facilitating the management of applications.

* **Traefik**: An Ingress Controller for Kubernetes, routing external traffic to applications within the cluster.

* **Cert-Manager**: A certificate management tool, enabling the use of HTTPS for applications.

* **Keycloak**: An identity management and access control service, securing applications and resources.

* **Minio**: A cloud storage server compatible with Amazon S3, providing object storage for applications.

* **kube-prometheus-stack**: A collection of Kubernetes manifests, Grafana dashboards, and Prometheus rules combined with documentation and scripts to provide easy to operate end-to-end Kubernetes cluster monitoring with Prometheus using the Prometheus Operator.

* **loki-stack**: Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus. It is designed to be very cost effective and easy to operate. It does not index the contents of the logs, but rather a set of labels for each log stream.

* **thanos**: Thanos is a highly available metrics system that can be added on top of existing Prometheus deployments, providing a global query view across all Prometheus installations.

These tools together enable the creation of a complete infrastructure for the development and management of Machine Learning applications in the Kubernetes environment.

## Requirements

To use MLflow-Kube, you need to have the following prerequisites installed and configured:

1. Terraform:
    - Installation: Visit the [Terraform website](https://www.terraform.io/downloads.html) and follow the instructions for your operating system.
2. Docker:
    - Installation: Install Docker by following the instructions for your operating system from the [Docker website](https://docs.docker.com/get-docker/).
3. Kubernetes CLI (kubectl):
    - Installation: Install `kubectl` by following the instructions for your operating system from the [Kubernetes website](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
4. Helm:
    - Installation: Install Helm by following the instructions for your operating system from the [Helm website](https://helm.sh/docs/intro/install/).

## Getting Started

To get started with the MLflow POC, follow these steps:

1. Clone this repository to your local computer.
    - `git clone https://github.com/GersonRS/mlflow-kube-poc.git`
2. Change directory to the repository:
    - `cd mlflow-kube-poc`

> Make sure you have Terraform installed on your system, along with other necessary dependencies.

3. Run `terraform init` to initialize Terraform configurations.
* 

```sh
  terraform init
  ```

> `This command will download the necessary Terraform plugins and modules.`

4. Run `terraform apply` to start the provisioning process. Wait until the infrastructure is ready for use.
* 

```
  terraform apply
  ```

> `Review the changes to be applied and confirm with yes when prompted. Terraform will now set up the Kubernetes cluster and deploy the required resources.`

5. After the Terraform apply is complete, the output will display URLs for accessing the applications. Use the provided URLs to interact with the applications.
6. The Terraform output will also provide the credentials necessary for accessing and managing the applications. Run `terraform output` to get the credentials.
* 

```
  terraform output -json credentials
  ```

## Usage

Once the infrastructure is successfully provisioned, you can utilize the installed applications.

## Project Structure

This project follows a structured directory layout to organize its resources effectively:

```sh
    .
    ├── kind-config
    ├── LICENSE
    ├── locals.tf
    ├── main.tf
    ├── modules
    │   ├── argocd
    │   ├── cert-manager
    │   ├── keycloak
    │   ├── kind
    │   ├── kube-prometheus-stack
    │   ├── loki-stack
    │   ├── metallb
    │   ├── minio
    │   ├── oidc
    │   ├── thanos
    │   └── traefik
    ├── outputs.tf
    ├── README.md
    ├── terraform.tf
    └── variables.tf

    68 directories, 240 files
```

* [**LICENSE**](LICENSE) - License file of the project.
* [**locals.tf**](locals.tf) - Terraform locals file.
* [**main.tf**](main.tf) - Main Terraform configuration file.
* [**modules**](modules/) - Directory containing all the Terraform modules used in the project.
  + [**argocd**](modules/argocd/) - Directory for configuring ArgoCD application.
  + [**cert-manager**](modules/cert-manager/) - Directory for managing certificates using Cert Manager.
  + [**jupyterhub**](modules/kube-prometheus-stack/) - Directory for setting up Prometheus monitor.
  + [**keycloak**](modules/keycloak/) - Directory for installing and configuring Keycloak.
  + [**kind**](modules/kind/) - Directory for creating a Kubernetes cluster using Kind.
  + [**metallb**](modules/metallb/) - Directory for setting up MetalLB, a load balancer for Kubernetes.
  + [**minio**](modules/minio/) - Directory for deploying and configuring Minio for object storage.
  + [**mlflow**](modules/loki-stack/) - Directory for setting up Loki-stack.
  + [**oidc**](modules/oidc/) - Directory for OpenID Connect (OIDC) configuration.
  + [**postgresql**](modules/thanos/) - Directory for deploying and configuring Thanos.
  + [**traefik**](modules/traefik/) - Directory for setting up Traefik, an ingress controller for Kubernetes.
* [**outputs.tf**](outputs.tf) - Terraform outputs file.
* [**README.md**](README.md) - Project's README file, containing important information and guidelines.
* [**terraform.tf**](terraform.tf) - Terraform configuration file for initializing the project.
* [**variables.tf**](variables.tf) - Terraform variables file, containing input variables for the project.

## Troubleshooting

## Contributions

Contributions are welcome! Feel free to create a pull request with improvements, bug fixes, or new features. Contributions are what make the open source community an amazing place to learn, inspire, and create. Any contribution you make will be greatly appreciated.

To contribute to the project, follow the steps below:

1. Fork the project.
2. Create a branch for your contribution (git checkout -b feature-mycontribution).
3. Make the desired changes to the code.
4. Commit your changes (git commit -m 'MyContribution: Adding new feature').
5. Push the branch to your Fork repository (git push origin feature-mycontribution).
6. Open a Pull Request on the main branch of the original project. Describe the changes and wait for the community's review and discussion.

We truly value your interest in contributing to the MLflow-Kube project. Together, we can make it even better!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For any inquiries or questions, please contact:

<p align="center">

[![twitter](https://img.shields.io/badge/-Twitter-9cf?logo=Twitter&logoColor=white)](https://twitter.com/gersonrs3)
[![instagram](https://img.shields.io/badge/-Instagram-ff2b8e?logo=Instagram&logoColor=white)](https://instagram.com/gersonrsantos)
[![linkedin](https://img.shields.io/badge/-Linkedin-blue?logo=Linkedin&logoColor=white)](https://www.linkedin.com/in/gersonrsantos/)
[![Telegram](https://img.shields.io/badge/-Telegram-blue?logo=Telegram&logoColor=white)](https://t.me/gersonrsantos)
[![Email](https://img.shields.io/badge/-Email-c14438?logo=Gmail&logoColor=white)](mailto:gersonrodriguessantos8@gmail.com)

</p>

## Acknowledgments

We appreciate your interest in using MLflow on Kubernetes PoC. We hope this configuration simplifies the management of your Machine Learning experiments on Kubernetes! 🚀📊
