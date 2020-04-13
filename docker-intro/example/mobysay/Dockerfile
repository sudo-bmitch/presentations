FROM debian:10

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends cowsay

COPY moby.cow /usr/share/cowsay/cows/

ENV PATH=$PATH:/usr/games

ENTRYPOINT [ "cowsay", "-f", "moby.cow" ]
CMD [ "Whale hello there" ]

