Welcome to the readme file!

How to run this code:

1) Download and ungzip GeoLite2 City database:
`http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz`

2) Install the libraries: `Apache::Log::Parser`, `GeoIP2`

3) Find any apache access log file

4) And enjoy:

`~$ ./test.pl GeoLite2-City.mmdb access.log`


(c) Amir Begalinov
