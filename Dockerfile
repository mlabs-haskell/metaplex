# Stage 1: Compile and Build the app

# Node version
FROM node:14.17.3-alpine as build

RUN apk add --update --no-cache \
    make \
    g++ \
    jpeg-dev \
    cairo-dev \
    giflib-dev \
    pango-dev \
    libtool \
    autoconf \
    automake \
    git \
    libc6-compat

# Set the working directory
WORKDIR /app

# Add the source code to app
COPY ./js /app

# Install all the dependencies
RUN yarn install --frozen-lockfile --network-timeout 1000000
RUN yarn bootstrap

# HERE ADD YOUR STORE WALLET ADDRESS
ENV REACT_APP_STORE_OWNER_ADDRESS_ADDRESS=""

# Generate the build of the application
RUN npx browserslist@latest --update-db
RUN yarn build-web

# Stage 2: Serve app with nginx server

# Production image, copy all the files and run next
FROM node:14.17.3-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Copy the build output to replace the default nginx contents.
COPY --from=build /app/packages/web/next.config.js ./
COPY --from=build /app/packages/web/public ./public
COPY --from=build --chown=nextjs:nodejs /app/packages/web/.next ./.next
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/packages/web/package.json ./package.json

USER nextjs

EXPOSE 3000

CMD ["yarn", "start:prod"]
