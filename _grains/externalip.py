import requests

def external_ip():
    """
    Return the external IP address reported by icanhazip
    """
    try:
        r = requests.get('http://icanhazip.com')
        ip = r.content
    except:
        ip = ''
    return {'external_ip': ip}
