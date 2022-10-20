import json
import requests
import response

requests.packages.urllib3.disable_warnings()

api_url = "https://10.110.101.1/restconf/data/ietf-interfaces:interfaces"

headers = { "Accept": "application/yang-data+json",
	    "Content-type": "application/yang-data+json"}

basicauth = ("patah", "Skills39")

yangConfig = {
    "ietf-interfaces:interfaces": {
        "interface": [
            {
                "name": "GigabitEthernet1",
                "type": "iana-if-type:ethernetCsmacd",
                "enabled": "true",
                "ietf-ip:ipv4": {
                    "address": [
                        {
                            "ip": "10.110.101.1",
                            "netmask": "255.255.255.0"
                        }
                    ]
                },
                "ietf-ip:ipv6": {}
            },
            {
                "name": "GigabitEthernet2",
                "type": "iana-if-type:ethernetCsmacd",
                "enabled": "true",
                "ietf-ip:ipv4": {
                    "address": [
                        {
                            "ip": "10.200.200.1",
                            "netmask": "255.255.255.0"
                        }
                    ]
                },
                "ietf-ip:ipv6": {}
            }
        ]
    }
}

resp = requests.put(api_url, data=json.dumps(yangConfig), auth=basicauth, headers=headers, verify=False)

if(resp.status_code >= 200 and resp.status_code <= 299):
	print("Status OK: {}" .format(resp.status_code))
else:
	print('Error, Status Code: {} \nError messege: {}' .format(resp.status_code,resp.json()))
