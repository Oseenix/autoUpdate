FROM centos:6.6

RUN shellDepences='expect openssh-clients' \
        && yum install -y $shellDepences

WORKDIR /opt/src

CMD ["/bin/bash"]

