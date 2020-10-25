#!/bin/bash

# Associate with ECS cluster by adding cluster name in ECS config
echo ECS_CLUSTER=${ecs_cluster_name} >> /etc/ecs/ecs.config
