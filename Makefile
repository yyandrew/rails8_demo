# 默认版本号，如果在命令行不指定，就使用 latest
VERSION ?= latest
IMAGE = localhost:5000/rails8_demo

.PHONY: deploy

deploy:
	@echo "🚀 Building image $(IMAGE):$(VERSION)..."
	docker build -t $(IMAGE):$(VERSION) .

	@echo "📦 Pushing image to local registry..."
	docker push $(IMAGE):$(VERSION)

	@echo "🔔 Notifying Keel to update Pods..."
	curl -s -X POST -H "Content-Type: application/json" \
	  -d '{"name": "k3d-myregistry.$(IMAGE)", "tag": "$(VERSION)"}' \
	  http://localhost:9300/v1/webhooks/native
	@echo "\n✅ Deployment triggered!"
