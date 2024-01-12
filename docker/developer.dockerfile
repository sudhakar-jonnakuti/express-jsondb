# Stage 1: Setup a home directory.
FROM node:20-alpine AS base
RUN mkdir -p /home/node/app
RUN chown -R node:node /home/node && chmod -R 770 /home/node
WORKDIR /home/node/app

# Stage 2: Install dependencies.
FROM base AS app-install
WORKDIR /home/node/app
COPY --chown=node:node ./package.json ./package.json
COPY --chown=node:node ./package-lock.json ./package-lock.json
USER node
RUN npm install --loglevel warn

# Stage 3: Type checking.
FROM app-install AS app-typecheck
WORKDIR /home/node/app
COPY --chown=node:node ./src ./src
COPY --chown=node:node ./tsconfig.json ./tsconfig.json
COPY --from=app-install /home/node/app/node_modules ./node_modules
USER node
RUN npm run app:typecheck

# Stage 4: Lint checking.
FROM app-typecheck AS app-lint
WORKDIR /home/node/app
COPY --chown=node:node ./.eslintrc ./.eslintrc
COPY --chown=node:node ./.eslintignore ./.eslintignore
COPY --chown=node:node ./.prettierrc ./.prettierrc
COPY --chown=node:node ./.prettierignore ./.prettierignore
COPY --from=app-typecheck /home/node/app/src ./src
COPY --from=app-typecheck /home/node/app/tsconfig.json ./tsconfig.json
COPY --from=app-typecheck /home/node/app/node_modules ./node_modules
USER node
RUN npm run app:lint

# Stage 5: Bundler with ESBuild.
FROM app-lint AS app-build
WORKDIR /home/node/app
COPY --chown=node:node ./esbuild.js ./esbuild.js
Copy --from=app-lint /home/node/app/src ./src
COPY --from=app-lint /home/node/app/node_modules ./node_modules
USER node
RUN npm run app:build

# Stage 6: Serve the application.
FROM node:20-alpine AS developer
WORKDIR /home/node/app

# Copy necessary files
COPY --from=app-build /home/node/app/dist ./dist
COPY --from=app-install /home/node/app/node_modules ./node_modules
COPY --from=app-install /home/node/app/package.json ./package.json
COPY --from=app-install /home/node/app/package-lock.json ./package-lock.json

# Set APP_PORT environment variable
ENV APP_PORT=5000

USER node

# Run the application
CMD npm run app:start:dev
