# Argus production deployment examples using Docker

This repository contains a simple, but complete Argus deployment example using
[Docker Compose](https://docs.docker.com/compose/).

## TL;DR

1. Type `docker compose up` (depending on your system, the command may be
   `docker-compose` instead of `docker compose`)

2. After getting the docker compose environment up and running, you must create
   your initial admin user, thus:

   ```
   docker compose exec api django-admin initial_setup
   ```

   This should create the `admin` user and print a randomly generated password for
   that user. Use this on your first login to Argus.

3. Browse http://localhost/

## More details

### Services

This docker compose environment brings up four services:

1. [The main Argus API backend](https://github.com/Uninett/Argus) (http port 8000)
2. [The main Argus frontend application](https://github.com/Uninett/Argus-frontend) (http port 80)
3. A PostgreSQL server for persistent storage of Argus data
4. A Redis server that acts as a message broker for websocket communication
   between the frontend and backend components.

### Configuration

Minimally, you need to alter the configuration in the [`.env`](./.env) file to suit your
setup (including generating the keys/random strings that should be unique for
your site!).

If you are just testing on `localhost`, the existing settings are mostly fine. Be
aware that the complete application consists of *2 web sites*:

1. The frontend, pre-configured at build time to access the backend at the
   configured domain name.
2. The backend API server.

#### Changing port numbers

By default, the frontend service (which you normally visit using your browser)
is configured to bind to your system's port *80*, while the backend is bound to
port *8000*. If you, for some reason, wish to change this, set the
`ARGUS_FRONTEND_PORT` and `ARGUS_BACKEND_PORT` variables in [`.env`](./.env).

### SSL

This setup does not include SSL protection of the web sites. This is absolutely
necessary for production deployment. If you want to deploy to production user
Docker Compose, we suggest looking at including
https://github.com/nginx-proxy/acme-companion into your `docker-compose.yml`
(or maybe preferably, into `docker-compose.override.yml`).

### Troubleshooting on MacOS

The images referred to by `docker-compose.yml` are hosted as GitHub packages on
the `ghcr.io` domain.  If you're attempting to run this Docker Compose
environment on Docker Desktop for MacOS, you may have problems pulling these
images. If your are getting messages about being `denied` the pull operations,
you must go into the Docker Desktop settings menu. Under the "Beta features"
tab, you must enable the option "Use containerd for pulling and storing
images".


### What is Argus, anyway?

You can read more about Argus itself at the [Argus homepage](https://network.geant.org/argus/) or in the [official Argus documentation](https://argus-server.readthedocs.io/en/latest/).
