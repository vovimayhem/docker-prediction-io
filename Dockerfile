FROM java:8-jdk
MAINTAINER Romain Vermot <romain@vermot.eu>

RUN cp /etc/default/useradd /etc/default/useradd.bak \
  && echo "HOME=" >> /etc/default/useradd \
  && useradd --create-home --shell /usr/sbin/nologin prediction-io \
  && rm -rf /etc/default/useradd \
  && mv /etc/default/useradd.bak /etc/default/useradd \
  && rm /prediction-io/.bash_logout /prediction-io/.bashrc /prediction-io/.profile

USER prediction-io
WORKDIR /prediction-io

# Breakdown of the next 'monolythic' ENV command:
#   - Line X: Prepend the '/prediction-io/bin' directory to $PATH
#   - Line X: Set the PredictionIO version

ENV PIO_VERSION=0.9.6 \
    PIO_FS_BASEDIR=/prediction-io/.pio_store \
    PIO_FS_ENGINESDIR=/prediction-io/.pio_store/engines \
    PIO_FS_TMPDIR=/prediction-io/.pio_store/tmp \
    PATH=/prediction-io/bin:$PATH \
    PIO_ENV_LOADED=1

# Breakdown of the next 'monolythic' RUN command:
#   - Line XX: Add the "prediction-io" user+group, with it's home dir at '/prediction-io'.
#   - Line XX: Download, Build & Install PredictionIO into the '/prediction-io' dir.
#   - Line XX: Edit the PredictionIO logger config to write logs to STDOUT only.
#   - Line XX: Download Spark
#   - Line XX: Remove PredictionIO environment variables shell scripts, as we're
#   providing the environment variables anyway.
#   - Line XX: Fix owner/group of the files at '/prediction-io'.

RUN mkdir -p /tmp/src/prediction-io /prediction-io/.pio_store/tmp /prediction-io/.pio_store/engines \
  && curl -fSL -o /tmp/pio.tar.gz "https://github.com/PredictionIO/PredictionIO/archive/v$PIO_VERSION.tar.gz" \
  && tar zxvfC /tmp/pio.tar.gz /tmp/src/prediction-io --strip-components=1 \
  && rm -rf /tmp/pio.tar.gz \
  && cd /tmp/src/prediction-io \
  && ./make-distribution.sh \
  && tar zxvfC "PredictionIO-$PIO_VERSION.tar.gz" /prediction-io --strip-components=1 \
  && rm -rf /tmp/src/prediction-io \
  && sed -i '/log4j.appender.file/d;/# file/d;s/INFO, console, file/INFO, console/' /prediction-io/conf/log4j.properties \
  && cat /prediction-io/conf/log4j.properties \
  && rm -rf /prediction-io/conf/pio-env.sh*

ENV HADOOP_VERSION=2.6 \
    SPARK_VERSION=1.3.1 \
    SPARK_HOME=/prediction-io/vendors/spark \
    SPARK_DOWNLOAD_SHA512=ce50ce521895eeabbe3606cfcd76e09bab7ef539acbb4aa7040b5042017885e8619c2acbc0a48cc2d0e2ba4d8d45ff05b804fc8c1eca6561f409d8605c637d96 \
    PATH=/prediction-io/vendors/spark/bin:$PATH

RUN mkdir -p /prediction-io/vendors/spark \
  && curl -fSL -o /tmp/spark.tar.gz "http://www.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop$HADOOP_VERSION.tgz" \
  && echo "$SPARK_DOWNLOAD_SHA512 /tmp/spark.tar.gz" | sha512sum -c - \
	&& tar zxvfC /tmp/spark.tar.gz /prediction-io/vendors/spark --strip-components=1 \
	&& rm -rf /tmp/spark.tar.gz

VOLUME ["/prediction-io/.pio_store"]

# Set the default command:
CMD ["pio", "eventserver"]
