# Kubernetes Persistent Volumes with AWS EBS (Dynamic Provisioning)

## Overview

In this lab, I practiced **Persistent Storage in Kubernetes using AWS EBS** in an **Amazon EKS cluster**.

The goal was to understand how Kubernetes manages persistent storage using:

* **StorageClass**
* **PersistentVolumeClaim (PVC)**
* **PersistentVolume (PV)**
* **Pod volume mounting**

This setup uses **Dynamic Provisioning**, where Kubernetes automatically creates the EBS volume when a PVC is requested.

---

# Architecture

```
Pod
 ↓
PersistentVolumeClaim (PVC)
 ↓
PersistentVolume (PV)  [Automatically created]
 ↓
AWS EBS Volume
```

Kubernetes dynamically provisions the storage using the **EBS CSI driver**.

---

# Step 1 – Create StorageClass

StorageClass defines **what type of storage Kubernetes should create**.

In this lab we used **AWS EBS CSI driver**.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: example-storage-class
provisioner: ebs.csi.aws.com
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
```

### Explanation

| Parameter         | Purpose                                              |
| ----------------- | ---------------------------------------------------- |
| provisioner       | AWS EBS CSI driver used to create EBS volumes        |
| reclaimPolicy     | Defines what happens to the disk when PVC is deleted |
| volumeBindingMode | Ensures volume is created in the same AZ as the node |

`WaitForFirstConsumer` prevents **AZ mismatch issues**.

---

# Step 2 – Create PersistentVolumeClaim (PVC)

PVC requests storage from the StorageClass.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 4Gi
  storageClassName: example-storage-class
```

### Explanation

| Field            | Meaning                                    |
| ---------------- | ------------------------------------------ |
| accessModes      | EBS supports ReadWriteOnce                 |
| storage          | Requested storage size                     |
| storageClassName | StorageClass used for dynamic provisioning |

When this PVC is created, Kubernetes automatically creates a **PersistentVolume** and **EBS disk**.

---

# Step 3 – Create Pod and Mount the Volume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myweb
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
      - mountPath: "/usr/share/nginx/html/data"
        name: mypd
  volumes:
    - name: mypd
      persistentVolumeClaim:
        claimName: my-pvc
```

### Explanation

| Field        | Purpose                                 |
| ------------ | --------------------------------------- |
| volumeMounts | Mounts the storage inside the container |
| mountPath    | Directory where storage is attached     |
| claimName    | PVC used by the pod                     |

---

# Step 4 – Apply the Resources

```
kubectl apply -f storage.yaml
kubectl apply -f pvc.yaml
kubectl apply -f pods.yaml
```

Check resources:

```
kubectl get storageclass
kubectl get pvc
kubectl get pv
kubectl get pods
```

---

# Verifying the Volume Inside the Pod

Login into the pod:

```
kubectl exec -it myweb -- /bin/bash
```

Check block devices:

```
lsblk
```

Example output:

```
nvme1n1    4G disk  /usr/share/nginx/html/data
```

This confirms that the **EBS volume is successfully mounted**.

---

# Testing Persistent Storage

Create a file inside the mounted volume.

```
cd /usr/share/nginx/html/data

echo "Testing retain policy" >> test.txt
```

Verify:

```
ls
cat test.txt
```

Output:

```
Testing retain policy
```

---

# Persistence Test

Delete the pod:

```
kubectl delete pod myweb
```

Recreate it:

```
kubectl apply -f pods.yaml
```

Enter the pod again and check the file.

```
cat /usr/share/nginx/html/data/test.txt
```

Result:

```
Testing retain policy
```

This confirms **data persists even after pod deletion**.

---

# Reclaim Policy Behavior

The StorageClass uses:

```
reclaimPolicy: Retain
```

This means the EBS disk will **NOT be deleted automatically**.

| Action     | Result                       |
| ---------- | ---------------------------- |
| Delete Pod | Volume remains               |
| Delete PVC | Volume remains               |
| Delete PV  | EBS disk still exists in AWS |

The disk must be **manually deleted from AWS console**.

---

# Issue Faced During Setup

Initially, the PVC remained in **Pending state**.

```
kubectl get pvc
```

Output:

```
my-pvc   Pending
```

Pod status:

```
myweb   Pending
```

---

## Root Cause

The **EBS CSI driver did not have proper permissions**.

The **EBS CSI Controller Pods were crashing**.

```
kubectl get pods -n kube-system
```

Output:

```
ebs-csi-controller   CrashLoopBackOff
```

---

## Fix

The issue was resolved by attaching the required **Pod Identity / IAM role** to the EBS CSI driver.

Required permission policy:

```
AmazonEBSCSIDriverPolicy
```

After attaching the correct permissions, the controller became healthy.

```
ebs-csi-controller   Running
```

Then the PVC automatically became:

```
STATUS: Bound
```

and the pod started successfully.

---

# Key Learnings

* Kubernetes uses **PVC to request storage**
* **Dynamic provisioning automatically creates EBS volumes**
* EBS supports **ReadWriteOnce**
* `WaitForFirstConsumer` prevents AZ mismatch issues
* `Retain` policy keeps the disk even after PVC deletion
* EBS CSI driver must have **proper IAM permissions**
* Pod Identity is required for the CSI driver to interact with AWS APIs

---


