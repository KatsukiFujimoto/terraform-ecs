#!/bin/bash

aws --profile private s3api delete-objects \
    --bucket aws-ecs-terraform-tutorial \
    --delete "$(aws --profile private s3api list-object-versions \
    --bucket aws-ecs-terraform-tutorial \
    --output=json \
    --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
aws --profile private s3api delete-bucket --bucket aws-ecs-terraform-tutorial
