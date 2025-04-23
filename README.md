# Laboratório: Utilização do CRI-O

## Integrantes

- Gabriel Silveira
- Hayda Vitória Cunha
- João Vitor Scharmach
- Leonardo Júnior

---

## Introdução

Neste laboratório, utilizamos o **CRI-O**, um container runtime compatível com o padrão OCI (Open Container Initiative), projetado especificamente para funcionar com o Kubernetes. O objetivo foi compreender como o CRI-O funciona como alternativa ao Docker no ecossistema de orquestração de containers.

Mais informações estão disponíveis em: [https://cri-o.io](https://cri-o.io)

---

## Pré-requisitos

### Sistema Operacional
- Ubuntu 22.04

### Dependências

(As dependências foram gerenciadas diretamente no processo de instalação.)

---

## Instalação

### Passo a Passo da Instalação da Ferramenta

```bash
apt-get update

apt-get install -y software-properties-common curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v1.32/deb/Release.key | 
    sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/v1.32/deb/ /" | 
    sudo tee /etc/apt/sources.list.d/cri-o.list 
    
apt-get update

apt-get install -y cri-o kubelet kubeadm kubectl

systemctl start crio.service

swapoff -a
modprobe br_netfilter
sysctl -w net.ipv4.ip_forward=1

kubeadm init
```

---

## Execução de um Container

### Comandos Utilizados

#### Imagens

```bash
crictl pull <imagem>
crictl images
crictl rmi <imagem>
```

#### Pods (sandbox)

```bash
crictl runp <sandbox-config.json>
crictl stopp <pod-id>
crictl rmp <pod-id>
crictl pods
crictl inspectp <pod-id>
```

#### Containers

```bash
crictl create <pod-id> <config.json> <sandbox-config.json> 
# <pod-id>: ID do pod sandbox criado com crictl runp
# <config.json>: JSON com a configuração do container
# <sandbox-config.json>: JSON da sandbox (geralmente o mesmo usado no runp)

crictl start <container-id> # Inicia um container criado previamente.

crictl stop <container-id> # Para um container em execução.

crictl rm <container-id> # Remove um container.

crictl ps # Lista os containers em execução (use -a para todos, inclusive os parados).

crictl inspect <container-id> # Mostra detalhes da configuração do container.

crictl logs <container-id> # Exibe os logs de saída do container.

crictl exec <container-id> <comando> # Executa um comando dentro do container (semelhante ao docker exec).
```

### Capturas de Tela ou Saídas Esperadas

```bash
➜  crictl pull nginx:alpine
Image is up to date for docker.io/library/nginx@sha256:62223d644fa234c3a1cc785ee14242ec47a77364226f1c811d2f669f96dc2ac8
```

```bash
➜  crictl runp pod-config.json
0df9ef97922afa22c7eea146e9345c5b8aacb0e79524f1129fb43dfa882372d3
```

```bash
➜  crictl pods                
POD ID              CREATED             STATE               NAME                NAMESPACE           ATTEMPT             RUNTIME
0df9ef97922af       50 seconds ago      Ready               nginx-pod-crictl    default             1                   (default)
```

```bash
➜  crictl create 0df9ef97922af container-config.json pod-config.json
336033a57c3e1c34b091edb5f0bf05ed1f60c7de1e24aa4cdd8ef4ce1ba6068b
```

```bash
➜  crictl ps -a
CONTAINER           IMAGE               CREATED              STATE               NAME                     ATTEMPT             POD ID              POD                 NAMESPACE
336033a57c3e1       nginx:alpine        About a minute ago   Created             nginx-container-crictl   0                   0df9ef97922af       unknown             unknown
```

```bash
➜  crictl start 336033a57c3e1
336033a57c3e1
```

```bash
➜  crictl ps                 
CONTAINER           IMAGE               CREATED             STATE               NAME                     ATTEMPT             POD ID              POD                 NAMESPACE
336033a57c3e1       nginx:alpine        4 minutes ago       Running             nginx-container-crictl   0                   0df9ef97922af       unknown             unknown
```

```bash
➜  CONTAINER_IP=$(crictl inspect 336033a57c3e1 | jq -r '.info.runtimeSpec.annotations."io.kubernetes.cri-o.IP.0"')
➜  echo "🌐 Testando acesso ao servidor NGINX via http://$CONTAINER_IP:80"

🌐 Testando acesso ao servidor NGINX via http://10.85.0.38:80
```

```bash
➜  curl http://10.85.0.38:80
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Teste CRI-O</title>
  </head>
  <body>
    Teste CRI-O
  </body>
</html>
```

```bash
➜  crictl ps 
➜  crictl stop 336033a57c3e1
crictl stopp 0df9ef97922af
crictl rm 336033a57c3e1
crictl rmp 0df9ef97922af
```

---

## Comparação com Docker

### Diferenças Observadas

Como o CRI-O é apenas um runtime, ele não possui uma CLI própria como o Docker. É necessário utilizá-lo com ferramentas como `crictl` ou diretamente com o Kubernetes (`kubectl`). No nosso caso, usamos o `crictl`, que utiliza arquivos de configuração em JSON, ao contrário do Docker, que geralmente adota YAML.

### Limitações

A principal limitação observada foi a ausência de uma CLI como a do Docker. Isso exige conhecimento e uso de ferramentas adicionais como `crictl` ou `kubectl`.

---

## Conclusão

### Aprendizados do Laboratório

A instalação do CRI-O exigiu atenção, pois muitos tutoriais disponíveis estavam desatualizados. Cada fonte indicava um caminho diferente, mas uma vez instalado corretamente, a execução dos containers foi direta e eficaz.

Inicialmente tentamos integrá-lo com o Kubernetes, configurando um servidor NGINX, sem considerar o mapeamento de diretórios do host. Observamos que o Kubernetes abstrai bastante o uso do runtime. Um exemplo da configuração utilizada foi:

```bash
sudo kubeadm init --cri-socket=unix:///var/run/crio/crio.sock --pod-network-cidr=10.244.0.0/16 # configuração do cri-o como cri do kubernetes 

cat <<EOF > nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: $SERVICE_NAME
  namespace: $NAMESPACE
spec:
  selector:
    app: $APP_NAME
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF # arquivo de configuração

kubectl apply -f nginx-service.yaml # Execução

kubectl port-forward service/nginx-service 8080:80 -n default # Mapeamento da porta
```

![Exemplo](images/container_ip.png)
