. ./mysql.cfg


IP_ADDR=$(./display-mysql.sh | grep mysql-1 | awk '{print $3}')
echo IP_ADDR: $IP_ADDR

MYSQL_USER=admin
echo Configuring inventory service with IP $IP_ADDR, user $MYSQL_USER, password $MYSQL_PASSWORD

echo Deleting container group 
cf ic group rm micro-inventory-group

echo Creating container group
cf ic group create -p 8080 -m 128 --min 1 --auto --name micro-inventory-group \
	-e "spring.datasource.url=jdbc:mysql://$IP_ADDR:3306/inventorydb" \
	-e "spring.datasource.username=$MYSQL_USER" \
	-e "spring.datasource.password=$MYSQL_PASSWORD" \
	-e eureka.client.fetchRegistry=true \
	-e eureka.client.registerWithEureka=true \
	-e eureka.client.serviceUrl.defaultZone=http://netflix-eureka-$(cf ic namespace get).mybluemix.net/eureka/ \
	-n inventoryservice \
	-d mybluemix.net \
	registry.ng.bluemix.net/$(cf ic namespace get)/inventoryservice:cloudnative

echo Checking inventory
curl http://$(cf ic namespace get)-inventory.mybluemix.net/micro/inventory/13412


