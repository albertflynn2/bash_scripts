import json
import tkinter as tk
from tkinter import filedialog, simpledialog
from elasticsearch import Elasticsearch, helpers

def validate_log_entry(log_entry):
    return isinstance(log_entry, str) and len(log_entry.split(' ')) > 0

def validate_json_entry(json_entry):
    return isinstance(json_entry, list) and all(isinstance(item, str) for item in json_entry)

def log_to_json(log_file_path, json_file_path):
    json_data = []
    
    with open(log_file_path, 'r') as log_file:
        for line in log_file:
            log_entry = line.strip().split(' ')
            if validate_log_entry(log_entry):
                json_data.append(log_entry)
            else:
                print(f"Invalid log entry: {log_entry}")
                return
            
    with open(json_file_path, 'w') as json_file:
        json.dump(json_data, json_file)

def json_to_log(json_file_path, log_file_path):
    with open(json_file_path, 'r') as json_file:
        data = json.load(json_file)

    with open(log_file_path, 'w') as log_file:
        for entry in data:
            log_entry = ' '.join(entry)
            log_file.write(log_entry + '\n')

def upload_to_elasticsearch(json_file_path, cloud_id, username, password):
    es = Elasticsearch(
        cloud_id=cloud_id,
        http_auth=(username, password),
    )

    with open(json_file_path, 'r') as json_file:
        data = json.load(json_file)

    actions = []
    for entry in data:
        if validate_json_entry(entry):
            actions.append({
                "_index": "your_index_name",
                "_source": entry,
            })
        else:
            print(f"Invalid JSON entry: {entry}")
            return

    helpers.bulk(es, actions)

def select_log_file():
    log_file_path = filedialog.askopenfilename()
    json_file_path = filedialog.asksaveasfilename(defaultextension=".json")
    
    cloud_id = simpledialog.askstring("Input", "Enter your Elasticsearch Cloud ID:")
    username = simpledialog.askstring("Input", "Enter your Elasticsearch username:")
    password = simpledialog.askstring("Input", "Enter your Elasticsearch password:", show='*')
    
    log_to_json(log_file_path, json_file_path)
    upload_to_elasticsearch(json_file_path, cloud_id, username, password)

root = tk.Tk()
button = tk.Button(root, text="Select log file", command=select_log_file)
button.pack()
root.mainloop()
