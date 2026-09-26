FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod ./
COPY *.go ./
RUN CGO_ENABLED=0 go build -o /hello .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /hello /hello
USER nonroot
EXPOSE 8080
ENTRYPOINT ["/hello"]
