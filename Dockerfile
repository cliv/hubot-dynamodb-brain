FROM node:8
RUN npm install -g grunt bower mocha
COPY . /app
WORKDIR /app
RUN npm install
CMD ["grunt", "test"]
