FROM rockylinux/rockylinux:8.5 as build_stage

# set user env
ENV USERHOME=/srv/nominatim
ENV NOMINATIM_VER=4.0.0
# refresh package list
RUN dnf update -y
# enable epel directory
RUN dnf install -y epel-release
# disable default postgres and enable postgres 12
RUN dnf -qy module disable postgresql
RUN dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
ENV PATH=/usr/pgsql-12/bin:$PATH
RUN dnf install -y --enablerepo=powertools \
  postgresql12-server postgresql12-contrib postgresql12-devel postgis30_12 \
  wget cmake make gcc gcc-c++ libtool policycoreutils-python-utils \
  llvm-toolset ccache clang-tools-extra \
  php-pgsql php php-intl php-json libpq-devel \
  bzip2 bzip2-devel proj-devel boost-devel \
  python3-pip python3-setuptools python3-devel python3-psycopg2 \
  expat-devel zlib-devel libicu-devel redhat-rpm-config
# building nominatim
WORKDIR $USERHOME
RUN wget https://nominatim.org/release/Nominatim-$NOMINATIM_VER.tar.bz2 \
  && tar xf Nominatim-$NOMINATIM_VER.tar.bz2
RUN rm Nominatim-$NOMINATIM_VER.tar.bz2
RUN mkdir $USERHOME/build
WORKDIR $USERHOME/build
RUN cmake $USERHOME/Nominatim-4.0.0
RUN make
RUN make install
# copy requirements file from local
COPY pypi_requirements.txt $USERHOME/
# build entrypoint file and set permission
# RUN touch /docker-entrypoint.sh
# RUN chmod +x /docker-entrypoint.sh

FROM rockylinux/rockylinux:8.5 as app_stage
# user env
ENV APPPATH=/srv/nominatim
# install python libraries
RUN dnf update -y
RUN dnf install -y libicu-devel gcc gcc-c++ \
  python3-pip python3-setuptools python3-devel python3-psycopg2
# add nominatim user
RUN useradd -s /bin/bash -m nominatim
# copy from build stage to app stage
COPY --from=build_stage $APPPATH $APPPATH
RUN chmod a+x $APPPATH
# Switch to nominatim user
USER nominatim
RUN python3 -m pip install -r $APPPATH/pypi_requirements.txt --user

ENTRYPOINT ["/bin/bash"]
EXPOSE 5432
EXPOSE 8080
