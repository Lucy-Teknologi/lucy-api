FROM golang:alpine

RUN apk add --no-cache curl pkgconfig

RUN curl -s https://raw.githubusercontent.com/h2non/bimg/master/preinstall.sh | sh -
RUN apk add --no-cache build-base libtool autoconf automake zlib-dev libpng-dev libjpeg-turbo-dev libwebp-dev giflib-dev libexif-dev libheif-dev vips-dev fftw-dev

WORKDIR /go/src/app
COPY . .
# RUN go mod tidy


ENTRYPOINT [ "./lucy-go-api" ]