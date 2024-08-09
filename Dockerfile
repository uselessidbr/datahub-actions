# Copyright 2021 Acryl Data, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Defining environment
ARG APP_ENV=prod
ARG ACTIONS_VERSION=v0.0.15

FROM acryldata/datahub-actions:${ACTIONS_VERSION} as prod-install

USER root

RUN apt-get update \
    && apt-get install -y -qq \
    make \
    jq \
    python3-ldap \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    libsasl2-modules \
    libaio1 \
    libsasl2-modules-gssapi-mit \
    krb5-user \
    wget \
    git \
    zip \
    unzip \
    ldap-utils \
    && LIBRDKAFKA_VERSION=$(basename $(curl -Ls -o /dev/null -w %{url_effective} https://github.com/confluentinc/librdkafka/releases/latest | cut -d'v' -f2)) \
    && curl -Lk -o /root/librdkafka-${LIBRDKAFKA_VERSION}.tar.gz https://github.com/edenhill/librdkafka/archive/v${LIBRDKAFKA_VERSION}.tar.gz \
    && tar -xzf /root/librdkafka-${LIBRDKAFKA_VERSION}.tar.gz -C /root/ \
    && cd /root/librdkafka-${LIBRDKAFKA_VERSION} \ 
    && ./configure --prefix /usr && make && make install && make clean && ./configure --clean \
    && apt-get remove -y make \
    && rm -Rf /root/librdkafka-${LIBRDKAFKA_VERSION}

RUN CONFLUENT_KAFKA_VERSION=$(grep confluent-kafka requirements.txt) \
    && pip install --upgrade --ignore-installed --no-binary :all: "${CONFLUENT_KAFKA_VERSION}"

FROM ${APP_ENV}-install as final
USER datahub
ENTRYPOINT [ ]
CMD dockerize -wait ${DATAHUB_GMS_PROTOCOL:-http}://$DATAHUB_GMS_HOST:$DATAHUB_GMS_PORT/health -timeout 240s /start_datahub_actions.sh
