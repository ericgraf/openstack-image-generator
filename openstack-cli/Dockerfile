FROM python:3

WORKDIR /openstack

COPY requirements.txt ./

RUN /usr/local/bin/python -m pip install --upgrade pip
RUN pip3 install \
  --trusted-host pypi.org \
  --trusted-host files.pythonhosted.org \
  --no-cache-dir -r requirements.txt

#ENV OS_AUTH_URL 
#ENV OS_PROJECT_ID
#ENV OS_PROJECT_NAME
#ENV OS_USER_DOMAIN_NAME
#ENV OS_USERNAME
#ENV OS_PASSWORD
#ENV OS_REGION_NAME
#ENV OS_INTERFACE
#ENV OS_IDENTITY_API_VERSION 

CMD [ "openstack", "versions", "show" ]