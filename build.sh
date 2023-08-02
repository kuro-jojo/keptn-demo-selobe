#!/bin/sh

# Build and push v0.1.0
cd v0.1.0
docker build . -t kuro08/zero:0.1.0 && docker push kuro08/zero:0.1.0
cd ..

# Build and push v0.2.0
cd v0.2.0
docker build . -t kuro08/zero:0.2.0 && docker push kuro08/zero:0.2.0
cd ..

# Build and push v0.3.0
cd v0.3.0
docker build . -t kuro08/zero:0.3.0 && docker push kuro08/zero:0.3.0
cd ..

tar -czvf zeroservice.tgz zeroservice