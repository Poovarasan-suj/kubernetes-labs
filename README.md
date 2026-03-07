
# Kubernetes Minikube Networking Lab

## Project Overview

This project demonstrates basic Kubernetes networking concepts using a local cluster created with Minikube.

The lab includes:

* Deployment creation
* Pod networking
* Service creation (ClusterIP)
* Service exposure (NodePort)
* Accessing applications from outside the cluster

This project was implemented on a Rocky Linux VM using Docker as the Minikube driver.

---

# Architecture

```
Client
   │
NodePort (30007)
   │
Node IP (192.168.49.2)
   │
Kubernetes Service (ClusterIP)
   │
Pods (NGINX containers)
```

Network layers observed in the cluster:

| Component         | Example       |
| ----------------- | ------------- |
| Node IP           | 192.168.49.2  |
| Service ClusterIP | 10.108.11.250 |
| Pod Network       | 10.244.0.x    |

---

# Environment

| Component         | Version     |
| ----------------- | ----------- |
| OS                | Rocky Linux |
| Kubernetes CLI    | kubectl     |
| Local Cluster     | Minikube    |
| Container Runtime | Docker      |
| Application       | NGINX       |

Tools used:

* Kubernetes
* Minikube
* kubectl
* Docker
* NGINX

---

# Step 1 — Start Minikube Cluster

Start the cluster:

```bash
minikube start --driver=docker
```

Verify node:

```bash
kubectl get nodes
```

Example output:

```
NAME       STATUS   ROLES           AGE
minikube   Ready    control-plane
```

---

# Step 2 — Create Deployment

Create an nginx deployment.

```bash
kubectl create deployment nginx-deployment --image=nginx
```

Scale to 3 replicas:

```bash
kubectl scale deployment nginx-deployment --replicas=3
```

Check pods:

```bash
kubectl get pods -o wide
```

Example:

```
nginx-deployment-xxx   Running   10.244.0.3
nginx-deployment-xxx   Running   10.244.0.4
nginx-deployment-xxx   Running   10.244.0.5
```

---

# Step 3 — Test Pod Connectivity

Access the pod directly:

```bash
curl http://10.244.0.3
```

Output:

```
Welcome to nginx!
```

This confirms that Pod networking is working.

---

# Step 4 — Create ClusterIP Service

Create `service.yaml`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-cip-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
    - port: 9000
      targetPort: 80
```

Apply service:

```bash
kubectl apply -f service.yaml
```

Verify service:

```bash
kubectl get svc
```

Example:

```
NAME             TYPE        CLUSTER-IP
my-cip-service   ClusterIP   10.108.11.250
```

---

# Step 5 — Verify Service Endpoints

Check connected pods:

```bash
kubectl get endpoints my-cip-service
```

Example:

```
10.244.0.3:80
10.244.0.4:80
10.244.0.5:80
```

---

# Step 6 — Test ClusterIP

Login into the Minikube node:

```bash
minikube ssh
```

Test service:

```bash
curl http://10.108.11.250:9000
```

Output:

```
Welcome to nginx!
```

---

# Step 7 — Convert Service to NodePort

Edit the service:

```bash
kubectl edit svc my-cip-service
```

Change:

```
type: ClusterIP
```

to

```
type: NodePort
```

Check service:

```bash
kubectl get svc
```

Example:

```
my-cip-service   NodePort   10.108.11.250   9000:30007/TCP
```

---

# Step 8 — Get Minikube Node IP

```bash
minikube ip
```

Example:

```
192.168.49.2
```

---

# Step 9 — Access Application

Test using NodePort:

```bash
curl http://192.168.49.2:30007
```

Output:

```
Welcome to nginx!
```

---

# Networking Flow

```
User Request
      │
Node IP:30007
      │
NodePort
      │
ClusterIP Service
      │
Pod (nginx)
```

Kubernetes automatically load balances traffic between pods.

---

# Kubernetes Concepts Demonstrated

This lab covered the following concepts:

* Kubernetes Deployment
* Replica Pods
* Pod networking
* ClusterIP Service
* NodePort Service
* Kubernetes Endpoints
* Internal and external service access

---

# Key Commands

```bash
minikube start
kubectl get nodes
kubectl create deployment
kubectl scale deployment
kubectl get pods -o wide
kubectl apply -f service.yaml
kubectl get svc
kubectl describe svc
kubectl get endpoints
minikube ip
curl http://<node-ip>:<nodeport>
```

---

# Conclusion

This lab demonstrates how Kubernetes services expose applications using ClusterIP and NodePort. The application was deployed using nginx with multiple replicas and accessed through Minikube networking.

---

