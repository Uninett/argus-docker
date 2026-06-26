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

3. Browse http://localhost:8000/

## More details

### Services

This docker compose environment brings up three services:

1. [Argus](https://github.com/Uninett/Argus) (`api`), which serves both the web
   interface and the REST API on http port 8000. Since Argus 2.0 the web
   frontend is rendered server-side and bundled into this single image — there
   is no longer a separate frontend application to deploy.
2. A background task worker (`db-task-queue`), running from the same Argus image
   with an alternate command. It drains the database-backed task queue that
   delivers notifications; without it Argus runs, but never sends any
   notifications.
3. A PostgreSQL server for persistent storage of Argus data.

### Configuration

Minimally, you need to alter the configuration in the [`.env`](./.env) file to suit your
setup (including generating the keys/random strings that should be unique for
your site!).

If you are just testing on `localhost`, the existing settings are mostly fine.

#### Changing the port number

By default, Argus binds to your system's port *8000*. If you wish to change
this, set the `ARGUS_BACKEND_PORT` variable in [`.env`](./.env).

### TLS / HTTPS

This example serves Argus over plain HTTP and does **not** terminate TLS, which
is fine for local testing but unacceptable for production. TLS is normally
handled by a reverse proxy placed in front of the `api` service. For a Docker
Compose setup, a convenient option is to add
[nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) together with its
[acme-companion](https://github.com/nginx-proxy/acme-companion) (for automatic
Let's Encrypt certificates), preferably wired in through your own
`docker-compose.override.yml` so the base `docker-compose.yml` stays
deployment-agnostic.

Once TLS is in place, set `ARGUS_FRONTEND_URL` in [`.env`](./.env) to the public
`https://` URL, so the permalinks Argus embeds in tickets and notifications use
the correct scheme and hostname.

### Authentication and federated login

Out of the box Argus uses local accounts: the `initial_setup` step above creates
the `admin` user, and further users can be added through Django's admin at
`/admin/` or via the API. For production you will usually want to connect Argus
to your organisation's identity provider instead. Argus supports two broad
approaches:

* **Web-server / `REMOTE_USER`** — the reverse proxy authenticates the user (for
  example SAML via Apache `mod_auth_mellon` or an nginx SAML module) and passes
  the username to Argus.
* **In-process OAuth2 / OIDC** via
  [python-social-auth](https://github.com/python-social-auth) — this is what Sikt
  uses for Feide/Dataporten.

Both require installing extra Python packages and supplying a custom Django
settings module, so they are intentionally left out of this minimal example. See
[How to add federated login](https://argus-server.readthedocs.io/en/latest/development/howtos/federated-logins.html)
and the
[authentication reference](https://argus-server.readthedocs.io/en/latest/reference/authentication.html)
for the details.

### Notification and ticket-system plugins

The default `ghcr.io/uninett/argus` image bundles Argus's built-in notification
media — as of 2.9.1 that is email, an email-based SMS plugin, and Slack (incoming
webhooks) — with only email enabled out of the box. (The built-in set can grow
between releases, so on a newer image check the notification docs linked below.)
Other integrations ship as separate Python packages installed alongside Argus:

* **Notification plugins** (e.g. Microsoft Teams) deliver notifications to
  additional destinations. See
  [Notification plugins](https://argus-server.readthedocs.io/en/latest/integrations/notifications/index.html).
* **Ticket-system plugins** (GitHub, GitLab, Jira and Request Tracker) let Argus
  automatically create tickets from incidents. See
  [Ticket system plugins](https://argus-server.readthedocs.io/en/latest/integrations/ticket-systems/index.html).

Rather than building a custom image to add these packages, you can switch to the
**all-plugins** image, which is built from the same releases and ships with every
Sikt-maintained notification and ticket plugin pre-installed:

```
ghcr.io/uninett/argus-all-plugins:<version>
```

This image is published from Argus **2.9.1** onward and carries the same version
tags as the default image, so pick a tag that actually exists (2.9.1 or newer —
note the example in this repo still pins an older `api` image). Switch to it by
changing the `image:` field in the `x-argus` anchor in
[`docker-compose.yml`](./docker-compose.yml) (or overriding it in
`docker-compose.override.yml`). Both the `api` and `db-task-queue` services share
that anchor, so the change covers both — which matters, because the worker is the
service that actually sends notifications.

Note that **installed is not the same as activated**: whichever image you use,
plugins must still be enabled and configured through Argus settings —
`MEDIA_PLUGINS` for notification media, and `TICKET_PLUGIN` / `TICKET_ENDPOINT` /
`TICKET_AUTHENTICATION_SECRET` / `TICKET_INFORMATION` for ticketing — which means
supplying a custom settings module. See
[site-specific settings](https://argus-server.readthedocs.io/en/latest/reference/site-specific-settings.html)
and the integration pages above for the specifics.

### Upgrading PostgreSQL

This example pins a specific PostgreSQL major version (currently `17`). For a
fresh deployment there is nothing special to do — bring the stack up and the
database is initialised on first start.

Upgrading an *existing* deployment to a newer major version is **not** just a
matter of bumping the image tag. PostgreSQL's on-disk data format changes
between major versions, and the official `postgres` image will not migrate it
for you: starting, say, a `postgres:17` container on a data volume created by
`postgres:14` fails with a "database files are incompatible with server" error.
The data has to be migrated explicitly. **Back up the `postgres` volume before
attempting any upgrade.**

The common approaches are:

* **Dump and restore** with `pg_dumpall` — the most portable method.
* **`pg_upgrade`** — faster, reuses the existing data files.
* **A drop-in helper image** such as
  [`pgautoupgrade`](https://github.com/pgautoupgrade/docker-pgautoupgrade), which
  runs `pg_upgrade` automatically against the existing volume.

See the PostgreSQL documentation on
[Upgrading a PostgreSQL Cluster](https://www.postgresql.org/docs/current/upgrading.html)
and [`pg_upgrade`](https://www.postgresql.org/docs/current/pgupgrade.html), and
the [docker-library/postgres upgrade discussion](https://github.com/docker-library/postgres/issues/37)
for why the image leaves this to you and how others automate it.

Note also that PostgreSQL **18** moved its data directory to
`/var/lib/postgresql/18/data`; upgrading to 18 or later therefore also requires
changing the `postgres` volume mount in
[`docker-compose.yml`](./docker-compose.yml), not just the image tag.

### Troubleshooting on MacOS

The images referred to by `docker-compose.yml` are hosted as GitHub packages on
the `ghcr.io` domain.  If you're attempting to run this Docker Compose
environment on Docker Desktop for MacOS, you may have problems pulling these
images. If your are getting messages about being `denied` the pull operations,
you must go into the Docker Desktop settings menu. Under the "Beta features"
tab, you must enable the option "Use containerd for pulling and storing
images".


### What is Argus, anyway?

You can read more about Argus itself at the
[Argus homepage](https://network.geant.org/argus/) or in the
[official Argus documentation](https://argus-server.readthedocs.io/en/latest/).
