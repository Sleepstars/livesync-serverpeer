# Stage 1: Deno binary
FROM denoland/deno:bin-2.2.11 as deno

# Stage 2: Dependencies
FROM node:22.14-bookworm-slim as deps
COPY --from=deno /deno /usr/local/bin/deno

# Set working directory
WORKDIR /app

# Copy dependency files first to leverage Docker cache
COPY package.json package-lock.json deno.json ./

# Install dependencies
RUN deno task install && \
    # Clean npm cache to reduce image size
    npm cache clean --force

# Stage 3: Production image
FROM node:22.14-bookworm-slim as production

# Copy Deno binary
COPY --from=deno /deno /usr/local/bin/deno

# Set working directory
WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/package.json /app/package-lock.json /app/deno.json ./

# Copy source code
COPY lib ./lib
COPY src ./src
COPY dat ./dat

# Set environment variables
ENV NODE_ENV=production

# Default command
CMD ["deno", "task", "main", ""]