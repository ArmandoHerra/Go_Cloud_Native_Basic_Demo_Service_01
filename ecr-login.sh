#!/bin/bash -xe

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 933673765333.dkr.ecr.us-east-1.amazonaws.com

