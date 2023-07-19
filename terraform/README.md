## Init
gcloud init

Criando Iam
gcloud iam service-accounts create servicemonks

Adicionando police
gcloud projects add-iam-policy-binding 705455503469 --member="serviceAccount:servicemonks@precise-window-392617.iam.gserviceaccount.com" --role="roles/owner"

Criando credencials
gcloud iam service-accounts keys create cred.json --iam-account=servicemonks@precise-window-392617.iam.gserviceaccount.com
Criado um arquivo cred.json o comando abaixo iremos adicionar export com as credencias para poder utilizar em nosso terminal.

export GOOGLE_APPLICATION_CREDENTIALS="cred.json"