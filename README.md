# nominatim-docker-example

nominatim-docker-example is an example for running nominatim as a dockerized app
More on nominatinum: https://nominatim.org/

## Installation

Before starting, please install Docker Desktop or minikube
For Mac, please visit https://docs.docker.com/docker-for-mac/
For Windows, please visit https://docs.docker.com/docker-for-windows/

```bash
# instructions for docker desktop
git clone https://github.com/heiyiu/nominatim-docker-example.git
cd nominatim-docker-example
docker build . --tag nominatim-docker-example:1.0
```

```bash
# instructions for minikube
git clone https://github.com/heiyiu/nominatim-docker-example.git
minikube start
minikube docker-env
# set the environment variables as provided
eval $(minikube -p minikube docker-env)
docker build . --tag nominatim-docker-example:1.0
```


## Usage

In the dockerfile, bash is already set as the entrypoint. Running the container will grant shell access as the nominatim user
```bash
docker run -it nominatim-docker-example:1.0
```

## TODO

1. Add dockerfile for Apache
2. Add dockerfile for Postgres database
3. Add docker-compose for orchestration

## General Best Practices
1. On improving build speed and decreasing image size

Switching to a smaller base os (like Alpine) for the run/app layer is a definitely an option. However, Alpine may not have all the packages available upstream if the target app includes too many dependencies. To change the base os, change the FROM lines in the Dockerfile to a differnt os. Here is an example comparing how the base images affect the final image size. 
Another good practice is to make use of multi-stage build. Multi-stage build is the process of building artifact in a build layer and then copying only the built artifact to a different layer for running. The multi-stage pattern allows us to choose different os for building and running the application, which is beneficial for legacy applications that require older packages. Since some tools required to build an application is often not required to run an application, multi-stage build will result in a smaller image.  
```bash
➜  luigi-docker-example git:(master) ✗ docker image ls
REPOSITORY                    TAG                 IMAGE ID            CREATED              SIZE
luigi-docker-example-alpine   1.0                 b83f2e8284f6        About a minute ago   169MB
luigi-docker-example          1.0                 36405ae99b6d        23 minutes ago       533MB
```
```bash
# top is the size for the final image using multi-stage build, bottom is the size of the image using single-stage build
nominatim-example             1.0                 6f1bf53a5c56   24 minutes ago   681MB
nominatim-example             1.0                 3d543f1da6f6   24 minutes ago   2.73GB
```

2. On versioning dependencies

Always provide a specific version (or range) for python package version and your base OS in your Dockerfile! I also recommend splitting out the application's python requirements file into a separate file (usually referred to as requirements.txt). We never know when a major version upgrade will break backward compactibility. Another recommendation is to move the python package installation further down in the Dockerfile to take advantage of image caching. However, running the build with the --no-cache flag occasionally is also a good idea.

3. On choosing the best base os image

While using Alpine as base image does result in a smaller image, the lack of backward compactibility can cause issues. For example, if I need to use an older version of Postgres (9.6), I'd need to go back to a much older version of Alpine. For Ubuntu, I'd simply have to compile the package manually
```dockerfile example
RUN apt-get install software-properties-common --assume-yes && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys KEY_HERE &&\
    add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" &&\
    apt-get install postgresql-9.6 --assume-yes
```

4. On variables

For build time arguments, make use of the ARG command in the Dockerfile.
For configuring environmental variables during build, make use of the ENV command.
