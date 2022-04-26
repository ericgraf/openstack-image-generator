buildimage:
  docker build . -t capo-image
  docker run -it --rm --network="host" \
  --device=/dev/kvm \
  -v `pwd`/output:/home/imagebuilder/output/ \
  -v `pwd`/cache:/home/imagebuilder/packer_cache/ \
  capo-image build-qemu-ubuntu-2004

openstackcli:
  echo "test"
  docker build ./openstack-cli -t openstack
  docker run --rm -it \
  -e OS_AUTH_URL=$OS_AUTH_URL \
  -e OS_PROJECT_ID=$OS_PROJECT_ID\
  -e OS_PROJECT_NAME=$OS_PROJECT_NAME \
  -e OS_USER_DOMAIN_NAME=$OS_USER_DOMAIN_NAME \
  -e OS_USERNAME=$OS_USERNAME \
  -e OS_PASSWORD=$OS_PASSWORD \
  -e OS_REGION_NAME=$OS_REGION_NAME \
  -e OS_INTERFACE=$OS_INTERFACE \
  -e OS_IDENTITY_API_VERSION=$OS_IDENTITY_API_VERSION \
  openstack


