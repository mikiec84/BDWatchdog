#!/usr/bin/env bash
source ../config.sh
if [ -z ${DATA_DIR} ]
then
    echo "\$DATA_DIR is empty, check the config.sh file and try again"
    exit 0
fi
if [ -z ${JAVA_HOME} ]
then
    echo "\$JAVA_HOME is not set, check the config.sh file and try again"
    exit 0
fi

echo "Stopping everything"
bash stop.sh

echo "Cleaning all the possibibly remaining previous data and software"
echo -e "y" | bash wipe_data.sh
echo -e "y" | bash wipe_software.sh

echo "Install HDFS"
wget http://apache.rediris.es/hadoop/common/hadoop-2.9.2/hadoop-2.9.2.tar.gz
tar xvf hadoop-2.9.2.tar.gz
chown -R $(whoami):$(whoami) hadoop-2.9.2
envsubst < config/hdfs/hdfs-site.xml > hadoop-2.9.2/etc/hadoop/hdfs-site.xml
cp config/hdfs/core-site.xml hadoop-2.9.2/etc/hadoop/core-site.xml
cp config/hdfs/format_filesystem.sh hadoop-2.9.2

echo "Format HDFS filesystem"
cd hadoop-2.9.2/
bash format_filesystem.sh
cd ..
sleep 20

echo "Start HDFS"
hadoop-2.9.2/sbin/start-dfs.sh
sleep 20

echo "Install HBase"
wget http://apache.rediris.es/hbase/hbase-1.4.12/hbase-1.4.12-bin.tar.gz
tar xvf hbase-1.4.12-bin.tar.gz
chown -R $(whoami):$(whoami) hbase-1.4.12
envsubst < config/hbase/hbase-site.xml > hbase-1.4.12/conf/hbase-site.xml
cp config/hbase/regionservers hbase-1.4.12/conf/regionservers

echo "Start HBase"
hbase-1.4.12/bin/start-hbase.sh
sleep 20

echo "Install OpenTSDB"
mkdir -p /var/log/opentsdb/
git clone git://github.com/OpenTSDB/opentsdb.git
cd opentsdb

# MAVEN FIX #
# https://github.com/OpenTSDB/opentsdb/issues/1899
find . | xargs grep -s central.maven.org | cut -f1 -d : | xargs sed -i '' -e "s/http:\/\/central/https:\/\/repo1/g"
find . | xargs grep -s repo1.maven.org | cut -f1 -d : | xargs sed -i '' -e "s/http:\/\/repo1/https:\/\/repo1/g"
# MAVEN FIX #

./build.sh
cp ../fix/opentsdb/create_table.sh ./src/create_table.sh
env COMPRESSION=GZ HBASE_HOME=$BDWATCHDOG_DIR/deployment/metrics/hbase-1.4.12/ ./src/create_table.sh
bash $BDWATCHDOG_DIR/MetricsFeeder/scripts/opentsdb/create-monitoring-opentsdb-metrics.sh
envsubst < ../config/opentsdb/opentsdb.conf  > opentsdb.conf # Expand variable $HOME inside of template file
cd ..

echo "Starting OpenTSDB"
cd opentsdb
tmux new -d -s "OPENTSDB" "./build/tsdb tsd"
cd ..

