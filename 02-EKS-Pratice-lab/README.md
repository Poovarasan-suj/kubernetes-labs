
# Amazon EKS RBAC & IRSA Hands-On Lab Documentation

## Overview

This lab demonstrates how to configure **user access control and pod-level AWS permissions** in Kubernetes running on
Amazon Elastic Kubernetes Service.

During this exercise we implemented:

1. Kubernetes RBAC (Role Based Access Control)
2. IAM user authentication to the EKS cluster
3. Namespace-level access control
4. Read-only cluster access
5. Pod identity using Service Accounts
6. AWS access from pods using **IRSA**

By the end of the lab, we achieved:

* **Dev user** → access only to a specific namespace
* **Readonly user** → read-only cluster access
* **Pod** → securely access S3 using IAM Role

---

# Architecture

```
AWS IAM Users
     │
     ▼
EKS Authentication (aws-auth ConfigMap)
     │
     ▼
Kubernetes RBAC
     │
     ├── Role + RoleBinding (namespace access)
     └── ClusterRole + ClusterRoleBinding (cluster access)

Pods
 │
 ▼
ServiceAccount
 │
 ▼
IAM Role (IRSA)
 │
 ▼
Amazon S3
```

---

# Prerequisites

Before starting the lab the following were prepared:

* AWS Account
* CLI tools installed
* VM instances to simulate different users

Services used:

* Amazon Elastic Kubernetes Service
* Amazon Elastic Compute Cloud
* Amazon Simple Storage Service
* AWS Identity and Access Management

---

# Lab Environment

VM instances created:

| VM          | Purpose                    |
| ----------- | -------------------------- |
| Root VM     | Cluster administration     |
| Dev VM      | Developer namespace access |
| Readonly VM | Cluster monitoring user    |

---

# Step 1 – Configure kubectl Access

The root VM connected to the EKS cluster.

Command used:

```bash
aws eks update-kubeconfig --name my-eks-cluster
```

Purpose:

This command downloads cluster configuration and updates the local **kubeconfig** file so `kubectl` can communicate with the Kubernetes API server.

Verify connection:

```bash
kubectl get nodes
```

Expected output:

```
NAME                        STATUS
ip-172-31-xx-xx             Ready
ip-172-31-xx-xx             Ready
```

This confirms the cluster nodes are active.

---

# Step 2 – Create Namespace

Namespaces allow isolation of workloads inside Kubernetes.

Command:

```bash
kubectl create namespace dev-namespace
```

Verify:

```bash
kubectl get namespace
```

Example output file name for GitHub:

```
outputs/namespace-created.png
```

---

# Step 3 – Create IAM Users

Two users were created in IAM:

| User          | Purpose          |
| ------------- | ---------------- |
| dev-user      | Developer access |
| readonly-user | Monitoring user  |

Minimal policy attached:

```
eks:DescribeCluster
eks:ListClusters
```

These permissions allow the AWS CLI to retrieve cluster details.

---

# Step 4 – Map IAM Users to Kubernetes

EKS uses a ConfigMap named **aws-auth** to map IAM identities to Kubernetes users.

Command used:

```bash
kubectl edit configmap aws-auth -n kube-system
```

Users added under `mapUsers`.

Example configuration:

```yaml
mapUsers:
  - userarn: arn:aws:iam::ACCOUNT:user/dev-user
    username: dev-user
    groups:
      - dev-group

  - userarn: arn:aws:iam::ACCOUNT:user/readonly-user
    username: readonly-user
    groups:
      - readonly-group
```

Purpose:

This connects AWS IAM identities with Kubernetes RBAC groups.

---

# Step 5 – Create Role (Namespace Access)

A Kubernetes **Role** grants permissions inside a specific namespace.

Role definition:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev-namespace
  name: dev-role
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "services", "deployments", "jobs"]
  verbs: ["get","list","create","update","delete","watch"]
```

Apply:

```bash
kubectl apply -f role.yaml
```

---

# Step 6 – Create RoleBinding

RoleBinding assigns the role to a user or group.

```yaml
kind: RoleBinding
metadata:
  name: dev-role-binding
  namespace: dev-namespace
subjects:
- kind: Group
  name: dev-group
roleRef:
  kind: Role
  name: dev-role
```

Apply:

```bash
kubectl apply -f role.yaml
```

Result:

The **dev user** can manage resources only in `dev-namespace`.

---

# Step 7 – Create ClusterRole

A **ClusterRole** provides permissions across the entire cluster.

```yaml
kind: ClusterRole
metadata:
  name: cluster-role
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods","services","deployments","jobs"]
  verbs: ["get","list","watch"]
```

Purpose:

Provide read-only access.

---

# Step 8 – Create ClusterRoleBinding

Bind the ClusterRole to readonly users.

```yaml
kind: ClusterRoleBinding
metadata:
  name: cluster-role-binding
subjects:
- kind: Group
  name: readonly-group
roleRef:
  kind: ClusterRole
  name: cluster-role
```

---

# Step 9 – Test RBAC Permissions

Dev user test:

```
kubectl get pods
```

Result:

```
Forbidden
```

Namespace test:

```
kubectl get pods -n dev-namespace
```

Result:

```
Allowed
```

Readonly user test:

```
kubectl create deployment nginx
```

Result:

```
Forbidden
```

This confirms RBAC works correctly.

---

# Step 10 – Service Account Concept

In Kubernetes, a **ServiceAccount** provides identity for pods.

Purpose:

Allow applications inside pods to communicate with:

* Kubernetes API
* External services

Example creation:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: s3-read-sa
  annotations:
    eks.amazonaws.com/role-arn: IAM_ROLE_ARN
```

---

# Step 11 – IAM Role for Service Accounts (IRSA)

IRSA allows pods to access AWS services securely.

Flow:

```
Pod
↓
ServiceAccount
↓
IAM Role
↓
AWS Service
```

Feature name:

IAM Roles for Service Accounts

---

# Step 12 – Create S3 Bucket

A bucket was created in:

Amazon Simple Storage Service

Public access remained **blocked** for security.

---

# Step 13 – Create IAM Role for Pod

IAM role created with policy:

```
AmazonS3ReadOnlyAccess
```

This allows the pod to list S3 buckets.

Trust policy used OIDC provider of the cluster.

---

# Step 14 – Create Pod Using ServiceAccount

Example pod definition:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: s3-reader
spec:
  serviceAccountName: s3-read-sa
  containers:
  - name: awscli
    image: amazonlinux
    command: ["/bin/sh"]
    args: ["-c","yum install -y aws-cli && aws s3 ls"]
```

Apply:

```
kubectl apply -f pod.yaml
```

---

# Step 15 – Verify Pod Access

Check logs:

```
kubectl logs s3-reader
```

Expected output:

```
bucket-name
```

This confirms the pod accessed S3 using IAM Role.

---

# Key Concepts Learned

### Role

Grants permissions **within a namespace**.

### RoleBinding

Associates a Role with users or groups.

### ClusterRole

Grants permissions across the entire cluster.

### ClusterRoleBinding

Associates ClusterRole with users or groups.

### ServiceAccount

Provides identity for pods.

### IRSA

Allows pods to securely access AWS services using IAM roles.

---

# Lab Outcome

After completing this lab we successfully implemented:

* Kubernetes RBAC
* Namespace isolation
* IAM authentication
* Pod identity
* Secure AWS access from containers

---


