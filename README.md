# Fenwave Helm Charts

https://fenleap.atlassian.net/wiki/x/AQDqCQ

##  Vue d'ensemble

##  Prérequis

### Infrastructure

- **Cluster GKE** avec Gateway API activé (Kubernetes 1.28+)
- **kubectl** configuré et connecté au cluster
- **Helm 3.x** installé

### Ressources Minimales

- **Nodes** : 2+ (type `e2-standard-4` ou `n2-standard-4`)
- **CPU** : 8+ vCPUs
- **Mémoire** : 16+ GB RAM
- **Stockage** : 50+ GB

### Outils Requis

```bash
# Vérifier les versions
kubectl version --short
helm version --short
gcloud version
```

### Installation des Outils

Si vous n'avez pas encore installé les outils nécessaires :

```bash
# Installer le plugin d'authentification GKE
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin -y

# Installer Helm
sudo snap install helm --classic

# Vérifier les installations
helm version --short
gke-gcloud-auth-plugin --version
```
---

## 🚀 Installation

### Étape 1 : Se Connecter au Cluster

```bash
# Récupérer les credentials
gcloud container clusters get-credentials fenwave-gke-dev \
  --region=europe-west1 \
  --project=YOUR_GCP_PROJECT_ID

# Vérifier la connexion
kubectl get nodes
kubectl get namespaces
```

### Étape 2 : Vérifier que le Gateway est Créé

```bash
# Vérifier le namespace gateway-system
kubectl get namespace gateway-system

# Vérifier le Gateway
kubectl get gateway -n gateway-system

# Obtenir les détails
kubectl describe gateway default-gateway -n gateway-system

# Récupérer l'IP du Load Balancer
kubectl get gateway default-gateway -n gateway-system \
  -o jsonpath='{.status.addresses[0].value}'
```

**Exemple de sortie** :
```
NAME              CLASS                             ADDRESS         PROGRAMMED   AGE
default-gateway   gke-l7-regional-external-managed  34.123.45.67    True         5m
```

### Étape 3 : Installer le Helm Chart

aller au dossier de helm 

```bash

# Créer le namespace
kubectl create namespace fenwave

# Installer le chart
helm install fenwave . \
  --namespace fenwave \
  --values values.yaml \
  --timeout 10m

# Suivre l'installation
kubectl get pods -n fenwave --watch
```

### Étape 4 : Vérifier le Déploiement

```bash
# Vérifier les pods
kubectl get pods -n fenwave

# Vérifier les services
kubectl get svc -n fenwave

# Vérifier les HTTPRoutes
kubectl get httproutes -n fenwave

# Voir les notes d'installation
helm status fenwave -n fenwave
```

**Exemple de sortie** :
```
NAME                                READY   STATUS    RESTARTS   AGE
fenwave-fenwave-backstage-xxx-xxx   1/1     Running   0          2m
fenwave-postgresql-0                1/1     Running   0          2m
fenwave-argocd-server-xxx-xxx       1/1     Running   0          2m
fenwave-grafana-xxx-xxx             1/1     Running   0          2m
```

---

##  Configuration

### Configuration Minimale (values.yaml)

```yaml
# Gateway API Configuration
gateway:
  enabled: true
  gatewayName: "default-gateway"
  gatewayNamespace: "gateway-system"
  listenerName: "http"  # ou "https" si SSL activé
  
  # Hostnames pour chaque service
  hostnames:
    backstage: "backstage.example.com"
    argocd: "argocd.example.com"
    argoWorkflows: "argo-workflows.example.com"
    prometheus: "prometheus.example.com"
    grafana: "grafana.example.com"
  
  gcp:
    region: "europe-west1"
    ssl:
      enabled: false  # Mettre true pour HTTPS
      certificateName: "fenwave-wildcard"

# Backstage Configuration
backstage:
  enabled: true
  replicaCount: 2
  image:
    repository: your-registry/backstage
    tag: "latest"
  service:
    type: ClusterIP
    port: 7007

# PostgreSQL Configuration
postgresql:
  enabled: true
  auth:
    username: "backstage_user"
    password: "your-secure-password"
    database: "backstage_db"
  primary:
    persistence:
      size: 20Gi

# ArgoCD Configuration
argocd:
  enabled: true
  server:
    service:
      type: ClusterIP
    ingress:
      enabled: false

# Argo Workflows Configuration
argo-workflows:
  enabled: true
  server:
    enabled: true

# Prometheus Configuration
prometheus:
  enabled: true

# Grafana Configuration
grafana:
  enabled: true
  adminPassword: "admin"
```

### Personnaliser les Hostnames

Éditez `values.yaml` :

```yaml
gateway:
  hostnames:
    backstage: "backstage.votre-domaine.com"
    argocd: "argocd.votre-domaine.com"
    grafana: "grafana.votre-domaine.com"
    # ... autres services
```

Puis mettez à jour :

```bash
helm upgrade fenwave . \
  --namespace fenwave \
  --values values.yaml
```

---

##  Accès aux Services

### Récupérer l'IP du Load Balancer

```bash
export GATEWAY_IP=$(kubectl get gateway default-gateway -n gateway-system \
  -o jsonpath='{.status.addresses[0].value}')

echo "Gateway Load Balancer IP: ${GATEWAY_IP}"
```

### Configurer le DNS

**Option 1 : DNS Production (Recommandé)**

