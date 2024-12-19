#!/bin/bash
set -eux

yum update -y
yum install -y python3-pip git

pip3 install flask boto3

cat <<EOF > /home/ec2-user/app.py
from flask import Flask, request, render_template_string, redirect, url_for
import boto3
import os
import socket

app = Flask(__name__)
s3 = boto3.client('s3', region_name='${region}')
bucket_name = '${bucket_name}'
private_ip = socket.gethostbyname(socket.gethostname())

html = """
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upload File</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-5">
        <div class="text-center">
            <h1 class="display-4">Upload File to S3</h1>
            <p class="lead">Your private IP: {{ private_ip }}</p>
        </div>
        <div class="card shadow-sm p-4 mb-4">
            <form method="post" enctype="multipart/form-data" class="d-flex flex-column align-items-center">
                <div class="mb-3">
                    <input type="file" name="file" class="form-control">
                </div>
                <button type="submit" class="btn btn-primary">Upload</button>
            </form>
        </div>
        <h2 class="mt-5">Files in S3</h2>
        <ul class="list-group">
            {% for filename in files %}
            <li class="list-group-item">{{ filename }}</li>
            {% endfor %}
        </ul>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
"""

@app.route('/', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        f = request.files['file']
        if f and f.filename:
            s3.upload_fileobj(f, bucket_name, f.filename)
        return redirect(url_for('upload_file'))

    files_list = []
    response = s3.list_objects_v2(Bucket=bucket_name)
    if 'Contents' in response:
        for obj in response['Contents']:
            files_list.append(obj['Key'])

    return render_template_string(html, files=files_list, private_ip=private_ip)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
EOF

chown ec2-user:ec2-user /home/ec2-user/app.py

nohup python3 /home/ec2-user/app.py > /home/ec2-user/app.log 2>&1 &
