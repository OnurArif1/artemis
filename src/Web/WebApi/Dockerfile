FROM node:20-alpine AS build
WORKDIR /app

ARG VITE_SIGNALR_HUB_URL=http://localhost:5094/hubs/chat
ARG VITE_IDENTITY_TOKEN_URL=http://artemisgw.ghossip.app/identity/connect/token

ENV VITE_SIGNALR_HUB_URL=$VITE_SIGNALR_HUB_URL
ENV VITE_IDENTITY_TOKEN_URL=$VITE_IDENTITY_TOKEN_URL

COPY src/Web/WebApi/package*.json ./
RUN npm ci

COPY src/Web/WebApi/ ./

RUN npm run build

FROM nginx:alpine
WORKDIR /usr/share/nginx/html

COPY --from=build /app/dist .

COPY src/Web/WebApi/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 5175

CMD ["nginx", "-g", "daemon off;"]
