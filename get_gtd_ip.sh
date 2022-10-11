SERVICE_NAME=$1

TASK_ARN=$(aws ecs list-tasks --cluster "$2" --service-name "$SERVICE_NAME" --query 'taskArns[0]' --output text)
TASK_DETAILS=$(aws ecs describe-tasks --cluster "$2" --task "${TASK_ARN}" --query 'tasks[0].attachments[0].details')
ENI=$(echo $TASK_DETAILS | jq -r '.[] | select(.name=="networkInterfaceId").value')
IP=$(aws ec2 describe-network-interfaces --network-interface-ids "${ENI}" --query 'NetworkInterfaces[0].Association.PublicIp' --output text)

echo "\nThe public ip address to the deployed app is http://$IP:$3/\n"
