# Caso Google Cloud - Monks.
### O que usamos? :
- Nginx base para hello world
- Nginx Ingress helm
- Docker
- Kubernetes
- Helm
- Terraform
- GitHub Actions
- GKE (Google Kubernetes Engine)
- GCR (Google Container Registry)

<p>
<img src="https://w7.pngwing.com/pngs/816/934/png-transparent-nginx-hd-logo-thumbnail.png" height="36" width="36" >
<img src="https://seeklogo.com/images/D/docker-logo-6D6F987702-seeklogo.com.png" height="36" width="36" >
<img src="https://juststickers.in/wp-content/uploads/2018/11/kubernetes-wordmark.png"  height="36" width="36" >
<img src="https://helm.sh/img/helm.svg"  height="36" width="36" >
<img src="https://www.gend.co/hs-fs/hubfs/gcp-logo-cloud.png?width=730&name=gcp-logo-cloud.png" height="36" >
<img src="https://miro.medium.com/v2/resize:fit:900/0*SM6gpc8GRfy65MmK.png" height="36" >
<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/Terraform_Logo.svg/1280px-Terraform_Logo.svg.png" height="36" >
</p>

# Sobre caso
Utilizamos codigo terraform para codar toda arquitetura, abaixo está cada ingrediente utiliza. Rs
* Criado IAM´s para utilizarmos CI/CD e permissoes de dono para testes de deploys.
* Criado bucket para terraform via github action.
* Criado uma VPC com Subnet.
* Criado rota com NAT para saidas de subnets VPC.
* Criado uma Instancia para utiliza IAP para fazer um tunel de acesso caso necessite. (OBS: Pois não criamos uma VPN.) 
* Criado um Cluster GKE com Nodes com rede privada.
* Deploy via terraform, kubernetes, helm.
* Criado modulo para fazer deploy com helm do nginx ingress e do app que criamos. (Voce pode encontrar na pasta terraform/modules/).

# Passo a Passo
- [x] Iniciar gcloud.
```console
gcloud init
```

- [x] Criando IAM
```console
gcloud iam service-accounts create servicemonks
```

- [x] GCP Project
```console
gcloud projects describe project-monks
```

name: monks
projectId: project-monks
projectNumber: '534232678406'

- [x] Criando bucket
```console
gcloud storage buckets create gs://monks-gk
```

- [x] Adicionando police
```console
gcloud projects add-iam-policy-binding 534232678406 --member="serviceAccount:servicemonks@project-monks.iam.gserviceaccount.com" --role="roles/owner"
```
Acima criamos iam com permissões de dono. (OBS: intuito aqui é uma breve demonstração então não focaremos em segurança com IAM.)

- [x] Criando credencials para utilizar localmente.
```console
gcloud iam service-accounts keys create cred.json --iam-account=servicemonks@project-monks.iam.gserviceaccount.com
```

```console
O comando abaixo iremos adicionar export com as credencias para poder utilizar em nosso terminal.
export GOOGLE_APPLICATION_CREDENTIALS="cred.json"
```

