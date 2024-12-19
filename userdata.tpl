#!/bin/bash
set -eux

yum update -y
yum install -y python3-pip git

pip3 install flask boto3

cat <<EOF > /home/ec2-user/app.py
from flask import Flask, request, render_template_string, redirect, url_for
import boto3
import socket

app = Flask(__name__)
s3 = boto3.client('s3', region_name='${region}')
bucket_name = '${bucket_name}'

html = """
<!doctype html>
<title>Uploading File</title>
<h1>Upload anything without zip bombs</h1>
<form method=post enctype=multipart/form-data>
  <input type=file name=file>
  <input type=submit value=Upload>
</form>
<ul>
{% for filename in files %}
<li>{{ filename }}</li>
{% endfor %}
</ul>
"""

@app.route('/', methods=['GET', 'POST'])
def upload_file():
    # If POST, handle file upload and then redirect to refresh the list
    if request.method == 'POST':
        f = request.files['file']
        if f and f.filename:
            s3.upload_fileobj(f, bucket_name, f.filename)
        return redirect(url_for('upload_file'))

    # If GET, list files in S3 and render the page
    files_list = []
    response = s3.list_objects_v2(Bucket=bucket_name)
    if 'Contents' in response:
        for obj in response['Contents']:
            files_list.append(obj['Key'])

    return render_template_string(html, files=files_list)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
EOF

chown ec2-user:ec2-user /home/ec2-user/app.py
nohup python3 /home/ec2-user/app.py > /home/ec2-user/app.log 2>&1 &
