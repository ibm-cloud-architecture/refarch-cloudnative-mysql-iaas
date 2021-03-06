. ./mysql.cfg


echo Using the following SoftLayer configuration
slcli config show

# Set the server type
if [ "$SERVER_TYPE"  == "bare" ]; then
  CLI_TYPE=server
else
  CLI_TYPE=vs
fi


# Deletes the kube master
TEMP_FILE=/tmp/destroy_mysql.out
slcli $CLI_TYPE list --domain $DOMAIN > $TEMP_FILE
for id in `cat $TEMP_FILE | awk '{print $1}'`
do
   echo Deleting server $id
   echo $id | slcli $CLI_TYPE cancel $id
done





