# 2bcloud

1. Infrastructure Provisioning
- Use Terraform to provision the following resources:
-- A Kubernetes Service:
--- Amazon Elastic Kubernetes Service (EKS).
--- Single node pool (minimum setup).
-- A Storage Account:
--- AWS S3 Bucket for managing the Terraform state file.
-- Configure the Kubernetes cluster to be accessible via a load balancer or external IP.

Best Practices Summary
* Terraform State Management → S3 bucket + DynamoDB for locking
* Networking → Proper VPC setup with private/public subnets
* Security → Least privilege IAM roles for EKS
* High Availability → Managed EKS nodes with autoscaling (expandable)
* Access → Load balancer for public-facing services

Steps Overview:
1.1 Setup Terraform Backend (S3 + DynamoDB)
1.2 Provision VPC and Subnets
1.3 Deploy EKS Cluster with a Single Node Pool
1.4 Deploy a Kubernetes Service with Load Balancer
1.5 Configure Access via Load Balancer

Note: 
Whole Terraform declaration - terraform/main.tf
The Region and Availability Zones default values - terraform/variables.tf

1.1 Setup Terraform Backend
It's best practice to store the Terraform state file in Amazon S3 with DynamoDB locking to prevent conflicts.

1.2 VPC and Subnets
Create a VPC, private/public subnets, and an internet gateway.

1.3 Deploy EKS Cluster with a Single Node Pool
Use the EKS module to deploy a cluster with a single managed node group.

1.4 Deploy a Kubernetes Service with Load Balancer
Use Terraform to deploy an Nginx deployment with a LoadBalancer service.

1.5 Configure Access via Load Balancer
After applying Terraform, run:

Configure_Access_via_Load_Balancer.sh

This will show the external IP assigned by AWS Elastic Load Balancer (ELB).


2. Basic Web Application
- Develop or clone a simple "Hello World" web application in Python.
- Include a health-check endpoint (`/healthz`) in the application.

2.1 "Hello World" web application using Python’s built-in HTTP server (http.server and socketserver).
* Root endpoint (/) → Returns "Hello, World!"
* Health check endpoint (/healthz) → Returns a JSON response

Hello_World_web_app.py

Run the python application:

python_run_app.sh

Note: check your "python" is running python 3.x otherwise use right alias to run python 3.x

2.2 Access the endpoints:

root_endpoint.sh

Expected output: Hello, World!

health_check_endpoint.sh

Expected output (json format): {"status": "healthy"}


3. Containerization
- Write a `Dockerfile` to containerize the web application.
- Build the Docker image and push it to a container registry:
-- Use AWS Elastic Container Registry (ECR).

3.1 Create a Dockerfile file near the "Hello World" web application Hello_World_web_app.py

Dockerfile

3.2 Run docker build command to build the Docker image:

docker_build_image.sh

Verify the image is built:

verify_image.sh

Local container testing:

Run the Container Locally

run_container.sh

Check the health-check endpoint

health_check_endpoint.sh

or open a browser with http://localhost:5000/

3.3  Push to AWS Elastic Container Registry (ECR)

3.3.1 Authenticate Docker with AWS - these steps required replacing <AWS_ACCOUNT_ID> with yours AWS account ID

Note: Make sure you have the AWS CLI installed and configured (aws configure)

authenticate_docker_with_aws.sh

Note: check and confirm the region

3.3.2 Create an ECR Repository

create_ECR_repo.sh

3.3.3 Tag the Docker Image

Find your ECR repository URL and tag the image:

tag_docker_image.sh

3.3.4 Push the Image to ECR

push_image_to_ECR.sh


4. CI/CD Pipeline for Application
- Create a GitHub Actions pipeline that automates:
-- Building the Docker image from the application source code.
-- Pushing the image to the container registry.
-- Deploying the application to the Kubernetes cluster using Kubernetes manifests.

Note: Before setting up the pipeline, make sure GitHub repository secrets configured:
* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY
* AWS_REGION (e.g., us-east-1)
* EKS_CLUSTER_NAME

4.1 Create the GitHub Actions Workflow

Create .github/workflows/deploy.yml in the repository

.github/workflows/deploy.yml

Create Kubernetes Manifests k8s/deployment.yaml and k8s/service.yaml in the repository

k8s/deployment.yaml
k8s/service.yaml

Note: If GitHub secrets defined (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) the commit of GitHub Action workflow yaml-files triggered GitHub Action automaticaly


5. Application Verification
- Verify that the application was successfully deployed using the CI/CD pipeline.
- Ensure the application is accessible via a public URL by performing a manual test.
- Document any issues or adjustments made during this step.

Vereifying deployment

After the pipeline completes, check if the application is running:

kubectl get pods
kubectl get svc

Get the external IP from the service:

kubectl get svc Hello-World-web-app-image

and try to connect to url http://<EXTERNAL-IP>/


6. Documentation & Verification
- Document your setup and approach in a `README.md` file. Include:
-- Steps to provision the infrastructure.
-- Steps to run the CI/CD pipeline.
-- Verification steps to ensure the application is accessible.
- Provide any commands or scripts used in the process.

All commands and scripts described inline and commited in the repository.

Note: 
The EXTERNAL-IP should be reachable after some delay because Load Balancer that takes a time to take effect.
For faster allocation the following annotation can be added into k8s/service.yaml : 

service.beta.kubernetes.io/aws-load-balancer-type: nlb


(Optional)
- Implement a Horizontal Pod Autoscaler (HPA) for the application and test its functionality.
- Use a benchmarking tool (e.g., Apache Bench) to simulate load and validate the HPA setup.

Adding an HPA (Horizontal Pod Autoscaler) allows the application to scale based on CPU or memory usage.
HPA requires metrics-server to collect CPU/memory usage.

Installing HPA on EKS cluster:

install_hpa.sh

Verify installation:

verify_hpa_installing.sh

Expected output:

NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   1/1     1            1           1m

Define HPA for the application Hello-World-web-app-image

hpa.yaml

Note:
minReplicas: Minimum number of pods.
maxReplicas: Maximum number of pods.
averageUtilization: If CPU usage goes above 50%, the app scales up.

Apply the hpa

apply_hpa.sh

Verify HPA running

verify_hpa_running.sh

Expected output:

NAME                             REFERENCE                              TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
Hello-World-web-app-image-hpa    Deployment/Hello-World-web-app-image   10%/50%    1         5         1          1m

Load Testing with Apache Bench (ab)
Use Apache Bench (ab) to generate load and trigger auto-scaling.

Install Apache Bench (e.g. on Ubuntu)

install_ab.sh

Run Load Test for EXTERNAL-IP by simulation 1000 requests with 50 concurrent users:

load_test.sh

Note: 
Check and update EXTERNAL-IP using: 
kubectl get svc Hello-World-web-app-image

Monitor Scaling

Check if HPA scales up:

verify_hpa_running.sh

Expected output (after load):

NAME                             REFERENCE                              TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
Hello-World-web-app-image-hpa    Deployment/Hello-World-web-app-image   60%/50%    1         5         3          2m

Check running pods:

verify_pods.sh

Expected output (more pods running):

NAME                                            READY   STATUS    RESTARTS   AGE
Hello-World-web-app-image-7df5d9c5d4-xyz123     1/1     Running   0          5m
Hello-World-web-app-image-7df5d9c5d4-abc456     1/1     Running   0          1m
Hello-World-web-app-image-7df5d9c5d4-def789     1/1     Running   0          1m
