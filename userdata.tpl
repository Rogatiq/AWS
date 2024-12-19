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
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upload Files to S3</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f0f4f8;
            margin: 0;
            padding: 0;
            color: #333;
        }
        .container {
            width: 80%;
            margin: 50px auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #4CAF50;
            text-align: center;
        }
        form {
            display: flex;
            justify-content: center;
            align-items: center;
            margin-bottom: 30px;
        }
        input[type="file"] {
            padding: 10px;
            margin-right: 10px;
            font-size: 16px;
            border: 1px solid #ccc;
            border-radius: 4px;
        }
        input[type="submit"] {
            padding: 10px 20px;
            font-size: 16px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        input[type="submit"]:hover {
            background-color: #45a049;
        }
        ul {
            list-style-type: none;
            padding: 0;
        }
        li {
            background-color: #f9f9f9;
            margin: 10px 0;
            padding: 10px;
            border-radius: 4px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        .file-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .file-name {
            font-size: 16px;
        }
        .delete-button {
            background-color: #ff6347;
            color: white;
            border: none;
            padding: 5px 10px;
            border-radius: 4px;
            cursor: pointer;
        }
        .delete-button:hover {
            background-color: #e5533e;
        }
    </style>
</head>
<body>

    <div class="container">
        <h1>Upload Your Files</h1>
        <form method="post" enctype="multipart/form-data">
            <input type="file" name="file" required>
            <input type="submit" value="Upload">
        </form>
        <ul>
        {% for filename in files %}
            <li class="file-item">
                <span class="file-name">{{ filename }}</span>
                <form action="/delete/{{ filename }}" method="post" style="display:inline;">
                    <button type="submit" class="delete-button">Delete</button>
                </form>
            </li>
        {% endfor %}
        </ul>
    </div>

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

    # List files in the S3 bucket
    files_list = []
    response = s3.list_objects_v2(Bucket=bucket_name)
    if 'Contents' in response:
        for obj in response['Contents']:
            files_list.append(obj['Key'])

    return render_template_string(html, files=files_list)

@app.route('/delete/<filename>', methods=['POST'])
def delete_file(filename):
    try:
        s3.delete_object(Bucket=bucket_name, Key=filename)
    except Exception as e:
        print(f"Error deleting file {filename}: {e}")
    return redirect(url_for('upload_file'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
EOF

chown ec2-user:ec2-user /home/ec2-user/app.py
nohup python3 /home/ec2-user/app.py > /home/ec2-user/app.log 2>&1 &
