### Enabling SASL authentication on "datahub-actions"

In order to enable SASL (GSSAPI) authentication, follow these detailed steps:

Create the ConfigMap:
- **name**: ingestion-executor-cm
- **mountPath**: /etc/datahub/actions/system/conf/executor.yaml
- **subPath**: executor.yaml

The content of the file is in this repository under the name "**executor.yaml**".

Additionally you will need to include within the HELM "values", under the "datahub-actions" properties, the following settings:

```
  extraEnvs:
  - name: KAFKA_BOOTSTRAP_SERVER
    value: lnciasc-boavistaprod130.intranet.ciasc.gov.br:9093,lnciasc-boavistaprod131.intranet.ciasc.gov.br:9093,lnciasc-boavistaprod132.intranet.ciasc.gov.br:9093
  - name: KAFKA_PROPERTIES_SASL_KERBEROS_SERVICE_NAME
    value: kafka
  - name: KAFKA_PROPERTIES_SECURITY_PROTOCOL
    value: SASL_SSL
  - name: KAFKA_PROPERTIES_SASL_JAAS_CONFIG
    value: com.sun.security.auth.module.Krb5LoginModule required principal='app-datahub'
      ssl.truststore.location='/etc/ssl/cm-auto-global_cacerts.jks' ssl.truststore.password='password'
      serviceName='kafka' useTicketCache=false useKeyTab=true doNotPrompt=true storeKey=true
      keyTab="/tmp/kerberos/app-datahub.keytab" debug=true;
  extraPipPackages:
  - acryl-datahub[presto-on-hive]
  - acryl-datahub[hive]
  extraVolumeMounts:
  - mountPath: /etc/datahub/actions/system/conf/executor.yaml
    name: ingestion-executor-cm
    subPath: executor.yaml
  - mountPath: /etc/ssl/ca.crt
    name: kafka-ca-cert
    readOnly: true
    subPath: ca.crt
  - mountPath: /opt/kafka/kafka-config.sh
    name: kafka-config-sh
    subPath: kafka-config.sh
  - mountPath: /tmp/kerberos
    name: datahub-kerberos-keytab
    readOnly: true
  - mountPath: /etc/krb5.conf
    name: datahub-kerberos-keytab
    readOnly: true
    subPath: krb5.conf
  - mountPath: /etc/ssl/cm-auto-global_cacerts.jks
    name: kafka-truststore
    readOnly: true
    subPath: cm-auto-global_cacerts.jks
  extraVolumes:
  - configMap:
      name: kafka-config-sh
    name: kafka-config-sh
  - name: datahub-kerberos-keytab
    secret:
      secretName: datahub-kerberos-keytab
  - name: kafka-truststore
    secret:
      secretName: truststore
  - configMap:
      name: ingestion-executor-cm
    name: ingestion-executor-cm
  - name: kafka-ca-cert
    secret:
      secretName: kafka-ca-cert
  image:
    repository: docker.io/gvoliveira/datahub-actions-sasl-gssapi
    tag: v0.0.15
```
### Create the image with SASL suppoirt

To build the image with SASL support, use the Dockerfile provided in this repository.

Here are the two possible strategies for deploying the image:

1. Utilize the dockerfile corresponding to the desired tag and incorporate the compilation processes of **librdkafka** and install the necessary **pip** package;
2. Import the image with the desired tag and, create an additional **layer** to perform the compilation and installation process. 

The second strategy is ideal because, initially, it will allow for a sustainable long-term process without the need to refactor the entire **Dockerfile**. 

#### Strategy 1

##### Building the image

Run the following commands:
```
git clone http://git.intranet.ciasc.gov.br/devops/datahub.git .
cd datahub/datahub-actions/v0.0.15
docker build -t sasl .
```

##### Alterando a tag para realizar o push

Execute o comando:
```
docker tag sasl:latest docker.io/gvoliveira/datahub-actions-sasl:v0.0.15
```

##### Realizando o push para o repositório 

Execute o comando: 
```
docker push gvoliveira/datahub-actions-sasl:v0.0.15
```

#### Estratégia 2

Executar os  comandos:
```
git clone http://git.intranet.ciasc.gov.br/devops/datahub.git .
cd datahub/datahub-actions
docker build -t sasl --build-arg ACTIONS_VERSION=v0.0.15 .
```
Obs.: a variável **ACTIONS_VERSION** definirá a versão da imagem a ser importada, neste exemplo "v0.0.15".

##### Alterando a tag para realizar o push

Execute o comando:
```
docker tag sasl:latest docker.io/gvoliveira/datahub-actions-gssapi:v0.0.15
```

##### Realizando o push para o repositório 

Execute o comando: 
```
docker push gvoliveira/datahub-actions-gssapi:v0.0.15
```
