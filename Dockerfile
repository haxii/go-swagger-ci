FROM golang:alpine as build

# go-swagger
WORKDIR /build
RUN apk --no-cache add ca-certificates shared-mime-info mailcap git build-base binutils-gold upx

RUN git clone https://github.com/go-swagger/go-swagger.git
WORKDIR /build/go-swagger

RUN git checkout v0.30.4
RUN CGO_ENABLED=0 go build -tags osusergo,netgo -o /bin/swagger-0.30.4 -a ./cmd/swagger

RUN git checkout v0.28.0
RUN go build -o /bin/swagger-0.28.0 -ldflags "-linkmode external -extldflags \"-static\"" -a ./cmd/swagger

# swag
WORKDIR /build
RUN git clone https://github.com/swaggo/swag.git
WORKDIR /build/swag

RUN latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1))
RUN git checkout $latest_tag
RUN CGO_ENABLED=0 go build -a -o /bin/swag cmd/swag/main.go

# swagger-sdk-gen
WORKDIR /build
RUN git clone https://github.com/haxii/js-swagger-sdk-gen.git

WORKDIR /build/js-swagger-sdk-gen
RUN go build -o /bin/swagger-sdk-gen ./cmd/js-swagger-sdk-gen/*

# compress
RUN upx --best /bin/swagger-0.28.0
RUN upx --best /bin/swagger-0.30.4
RUN upx --best /bin/swagger-sdk-gen
RUN upx --best /bin/swag

FROM golang:alpine
RUN apk --no-cache add git

COPY --from=build /bin/swagger-0.28.0 /bin/
COPY --from=build /bin/swagger-0.30.4 /bin/
COPY --from=build /bin/swagger-sdk-gen /bin/
COPY --from=build /bin/swag /bin/
