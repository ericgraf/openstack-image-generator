# openstack-image-generator
Goal is to generate openstack images in cluster and upload to glance.


# set alias

alias openstack="docker run --rm -it   -e OS_AUTH_URL=$OS_AUTH_URL   -e OS_PROJECT_ID=$OS_PROJECT_ID  -e OS_PROJECT_NAME=$OS_PROJECT_NAME   -e OS_USER_DOMAIN_NAME=$OS_USER_DOMAIN_NAME   -e OS_USERNAME=$OS_USERNAME   -e OS_PASSWORD=$OS_PASSWORD   -e OS_REGION_NAME=$OS_REGION_NAME   -e OS_INTERFACE=$OS_INTERFACE   -e OS_IDENTITY_API_VERSION=$OS_IDENTITY_API_VERSION openstack"