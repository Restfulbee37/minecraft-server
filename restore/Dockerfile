FROM alpine:latest

#Create Working Dir
RUN mkdir -p /tmp_store

RUN apk -U --no-cache add \
	sudo \
	bash \
	tar

COPY --chmod=755 scripts/ /usr/bin/

VOLUME ["/data", "/backups", "/worlds"]
ENTRYPOINT ["/usr/bin/restore"]
