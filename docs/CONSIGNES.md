# Project Brief

## Summary

Over the past few weeks, we got hands-on with a local Kubernetes environment using Kind, taking as an example a microservices application that we ported onto this platform, and for which we configured external access to the cluster, resources, health checks, and so on. Now it is time to move to production and deploy it on a "real" Kubernetes cluster!

We will need to go back to basics and build a continuous integration and continuous deployment pipeline on GitLab for this application. That means: build and push our container image to a remote registry (on Azure), create our Kubernetes cluster, and finally apply our YAML manifests to deploy the application "for real".

The Kubernetes offering on Azure is "AKS", aka Azure Kubernetes Services. It lets you create managed Kubernetes clusters using Azure VMs as worker nodes. Start with the smallest possible cluster (1 node, for example), and pay attention to the VM type and to costs. Recommended VM model to get started: Standard D2s v3. To begin with, we will use the "AKS Standard" offering, not "AKS Automatic".

## Typical Workflow

1. Prepare the Azure environment: create an image registry, create a Kubernetes cluster.
2. Build and push the image from your own PC locally, then apply the YAML manifests on the cluster to check that everything works.
3. Test the application: can you reach it from its public IP?
4. Build the CI that builds and pushes the image to the registry automatically (still no secrets!).
5. Build the CD that connects to the Kubernetes cluster, then applies the YAML manifests.
6. Document the steps in a Markdown file.

## Deliverable & Tips

The application must be reachable through its Load Balancer IP, accessible only from the Simplon premises (http://<load balancer ip>/data).

Remember to tag your images properly, with a different tag on each commit for example. You need clear versioning to be able to handle the CD part correctly afterwards.

Start by creating the resources by hand: use the Azure portal and get to a "working" result before you start automating. You can even push the app image directly from your PC.
