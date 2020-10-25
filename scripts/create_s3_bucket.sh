#!/bin/bash

aws --profile private s3api create-bucket --create-bucket-configuration LocationConstraint=ap-northeast-1 --bucket aws-ecs-terraform-tutorial
aws --profile private s3api put-bucket-versioning --bucket aws-ecs-terraform-tutorial --versioning-configuration Status=Enabled
