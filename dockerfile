FROM jrottenberg/ffmpeg

WORKDIR /downmix

COPY downmix.sh downmix.sh

USER root 
RUN chmod 755 downmix.sh

ENTRYPOINT [ "/downmix/downmix.sh" ]

