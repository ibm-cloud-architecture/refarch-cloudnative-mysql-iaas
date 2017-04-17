source bluemix-infra-tools/deploy-tools.sh

VM_PREFIX=mysql-
HOSTS=/tmp/ansible-hosts
TEMP_FILE=/tmp/deploy-mysql.out

# This var is not used anymore
TIMEOUT=600
PORT_SPEED=10

. ./mysql.cfg

# Need to determine operating system for certain SL CLI commands
PLATFORM_TYPE=$(uname)

# Set the server type
if [ $SERVER_TYPE  == "bare" ]; then
  SERVER_MESSAGE="bare metal server"
  CLI_TYPE=server
  SPEC="--size $SIZE --port-speed $PORT_SPEED --os CENTOS_7_64"
  STATUS_FIELD="status"
  STATUS_VALUE="ACTIVE"
else
  SERVER_MESSAGE="virtual server"
  CLI_TYPE=vs
  SPEC="--cpu $CPU --memory $MEMORY --os UBUNTU_LATEST --disk 25 --disk 25"
  STATUS_FIELD="state"
  STATUS_VALUE="RUNNING"
fi

function update_hosts_file {
  # Update ansible hosts file
  echo Updating ansible hosts files
  echo > $HOSTS
  echo "[mysql]" >> $HOSTS
  obtain_ip ${VM_PREFIX}1
  echo "${VM_PREFIX}1 ansible_host=$IP_ADDRESS ansible_user=root" >> $HOSTS
}

# Args $1 Node name
function configure_node {
  echo Configuring node $1

  # Get ucp password
  obtain_root_pwd $1

  # Get master IP address
  obtain_ip $1
  NODE_IP=$IP_ADDRESS
  echo IP Address: $NODE_IP

  # Set the SSH key
  set_ssh_key $PASSWORD $NODE_IP
}

#Args: $1: IP address
function install_python {
  echo Installing python

  # SSH to host
  ssh -o StrictHostKeyChecking=no root@$1 \
  "if [ ! -f /usr/bin/python ]; then add-apt-repository ppa:fkrull/deadsnakes && apt-get update && apt install -y python2.7 &&"\
  " ln -fs /usr/bin/python2.7 /usr/bin/python; fi" 

}


function configure_mysql {
  echo Configuring MySQL VM
  for(( x=1; x <= ${NUM_NODES}; x++))
  do
    configure_node "${VM_PREFIX}${x}"
  done

  install_python $NODE_IP

  # Execute node playbook
  ansible-playbook -i $HOSTS ansible/mysql.yaml -e mysql_password=$MYSQL_PASSWORD
}



function create_vm {
  create_machines ${NUM_NODES} ${VM_PREFIX}
}


echo Using the following SoftLayer configuration
slcli config show

create_vm

update_hosts_file

configure_mysql

echo -e "Congratulations. Your MySQL environment is up and running at\nHost: $NODE_IP\nuser: admin\npassword: $MYSQL_PASSWORD"


