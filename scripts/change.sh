#!/usr/bin/env zsh

declare -A VARS
while read line
do
    key=$(echo $line | cut -d= -f1)
    value=$(echo $line | cut -d= -f2-)
    VARS[$key]=$value
done < env

# aws cloudformation describe-change-set \
#     --stack-name ${VARS[CFN_STACK_NAME]} \
#     --change-set-name ${VARS[CFN_STACK_NAME]}-change

while getopts ":a:h" opt; do
    case ${opt} in
        a )
            echo "action is ${OPTARG}"
            action=${OPTARG}
            ;;
        h )
            echo "Usage"
            echo "  $0 -a <action>"
            echo "  <action> can be {stage,execute,}"
            exit 0
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            exit 1
            ;;
    esac
done

case ${action} in
    stage )
        echo "Creating change set"
        aws cloudformation create-change-set \
            --stack-name ${VARS[CFN_STACK_NAME]} \
            --change-set-name ${VARS[CFN_STACK_NAME]}-change \
            --template-url https://${VARS[S3_BUCKET]}.s3.amazonaws.com/${VARS[TEMPLATE_FILE]} \
            --parameters \
                ParameterKey=BastionAMIOS,ParameterValue=${VARS[AMI_OS]} \
                ParameterKey=BastionHostName,ParameterValue=${VARS[HOST_NAME]} \
                ParameterKey=BastionInstanceType,ParameterValue=${VARS[EC2_INSTANCE_TYPE]} \
                ParameterKey=KeyPairName,ParameterValue=${VARS[KEY_PAIR_NAME]} \
                ParameterKey=NumBastionHosts,ParameterValue=${VARS[NUM_HOSTS]} \
                ParameterKey=VPCID,ParameterValue=${VARS[VPC_ID]} \
                ParameterKey=PublicSubnet1ID,ParameterValue=${VARS[SUBNET1_ID]} \
                ParameterKey=PublicSubnet2ID,ParameterValue=${VARS[SUBNET2_ID]} \
                ParameterKey=QSS3BucketName,ParameterValue=${VARS[S3_BUCKET]} \
                ParameterKey=QSS3KeyPrefix,ParameterValue=${VARS[S3_PREFIX]} \
                ParameterKey=QSS3BucketRegion,ParameterValue=${VARS[S3_BUCKET_REGION]} \
                ParameterKey=RemoteAccessCIDR,ParameterValue=${VARS[REMOTE_ACCESS_CIDR]} \
                ParameterKey=EnableBanner,ParameterValue=${VARS[ENABLE_BANNER]} \
                ParameterKey=RootVolumeSize,ParameterValue=${VARS[EBS_SIZE_GB]} \
            --capabilities "${VARS[CFN_CAPABILITIES]}"
        ;;
    execute )
        echo "Executing change set"
        aws cloudformation execute-change-set \
            --stack-name ${VARS[CFN_STACK_NAME]} \
            --change-set-name ${VARS[CFN_STACK_NAME]}-change
        ;;
    \? )
        echo "Unsupported action ${action}"
        exit 1
        ;;
esac
