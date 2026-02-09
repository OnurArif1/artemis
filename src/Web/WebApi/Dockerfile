# Build stage
FROM node:20-alpine AS build
WORKDIR /app

# Copy package files
COPY src/Web/WebApi/package*.json ./
RUN npm ci

# Copy source code
COPY src/Web/WebApi/ ./

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Copy built files from build stage
COPY --from=build /app/dist .

# Copy nginx configuration
COPY src/Web/WebApi/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 5175

CMD ["nginx", "-g", "daemon off;"]
