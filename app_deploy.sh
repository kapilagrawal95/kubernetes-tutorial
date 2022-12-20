# Requires helm -- brew install helm -- version 3
# Requires minikube -- brew install minikube -- run the hyperkit version and not docker version
# Requires sudo permissions 
# Requires gettext and envsubst -- brew install gettext
###________MINIKUBE_________###
cd "$(dirname "$0")"
# minikube start --driver=hyperkit --disable-optimizations
###_________MINIKUBE_________###
# minikube addons enable metrics-server
# minikube addons enable ingress

export MEMORY="100Mi"
export CPU="33m"
export JWT_SECRET="mysecret"
export REPLICAS=3
helm install rc redis/redis-cluster
export REDIS_PASSWORD=$(kubectl get secret --namespace "default" rc-redis-cluster -o jsonpath="{.data.redis-password}" | base64 --decode)
# helm install ingress-nginx ingress-nginx/
envsubst < web.yaml | kubectl create -f -
kubectl expose deployment web --type=NodePort --port=80 --name web
envsubst < user.yaml | kubectl create -f -
kubectl apply -f user-service.yaml
envsubst < match.yaml | kubectl create -f -
kubectl expose deployment match --type=NodePort --port=80 --name match
envsubst < chat.yaml | kubectl create -f -
kubectl apply -f chat-service.yaml
kubectl create -f jaeger.yaml 
kubectl apply -f jaeger-service.yaml
# creating ingress nginx
kubectl create -f ingress.yaml
envsubst < uploader.yaml | kubectl create -f -
kubectl expose deployment uploader --type=NodePort --port=80 --name uploader
echo "$(minikube ip) hello-world.info" | sudo tee -a /etc/hosts
# Don't forget to set ingress resources using the edit command:
# kubectl edit deployment/ingress-nginx-controller