Créez des enregistrements DNS A ou CNAME :

```bash
# Exemple avec Google Cloud DNS
export DNS_ZONE="votre-zone-dns"

# Créer des enregistrements A
gcloud dns record-sets create backstage.example.com. \
  --zone="${DNS_ZONE}" \
  --type="A" \
  --ttl="300" \
  --rrdatas="${GATEWAY_IP}"

gcloud dns record-sets create argocd.example.com. \
  --zone="${DNS_ZONE}" \
  --type="A" \
  --ttl="300" \
  --rrdatas="${GATEWAY_IP}"

# Répéter pour les autres services...
```

**Option 2 : /etc/hosts pour Tests Locaux**

```bash
sudo tee -a /etc/hosts <<EOF
${GATEWAY_IP} backstage.example.com
${GATEWAY_IP} argocd.example.com
${GATEWAY_IP} argo-workflows.example.com
${GATEWAY_IP} grafana.example.com
${GATEWAY_IP} prometheus.example.com
EOF
```

### URLs des Services

Une fois le DNS configuré :

| Service | URL | Credentials |
|---------|-----|-------------|
| Backstage | http://backstage.example.com | - |
| ArgoCD | http://argocd.example.com | `admin` / (voir ci-dessous) |
| Argo Workflows | http://argo-workflows.example.com | - |
| Grafana | http://grafana.example.com | `admin` / `admin` |
| Prometheus | http://prometheus.example.com | - |

### Obtenir le Mot de Passe ArgoCD

```bash
kubectl get secret argocd-initial-admin-secret \
  -n fenwave \
  -o jsonpath="{.data.password}" | base64 -d
echo
```

### Tester les Services (avant DNS)

```bash
# Tester Backstage
curl -H "Host: backstage.example.com" http://${GATEWAY_IP}/healthcheck

# Tester ArgoCD
curl -H "Host: argocd.example.com" http://${GATEWAY_IP}/

# Tester Grafana
curl -H "Host: grafana.example.com" http://${GATEWAY_IP}/api/health
```

---

## 🔄 Mise à Jour

```bash
# Mettre à jour le chart
helm upgrade fenwave . \
  --namespace fenwave \
  --values values.yaml \
  --timeout 10m

# Vérifier le statut
helm status fenwave -n fenwave

# Rollback si nécessaire
helm rollback fenwave -n fenwave
```

---

## 🗑️ Désinstallation

```bash
# Désinstaller le Helm release
helm uninstall fenwave --namespace fenwave

# Supprimer le namespace
kubectl delete namespace fenwave

# (Optionnel) Supprimer le Gateway
kubectl delete gateway default-gateway -n gateway-system

# (Optionnel) Supprimer les DNS records
gcloud dns record-sets delete backstage.example.com. \
  --zone="${DNS_ZONE}" --type=A
```

---

## 🔧 Troubleshooting

### 1. Pods ne démarrent pas

**Symptôme** : Pods en `Pending` ou `CrashLoopBackOff`

```bash
# Vérifier les pods
kubectl get pods -n fenwave

# Voir les détails
kubectl describe pod <pod-name> -n fenwave

# Voir les logs
kubectl logs <pod-name> -n fenwave
```

**Solutions courantes** :
- Vérifier les ressources du cluster (CPU/Mémoire)
- Vérifier les secrets (ECR credentials, passwords)
- Vérifier les volumes persistants

### 2. Gateway retourne 404

**Symptôme** : `curl` retourne `HTTP/1.1 404 Not Found`

```bash
# Vérifier que les HTTPRoutes sont créés
kubectl get httproutes -n fenwave

# Vérifier les détails d'un HTTPRoute
kubectl describe httproute fenwave-backstage -n fenwave

# Vérifier que le hostname correspond
kubectl get httproute fenwave-backstage -n fenwave -o yaml | grep hostname
```

**Solution** : Vérifier que le header `Host` correspond au hostname configuré.

### 3. Services retournent 503

**Symptôme** : `curl` retourne `HTTP/1.1 503 Service Unavailable`

```bash
# Vérifier que les pods sont Running
kubectl get pods -n fenwave

# Vérifier les services
kubectl get svc -n fenwave

# Vérifier les endpoints
kubectl get endpoints -n fenwave
```

**Solution** : Attendre que les pods soient `Ready` et les health checks passent.

### 4. DNS ne résout pas

**Symptôme** : `nslookup` ne retourne pas l'IP du Gateway

```bash
# Tester la résolution DNS
nslookup backstage.example.com

# Vérifier l'IP du Gateway
kubectl get gateway default-gateway -n gateway-system
```

**Solution** :
- Vérifier que les enregistrements DNS sont créés
- Attendre la propagation DNS (jusqu'à 5 minutes)
- Utiliser `/etc/hosts` pour tester localement

### 5. HTTPRoute ne s'attache pas au Gateway

**Symptôme** : HTTPRoute Status montre `Accepted: False`

```bash
# Vérifier le statut
kubectl describe httproute fenwave-backstage -n fenwave

# Vérifier que le Gateway existe
kubectl get gateway default-gateway -n gateway-system

# Vérifier le namespace
kubectl get httproute fenwave-backstage -n fenwave -o yaml | grep namespace
```

**Solution** : Vérifier que `gatewayName` et `gatewayNamespace` sont corrects dans `values.yaml`.
