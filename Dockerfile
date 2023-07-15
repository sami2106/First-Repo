FROM registry.redhat.io/devspaces/udi-rhel8:latest
#FROM sami2106/ubuntu:20.04 as runner
#FROM craas-mvp.bcsv.cloud.intranet.bund.de/bmf-kiss/ubuntu:20.04 as runner

ARG DEBIAN_FRONTEND=noninteractive

ENV PATH="/home/user/.venv/bin:/home/user/.venv/local/bin:$PATH" 
ENV MPLLOCALFREETYPE=1

RUN mkdir -p /usr/local/share/ca-certificates/extra
COPY /ca.cer /usr/local/share/ca-certificates/extra/
#COPY certs/*.crt /usr/local/share/ca-certificates/extra/

RUN apt update && apt upgrade -y \
&& apt-get install software-properties-common -y \
&& add-apt-repository ppa:deadsnakes/ppa -y \
&& apt-get update \
&& apt-get purge python3.8 -y\
&& apt-get --purge remove python3.8 -y \
&& apt-get install --no-install-recommends -y nodejs npm python3.9 python3.9-distutils python3.9-dev python3.9-venv python3.8-venv python3-pip python3-wheel build-essential libatlas-base-dev libblas-dev liblapack-dev gfortran rustc libfreetype6-dev ca-certificates\
&& apt-get clean && apt-get autoremove -y && update-ca-certificates\
&& rm -rf /var/lib/apt/lists/* \
# add user and configure it
&&  useradd -u 1000 -G sudo,root -d /home/user --shell /bin/bash -m user \ 
# Setup $PS1 for a consistent and reasonable prompt
&&  echo "export PS1='\W \`git branch --show-current 2>/dev/null | sed -r -e \"s@^(.+)@\(\1\) @\"\`$ '" >> "${HOME}"/.bashrc \
# Change permissions to let any arbitrary user
&&  mkdir -p /projects \
&&  for f in "${HOME}" "/etc/passwd" "/etc/group" "/projects"; do echo "Changing permissions on ${f}" && chgrp -R 0 ${f} && chmod -R g+rwX ${f}; done \
# Generate passwd.template
&&  cat /etc/passwd | sed s#user:x.*#user:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g  > ${HOME}/passwd.template \
&&  cat /etc/group | sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g > ${HOME}/group.template \
# create and activate virtual environment
# using final folder name to avoid path issues with packages
&& python3.9 -m venv /home/user/.venv \
# install requirements
&& pip3 install --no-cache-dir  --upgrade pip \
&& pip3 install --no-cache-dir wheel \
#USER user
&& cd /home/user; /usr/bin/python3 -m venv .venv

# install base packages
COPY ./requirements.txt /home/user/
RUN cd /home/user && pip install -r requirements.txt \

#make sure that an user can write in $HOME
&& mkdir -p /home/user && chgrp -R 0 /home && chmod -R g=u /home

ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /projects
CMD tail -f /dev/null
# test
