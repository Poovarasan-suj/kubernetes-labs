# Kubernetes 3-Tier Application Deployment (AWS EKS)

## Project Overview

This project demonstrates how to deploy a **3-tier application architecture on Kubernetes** using AWS EKS.
The goal of this project is to practice Kubernetes core concepts such as:

* Namespaces
* ConfigMaps
* Secrets
* Persistent Volumes (PV)
* Persistent Volume Claims (PVC)
* Deployments
* Services
* Ingress Controller
* Ingress Resource
* Label Selectors
* Volume Mounts

This project simulates a real production-style application architecture.

---

# Architecture

Internet
↓
AWS Load Balancer (ELB)
↓
NGINX Ingress Controller
↓
Ingress Resource
↓
Frontend Service
↓
Frontend Pods (Nginx)
↓
Backend Service
↓
Backend Pods (HTTP API)
↓
MySQL Service
↓
MySQL Pod
↓
Persistent Volume Storage

---

# Technologies Used

* Kubernetes
* AWS EKS
* NGINX Ingress Controller
* Docker Containers
* MySQL Database
* kubectl CLI
* Linux

---

# Project Structure

```
kubernetes-project/
│
├── namespace.yaml
├── configmap.yaml
├── secret.yaml
├── pv.yaml
├── pvc.yaml
├── mysql-deployment.yaml
├── mysql-service.yaml
├── backend-deployment.yaml
├── backend-service.yaml
├── frontend-deployment.yaml
├── frontend-service.yaml
└── ingress.yaml
```

---

# Step 1 — Namespace

File: `namespace.yaml`

Purpose:
Namespaces are used to **logically separate resources in Kubernetes**.

Example:

```
cloud-project
```

Benefits:

* Resource isolation
* Better resource organization
* Easier management

Command used:

```
kubectl apply -f namespace.yaml
```

Verification:

```
kubectl get ns
```

---

# Step 2 — ConfigMap

File: `configmap.yaml`

ConfigMaps store **non-sensitive configuration data**.

Example:

```
APP_ENV=production
APP_VERSION=v1
APP_DEBUG=false
```

Pods can read these values as **environment variables**.

Command:

```
kubectl apply -f configmap.yaml
```

Verification:

```
kubectl get configmap -n cloud-project
```

---

# Step 3 — Secret

File: `secret.yaml`

Secrets store **sensitive data** such as:

* database passwords
* API keys
* credentials

Example stored values:

```
username
password
```

Important rule:
Secrets must be stored in **Base64 encoded format**.

Example encoding:

```
echo -n "admin" | base64
```

Command:

```
kubectl apply -f secret.yaml
```

Verification:

```
kubectl describe secret db-secret -n cloud-project
```

---

# Step 4 — Persistent Volume (PV)

File: `pv.yaml`

Persistent Volumes provide **permanent storage** for containers.

In this project we used:

```
hostPath
```

Example:

```
hostPath: /data/mysql
```

Meaning:

Node Directory → Kubernetes Volume → Container

Storage size:

```
1Gi
```

Access mode:

```
ReadWriteOnce
```

Verification:

```
kubectl get pv
```

---

# Step 5 — Persistent Volume Claim (PVC)

File: `pvc.yaml`

PVC is a **request for storage** by a pod.

Flow:

PV → PVC → Pod

Example request:

```
1Gi storage
```

Command:

```
kubectl apply -f pvc.yaml
```

Verification:

```
kubectl get pvc -n cloud-project
```

Status should be:

```
Bound
```

---

# Step 6 — MySQL Deployment

File: `mysql-deployment.yaml`

This deployment creates the **database container**.

Features used:

* Secret for MySQL password
* PVC for persistent storage
* Volume Mount

Important mount path:

```
/var/lib/mysql
```

This ensures database data is **not lost when pod restarts**.

Verification:

```
kubectl get pods -n cloud-project
```

---

# Step 7 — MySQL Service

File: `mysql-service.yaml`

Services provide a **stable network endpoint for pods**.

Why services are needed:

Pods are temporary and their IP changes.

Service type used:

```
ClusterIP
```

Example access:

```
mysql-service:3306
```

---

# Step 8 — Backend Deployment

File: `backend-deployment.yaml`

This deployment simulates an API service.

Container used:

```
kennethreitz/httpbin
```

Replicas:

```
2
```

This demonstrates **horizontal scaling of pods**.

Verification:

```
kubectl get pods -n cloud-project
```

---

# Step 9 — Backend Service

File: `backend-service.yaml`

Purpose:

Expose backend pods internally in the cluster.

Load balancing occurs automatically between backend pods.

Example communication:

Frontend → backend-service → backend pods

---

# Step 10 — Frontend Deployment

File: `frontend-deployment.yaml`

Frontend container:

```
nginx
```

Replicas:

```
3
```

This simulates a web UI.

Verification:

```
kubectl get pods -n cloud-project
```

---

# Step 11 — Frontend Service

File: `frontend-service.yaml`

Purpose:

Expose frontend pods internally.

Traffic flow:

Ingress → frontend-service → frontend pods

---

# Step 12 — NGINX Ingress Controller

Installed using:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

Purpose:

Ingress controller manages **external traffic routing**.

It creates an **AWS Load Balancer automatically**.

Verification:

```
kubectl get pods -n ingress-nginx
```

---

# Step 13 — Ingress Resource

File: `ingress.yaml`

Ingress exposes services to the internet.

Example routing:

```
/ → frontend-service
```

Verification:

```
kubectl get ingress -n cloud-project
```

Access application using:

```
http://<AWS-ELB-DNS>
```

---

# Key Kubernetes Concepts Practiced

## Labels

Labels are used to identify resources.

Example:

```
app: frontend
```

Selectors use labels to connect resources.

Example:

Service → find pods using labels.

---

## Selectors

Selectors allow Kubernetes to **match resources using labels**.

Example:

```
selector:
  app: frontend
```

This connects the service to frontend pods.

---

## Storage Types

### Static Provisioning

PV is created manually.

Used in this project.

Example:

```
hostPath
```

### Dynamic Provisioning

PVC automatically creates storage using a **StorageClass**.

Example:

AWS EBS.

---

# Useful Debugging Commands

Check pods:

```
kubectl get pods -n cloud-project
```

Check services:

```
kubectl get svc -n cloud-project
```

Check ingress:

```
kubectl get ingress -n cloud-project
```

Describe resource:

```
kubectl describe pod <pod-name>
```

View logs:

```
kubectl logs <pod-name>
```

---

# Project Outcome

This project demonstrates how to deploy a **production-style Kubernetes application** with:

* multi-tier architecture
* persistent storage
* service communication
* external access through ingress

---


