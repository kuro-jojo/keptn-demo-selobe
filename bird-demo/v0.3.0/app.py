import requests, os, time, re, json
from datetime import datetime
from random import randint
from dotenv import load_dotenv
from logging import log
import logging, base64

HEC_ENDPOINT = "services/collector"


class Splunksender(object):
    def __init__(self, host, port, token):
        self.instance = f"{host}:{port}"

        self.token = token

    def send(self, doc, source, index="keptn-splunk-dev", sourcetype="logger"):
        headers = {"Authorization": f"Splunk {self.token}"}
        body = {"event": doc}
        body["index"] = index
        body["sourcetype"] = sourcetype
        body["source"] = source
        response = requests.request(
            "POST",
            f"https://{self.instance}/{HEC_ENDPOINT}",
            headers=headers,
            data=json.dumps(body),
            verify=False,
        )
        return response

    def is_connected(self):
        headers = {"Authorization": f"Splunk {self.token}"}

        response = requests.request(
            "POST",
            f"https://{self.instance}/{HEC_ENDPOINT}",
            headers=headers,
            verify=False,
            data=json.dumps({"event": "test"}),
        )
        return response.status_code == 200


def updateDate(log_line: str) -> str:
    current_date = f"[{datetime.now().strftime('%a %b %d %H:%M:%S %Y')}]"
    new_line = re.sub(r"\[.*?\]", current_date, log_line, count=1)

    return new_line


if __name__ == "__main__":
    load_dotenv()
    logging.basicConfig(level=logging.INFO)

    host = os.getenv("SPLUNK_HEC_HOST", "localhost")
    port = os.getenv("SPLUNK_HEC_PORT", 8088)
    token = os.getenv("SPLUNK_HEC_TOKEN")
    namespace = os.getenv("SPLUNK_HEC_NAMESPACE")
    frequency = 7
    stage = os.getenv("STAGE", "")
    error_msg = (
        "[Fri Jul 28 09:59:58 2023] [error] mod_jvk child workerEnv in error state 7"
    )

    if not token:
        raise EnvironmentError("Please set the environment variables SPLUNK_HEC_TOKEN")

    sp = Splunksender(host, port, token)
    if not sp.is_connected():
        print("Splunk HEC is not available")
        exit(1)
    i = 0
    log(
        level=logging.INFO,
        msg=f"Sending logs to {sp.instance} each {frequency} seconds on http:selobe-wind{stage}",
    )
    while True:
        error_msg = updateDate(error_msg)
        resp = sp.send(error_msg, f"http:selobe-wind{stage}")
        log(level=logging.INFO, msg=error_msg)
        log(level=logging.INFO, msg=f"Response: {resp.content}")
        log(level=logging.INFO, msg=f"Error number: {i}")
        i += 1
        time.sleep(frequency)
