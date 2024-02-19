import asyncio
import aiohttp
import time
import json
import os
import requests
import logging
from urllib.parse import urljoin
from os import path

KOBOLDCPP_API_BASE = "http://localhost:5001/api/v1/"
KOBOLDCPP_MODEL_ENDPOINT = "model"
KOBOLDCPP_GENERATE_ENDPOINT = "generate"
KOBOLDCPP_INIT_TIMEOUT = 240 # 4minutes

logging.basicConfig(level=logging.INFO)

# Periodically call koboldcpp HTTP API to check if server is initialized
def koboldcpp_wait_until_started():
    counter = 0
    while True:
        try:
            response = requests.get(urljoin(KOBOLDCPP_API_BASE, KOBOLDCPP_MODEL_ENDPOINT))
            if response.status_code == 200:
                # Successfully received 200 OK
                logging.info("Koboldcpp daemon initialized.")
                return True
        except requests.exceptions.RequestException as e:
            # Handle exception for a failed request
            logging.error(f"An error occurred: {e}")

        counter += 1
        if counter > KOBOLDCPP_INIT_TIMEOUT:
            error_str = "Error: koboldcpp did not initialize in 4 minutes, exiting.."
            logging.error(error_str)
            return False

        # Wait before trying again
        time.sleep(1)


def koboldcpp_generate_response(input_text):
    # Set the API endpoint URL
    generate_api_endpoint = urljoin(KOBOLDCPP_API_BASE, KOBOLDCPP_GENERATE_ENDPOINT)

    # Create the JSON payload
    payload = {
        "prompt": "",
        "max_context_length": 20000,
        "max_length": 128,
        "rep_pen": 1.1,
        "temperature": 0.6,
        "top_p": 0.72,
        "min_p": 0,
        "top_k": 100,
        "stop_sequence": ["\n"]
    }

    preprompt = "You are an F-16 pilot responding to the following call on the radio. Use appropriate military brevity speak. \n\n"

    output_text = ""

    payload['prompt'] = preprompt + input_text
    #payload['prompt'] = "[INST]" + payload['prompt'] + "[/INST]\n" # PROMPT TEMPLATE FOR MISTRAL AND MIXTRAL
    payload['prompt'] = "### Instruction: " + payload['prompt'] + "\n### Response:" # PROMPT TEMPLATE FOR ALPACA (Toppy, other non-mistral)
    # Make the API request
    response = requests.post(generate_api_endpoint, json=payload)

    # Check if the request was successful
    if response.status_code == 200:
        # Check if 'results' is in the response and append its first 'text' item to output_text
        if 'results' in response.json():
            output_text += response.json()['results'][0]['text']
            output_text += "\n"
        else:
            logging.error("Request failed, results is empty, status code:\n {response.status_code}, response Text:\n {response.text}")
    else:
        logging.error("Request failed, status code:\n {response.status_code}, response Text:\n {response.text}")

    return output_text
