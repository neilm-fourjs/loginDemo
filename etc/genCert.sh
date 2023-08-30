
echo "Gen MyCert - key ..."
openssl req -newkey rsa:2048 -nodes -keyout MyCert.key -out MyCert.csr
echo "Gen MyCert - cert ..."
openssl req -key MyCert.key -new -x509 -days 365 -out MyCert.crt
