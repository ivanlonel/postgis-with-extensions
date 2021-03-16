ARG BASE_IMAGE_TAG=latest

FROM ivanlonel/postgis-with-extensions:$BASE_IMAGE_TAG

ARG LOCALE
ARG ENCODING=UTF-8

# See "Locale Customization" in https://github.com/docker-library/docs/blob/master/postgres/README.md
RUN localedef -i $LOCALE -c -f $ENCODING -A /usr/share/locale/locale.alias $LOCALE.$ENCODING