# Abaixo iremo criar IAM para utilizar CI/CD do github action.
[Source](https://medium.com/@irem.ertuerk/iac-with-github-actions-for-google-cloud-platform-bc28f1c4b0c7)

- [x] Criar um workload identity pools
```console
gcloud iam workload-identity-pools create "k8s-git" --project="project-monks" --location="global" --display-name="k8s"
```

- [x] Criar IAM k8s-git para pools
```console
gcloud iam workload-identity-pools providers create-oidc "k8s-provider" --project="project-monks"  --location="global" --workload-identity-pool="k8s-git" --display-name="k8s provider" --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud" --issuer-uri="https://token.actions.githubusercontent.com"
```

- [x] Relação com IAM servicemonks e k8s IAM.
```console
gcloud iam service-accounts add-iam-policy-binding "servicemonks@project-monks.iam.gserviceaccount.com" --project="project-monks" --role="roles/owner" --member="principalSet://iam.googleapis.com/projects/534232678406/locations/global/workloadIdentityPools/k8s-git/attribute.repository/geantrevisan/gcp-gke"
```
- [x] Adicionar permisssão token
```console
gcloud iam service-accounts add-iam-policy-binding "servicemonks@project-monks.iam.gserviceaccount.com" --project="project-monks" --role="roles/iam.serviceAccountTokenCreator" --member=serviceAccount:servicemonks@project-monks.iam.gserviceaccount.com
```

- [x] Workflows
```yaml
name: Deploy to kubernetes
on:
  push:
    branches:
      - "main"

env:
  GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  TF_STATE_BUCKET_NAME: ${{ secrets.GCP_TF_STATE_BUCKET }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      IMAGE_TAG: ${{ github.sha }}

    permissions:
      contents: 'read'
      id-token: 'write'
    
    steps:
    - uses: 'actions/checkout@v3'

    # Login com GCP.
    - id: 'auth'
      name: 'Login na Google Cloud'
      uses: 'google-github-actions/auth@v1'
      with:
        token_format: 'access_token'
        workload_identity_provider: 'projects/534232678406/locations/global/workloadIdentityPools/k8s-git/providers/k8s-provider'
        service_account: 'servicemonks@project-monks.iam.gserviceaccount.com'
        
    # Instalar gcloud SDK
    - name: 'Intalling GCloud SDK'
      uses: 'google-github-actions/setup-gcloud@v1'

    # Login GCP para enviar docker image.
    - name: docker auth
      run: gcloud auth configure-docker
    
    # Mostra conta autenticada.
    - run: gcloud auth list

    # Build image e envia.
    - name: Build e push docker image
      run: |
        docker build -t us.gcr.io/$GCP_PROJECT_ID/appimage:$IMAGE_TAG .
        docker push us.gcr.io/$GCP_PROJECT_ID/appimage:$IMAGE_TAG
      working-directory: ./app

      # Configura Terraform
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2

      # Terraform Init
    - name: Terraform init
      run: terraform init -backend-config="bucket=$TF_STATE_BUCKET_NAME" -backend-config="prefix=test"
      working-directory: ./terraform

      # Terraform Plan
    - name: Terraform Plan
      run: |
        terraform plan \
        -var="region=us-central1" \
        -var="project=$GCP_PROJECT_ID" \
        -var="container_image=us.gcr.io/$GCP_PROJECT_ID/appimage:$IMAGE_TAG" \
        -out=PLAN
      working-directory: ./terraform

      # Terraform Apply
    - name: Terraform Apply
      run: terraform apply PLAN
      working-directory: ./terraform
```

- [x] Acessar repositorio e crie sua secrets.
Repo > Settings > Secrets and variables > Action.
Iremo clicar no botão New repository secret
Primeiro iremos colocar o nome de GCP_PROJECT_ID e no campo Secret o id do projeto da GCP.
O mesmo para GCP_TF_STATE_BUCKET so que no campo secret colocaremos o bucket criado anteriormente.

# Terraform
Criei todo codigo do terraforma com comentarios nos .tf. creio que ficou claro para entendimento.

# Links de referencias.

[Criar IAM para repo github](https://medium.com/@irem.ertuerk/iac-with-github-actions-for-google-cloud-platform-bc28f1c4b0c7)
[Terraform node](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool.html)
[Terraform script instancia](https://fabianlee.org/2021/05/28/terraform-invoking-a-startup-script-for-a-gce-google_compute_instance/)
[Terraform instancia](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)
[Terraform modules](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
[Terraform provider](https://registry.terraform.io/providers/Twingate/twingate/latest/docs/guides/gke-helm-provider-deployment-guide)
[Terraform vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network)
[Terraform subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork)
[Terraform GKE](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster)
[Terraform anddress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address.html)
[Terraform nat/firewall](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat)
[Terraform nat route](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat)
[Terraform nat gateway](https://registry.terraform.io/modules/terraform-google-modules/cloud-nat/google/1.4.0?utm_content=documentLink&utm_medium=Visual+Studio+Code&utm_source=terraform-ls)