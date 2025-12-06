FROM node:18-alpine

WORKDIR /usr/src/app

# Install deps using package files from apiserver
COPY apiserver/package*.json ./
RUN npm install --production

# Copy backend source
COPY apiserver/ ./

# Ensure images folder exists (for uploads)
RUN mkdir -p images/profile

ENV NODE_ENV=production
EXPOSE 5000

CMD ["npm", "start"]