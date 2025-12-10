# README
## How to run
### if use docker run
* Create network
```
docker network create rails8_demo-network
```
* Start postgres container
```
docker run -d \                                                                                                                                                                                                                                                        130 ↵
  --name postgres-db \
  --network rails8_demo-network \
  -e POSTGRES_USER=rails8-demo \
  -e POSTGRES_PASSWORD=123456 \
  -e POSTGRES_DB=rails8-demo \
  postgres:16

```
* Start rails server
```
docker run --rm -p 3001:3000 -e RAILS_MASTER_KEY=23ca89ce16309eaed370f57271a91067 -e RAILS_ENV=production -e DATABASE_URL=postgresql://rails8-demo:123456@postgres-db/rails8-demo --network rails8_demo-network --name rails8_demo harbor.ky2020.shop/rails8_demo:1.0.3 ./bin/rails server
```

* Open http://localhost:3001 to check page
