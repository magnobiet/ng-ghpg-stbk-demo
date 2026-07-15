# =========================================
# Stage 1: Build the Angular Application
# =========================================
ARG NODE_VERSION=24.18.0-alpine
ARG NGINX_VERSION=alpine3.24

# Use a lightweight Node.js image for building (customizable via ARG)
FROM node:${NODE_VERSION} AS base

# Enable pnpm via Corepack (bundled with Node.js)
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# Set the working directory inside the container
WORKDIR /app

# =========================================
# Install dependencies
# =========================================
FROM base AS deps

# Copy lockfile and manifest first to leverage Docker's layer caching
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# Install all dependencies (including devDependencies needed for build)
# Uses BuildKit cache mount to share pnpm store across builds
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

# =========================================
# Build stage
# =========================================
FROM deps AS builder

# Copy the rest of the application source code into the container
COPY . .

# Build the Angular application
RUN pnpm build

# =========================================
# Stage 2: Prepare Nginx to Serve Static Files
# =========================================

FROM nginxinc/nginx-unprivileged:${NGINX_VERSION} AS runner

# Copy custom Nginx config
# Path relative to build context (project root)
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Copy the static build output from the build stage to Nginx's default HTML serving directory
COPY --chown=nginx:nginx --from=builder /app/dist/*/browser /usr/share/nginx/html

# Use a built-in non-root user for security best practices
USER nginx

# Expose port 8080 to allow HTTP traffic
# Note: The default Nginx container now listens on port 8080 instead of 80
EXPOSE 8080

# Start Nginx directly with custom config
ENTRYPOINT ["nginx", "-c", "/etc/nginx/nginx.conf"]
CMD ["-g", "daemon off;"]
