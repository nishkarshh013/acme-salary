# syntax=docker/dockerfile:1
# check=error=true

# One image for the whole app (docs/architecture.md, decision 1): the React
# build is copied into Rails' public/, and Rails serves both the UI and the
# API from one origin. Built from the repository root:
#
#   docker build -t acme-salary .
#   docker run -p 3000:3000 -e DATABASE_URL=... -e SECRET_KEY_BASE=... \
#     -e HR_EMAIL=... -e HR_PASSWORD=... acme-salary
#
# Based on the Dockerfile Rails 8 generated (backend/Dockerfile), with a
# Node stage added for the frontend.

ARG RUBY_VERSION=3.4.4
ARG NODE_VERSION=22.12.0

# --- Frontend: npm ci and npm run build -----------------------------------
FROM docker.io/library/node:$NODE_VERSION-slim AS frontend

WORKDIR /frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# --- Backend base ----------------------------------------------------------
# Make sure RUBY_VERSION matches the Ruby version in backend/.ruby-version
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# --- Backend build: gems, code, and the frontend build in public/ ------------
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY backend/vendor/* ./vendor/
COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY backend/ ./

# The React build: index.html at public/, hashed files under public/assets/.
COPY --from=frontend /frontend/dist/ ./public/

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# --- Final image -----------------------------------------------------------
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p db log storage tmp/pids && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares and seeds the database, and points Thruster at $PORT.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Thruster listens on $PORT (3000 by default) and runs Puma behind it.
EXPOSE 3000
CMD ["./bin/thrust", "./bin/rails", "server"]
