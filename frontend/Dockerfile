FROM ghcr.io/uninett/argus-frontend-builder:1.6.1 AS build

# These arguments are needed in the environment to properly configure and build
# Argus-frontend for this site:
ARG REACT_APP_BACKEND_URL=http://argus.example.org
ARG REACT_APP_ENABLE_WEBSOCKETS_SUPPORT=true
ARG REACT_APP_BACKEND_WS_URL=wss://argus.example.org/ws
ARG REACT_APP_USE_SECURE_COOKIE=true
ARG REACT_APP_DEBUG=true
ARG REACT_APP_DEFAULT_AUTO_REFRESH_INTERVAL=30
ARG REACT_APP_REALTIME_SERVICE_MAX_RETRIES=5
ARG REACT_APP_COOKIE_DOMAIN=argus.example.org

RUN npm run build

##########################################################
# production environment consisting only of nginx and the statically compiled
# Argus Frontend application files
# FROM: https://mherman.org/blog/dockerizing-a-react-app/
FROM nginx:stable-alpine

COPY --from=build /app/build /usr/share/nginx/html

RUN apk add --update tini tree
COPY nginx.conf /etc/nginx/conf.d/default.conf

ENTRYPOINT ["/sbin/tini", "-v", "--"]
CMD ["nginx", "-g", "daemon off;"]
