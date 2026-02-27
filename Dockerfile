FROM node:18-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
ENV BUILD_DATE="2026-02-27T17:05:00Z"
COPY . .
CMD ["tail", "-f", "/dev/null"]
