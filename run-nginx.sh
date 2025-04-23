#!/bin/bash
set -e

# Define HTML_DIR com o diretório atual se não estiver definido
HTML_DIR="${HTML_DIR:-$(pwd)}"
echo "📁 Usando diretório HTML: $HTML_DIR"

# Verifica se o diretório existe
if [ ! -d "$HTML_DIR" ]; then
  echo "❌ Diretório $HTML_DIR não existe."
  exit 1
fi

echo "📦 Baixando imagem nginx:alpine..."
crictl pull nginx:alpine

echo "📁 Gerando arquivos de configuração..."

cat <<EOF > pod-config.json
{
  "metadata": {
    "name": "nginx-pod-crictl",
    "namespace": "default",
    "uid": "nginx-test",
    "attempt": 1
  },
  "log_directory": "/tmp",
  "linux": {}
}
EOF

cat <<EOF > container-config.json
{
  "metadata": {
    "name": "nginx-container-crictl"
  },
  "image": {
    "image": "nginx:alpine"
  },
  "command": [],
  "args": [],
  "working_dir": "/",
  "stdin": false,
  "stdin_once": false,
  "tty": false,
  "log_path": "nginx.log",
  "linux": {
    "resources": {}
  },
  "ports": [
    {
      "container_port": 80,
      "protocol": "TCP"
    }
  ],
  "mounts": [
    {
      "container_path": "/usr/share/nginx/html",
      "host_path": "$HTML_DIR",
      "read_only": false
    }
  ]
}
EOF

echo "🚀 Criando pod sandbox..."
POD_ID=$(crictl runp pod-config.json)
echo "🔧 Pod ID: $POD_ID"

echo "📦 Criando contêiner NGINX no pod..."
CONTAINER_ID=$(crictl create "$POD_ID" container-config.json pod-config.json)
echo "🔧 Container ID: $CONTAINER_ID"

echo "▶️ Iniciando contêiner..."
crictl start "$CONTAINER_ID"

echo "⌛ Aguardando alguns segundos para o NGINX iniciar..."
sleep 2

echo "Container ID: $CONTAINER_ID"
echo "Pod ID: $POD_ID"

echo "📍 Obtendo o IP do contêiner..."
# Obtendo o IP do contêiner
CONTAINER_IP=$(crictl inspect "$CONTAINER_ID" | jq -r '.info.runtimeSpec.annotations."io.kubernetes.cri-o.IP.0"')

if [ "$CONTAINER_IP" == "null" ]; then
  echo "⚠️ Não foi possível obter o IP do contêiner."
else
  echo "✅ O IP do contêiner é: $CONTAINER_IP"
  echo "🌐 Testando acesso ao servidor NGINX via http://$CONTAINER_IP:80"

  # Testando acesso ao servidor NGINX
  curl -s http://$CONTAINER_IP:80 || echo "⚠️ Erro ao acessar o servidor NGINX."
  
  # Se você já tiver um arquivo HTML específico dentro do contêiner NGINX, você pode especificar o caminho
  # como exemplo: curl -s http://$CONTAINER_IP:80/index.html
fi
