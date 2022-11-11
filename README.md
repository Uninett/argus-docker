# Argus production deployment examples using Docker

This repository contains a simple, but complete Argus deployment example using
Docker Compose.

## Services

This docker compose environment brings up four services:

1. The main Argus API backend (http port 8000)
2. The main Argus frontend application (http port 80)
3. A PostgreSQL server for persistent storage of Argus data
4. A Redis server that acts as a message broker for websocket communication
   between the frontend and backend components.

## Configuration

Minimally, you need to alter the configuration in the .env file to suit your
setup (including generating the keys/random strings that should be unique for
your site!).

If you are just testing on localhost, the existing settings are mostly fine. Be
aware that the complete application consists of *2* web sites:

1. The frontend, pre-configured at build time to access the backend at the
   configured domain name.
2. The backend API server.

## SSL

This setup does not include SSL protection of the web sites. This is absolutely
necessary for production deployment. If you want to deploy to production user
Docker Compose, we suggest looking at including
https://github.com/nginx-proxy/acme-companion into your `docker-compose.yml`
(or maybe preferably, into `docker-compose.override.yml`).

## Before your first login

After getting the docker compose environment up and running, you must create
your initial admin user, thus:

```
docker compose exec api django-admin initial_setup
```

This should create the `admin` user and print a randomly generated password for
that user. Use this on your first login to Argus.
