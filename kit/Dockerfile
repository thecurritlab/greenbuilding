FROM node:v18 AS build

# build the SvelteKit app

FROM node:v18 AS intermediate

# intermediate build of SvelteKit app

FROM node:v18

LABEL maintainer="Nate Currit"

# copy app essentials to final build for production

WORKDIR /app
