FROM golang:alpine as build

# go-swagger
WORKDIR /buid
RUN apk --no-cache add ca-certificates shared-mime-info mailcap git build-base binutils-gold upx
RUN git clone https://github.com/go-swagger/go-swagger.git

WORKDIR /buid/go-swagger
RUN git checkout tags/v0.30.4
RUN CGO_ENABLED=0 go build -tags osusergo,netgo -o /bin/swagger-0.30.4 -a ./cmd/swagger

RUN git checkout tags/v0.28.0
RUN go build -o /bin/swagger-0.28.0 -ldflags "-linkmode external -extldflags \"-static\"" -a ./cmd/swagger

# swagger-sdk-gen
WORKDIR /buid
RUN git clone https://github.com/haxii/js-swagger-sdk-gen.git

WORKDIR /buid/js-swagger-sdk-gen
RUN go build -o /bin/swagger-sdk-gen ./cmd/js-swagger-sdk-gen/*

RUN upx --best /bin/swagger-0.28.0
RUN upx --best /bin/swagger-0.30.4
RUN upx --best /bin/swagger-sdk-gen

FROM golang:alpine
RUN apk --no-cache add git

COPY --from=build /bin/swagger-0.28.0 /bin/
COPY --from=build /bin/swagger-0.30.4 /bin/
COPY --from=build /bin/swagger-sdk-gen /bin/
