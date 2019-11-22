FROM tenforce/virtuoso:virtuoso7.2.5

# Install curl
RUN apt-get update
RUN apt-get -y install curl

# Add startup script
COPY startup.sh /startup.sh

CMD ["/bin/bash", "/startup.sh"]
