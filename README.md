# aws-eks-gitops

EKS on AWS, built with Terraform. Once the cluster is up, Argo CD takes over and manages everything inside it from this repo.

There are two environments, dev and staging, each with its own VPC, EKS cluster and Argo CD.

## Layout

`terraform/bootstrap`: the S3 bucket for Terraform state.

`terraform/modules/cluster`: the VPC, the EKS cluster, and the Helm releases that need to happen before Argo CD can take over (Cilium, Argo CD itself, and a root Application).

`terraform/envs/dev` and `terraform/envs/staging`: call that module with a different name and CIDR.

`gitops/clusters/<env>`: what the root Application syncs. Traefik comes straight from its Helm chart, Keycloak and hello go through the Kustomize overlays in `gitops/apps`.

`hello`: a tiny Go service that exists to prove a commit actually makes it all the way to a running pod.

## Networking

Cilium runs in chaining mode on top of the AWS VPC CNI, so pods still get VPC IPs and Cilium adds network policies and Hubble on top.

Both `hello` and `keycloak` ship with a default deny `NetworkPolicy`, ingress is only allowed from Traefik (and from Argo CD for Keycloak, for the OIDC token exchange), egress is only DNS.

Traefik is the ingress controller and gets an NLB. Apps are exposed as `<app>.<env>.example.com`, so change `base_domain` in the env files and the overlay hosts to your own domain, then point a wildcard record at the NLB. No TLS yet, it's plain http.

## Running it

The bucket name in `terraform/bootstrap/variables.tf` and the `backend.tf` files has to be globally unique, pick your own before the first apply.

```sh
cd terraform/bootstrap
terraform init
terraform apply

cd ../envs/dev
terraform init
terraform apply
aws eks update-kubeconfig --name gitops-dev --region eu-west-3
```

## Secrets

Create these once the cluster is up with the same client secret in both namespaces:

```sh
kubectl create namespace keycloak
kubectl -n keycloak create secret generic keycloak-admin --from-literal=password=<admin password>
kubectl -n keycloak create secret generic keycloak-argocd-client --from-literal=clientSecret=<client secret>

kubectl -n argocd create secret generic keycloak-oidc --from-literal=clientSecret=<client secret>
kubectl -n argocd label secret keycloak-oidc app.kubernetes.io/part-of=argocd
```

Keycloak imports the `platform` realm from `gitops/apps/keycloak/base/platform-realm.json` on startup. Anyone in the `platform-admins` group is admin in Argo CD, everyone else gets read only access.

Keycloak runs in dev mode with no real database, so users created by hand are gone as soon as the pod restarts. The realm itself comes back fine since it lives in git. Okay for this lab.

## CI

`terraform.yml` checks formatting, validates every root module, and runs a Trivy config scan.

`hello.yml` runs the Go tests, builds the image, scans it with Trivy, and pushes it to GHCR when something lands on main.

## Tearing down

The NLB is created by Kubernetes, not Terraform, and it blocks the VPC deletion if it's still around. Remove it first:

```sh
kubectl -n argocd delete application root traefik
kubectl -n traefik delete service traefik
```

Then:

```sh
cd terraform/envs/dev
terraform destroy
```
