keytool -J-Dkeystore.pkcs12.legacy -genkey -alias mcas -keyalg RSA -keystore upf-keystore.jks -keysize 2048 -storepass aciworldwide -keypass aciworldwide -validity 3650 -dname "CN=UPF" -J-Dkeystore.pkcs12.legacy

keytool -exportcert -rfc -alias mcas -file upf.crt -keystore upf-keystore.jks -storepass aciworldwide

keytool -genkey -alias icexs -keyalg RSA -keystore icexs-mgmt-keystore.pfx -keysize 2048 -storetype PKCS12 -storepass aciworldwide -keypass aciworldwide -validity 3650 -dname "CN=ICEXS"

keytool -exportcert -alias icexs -file icexs.crt -keystore icexs-mgmt-keystore.pfx -storetype PKCS12 -storepass aciworldwide

keytool -import -noprompt -alias icexs -trustcacerts -file icexs.crt -keystore upf-truststore.jks -storepass aciworldwide