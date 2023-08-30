for RYU
```
 sudo docker build -f Dockerfile.Ryu -t osrg/ryu:latest --network host .
```
for SPGWU
```
sudo docker build -f Dockerfile.SPGWU -t oaisoftwarealliance/oai-spgwu-tiny:v1.5.1  --network host .  
```
for UBUNTU
```
sudo docker build -f Dockerfile.Ubuntu -t ubuntu:latest --network host . 
```

for Banking APP
```
sudo docker build -fDockerfile.Bankapp -t banking-app --network host .
```
