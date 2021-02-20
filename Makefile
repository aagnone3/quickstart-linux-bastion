include ./env

# For debugging purposes e.g. `make EXTRA_ARGS=--dryrun upload`
EXTRA_ARGS ?=

.PHONY: upload
upload:
	aws s3 sync \
		$(EXTRA_ARGS) \
		--delete \
		--exclude '.git*' \
		--exclude Makefile \
		--exclude env \
		--exclude .taskcat.yml \
		./ s3://$(S3_BUCKET)/

.PHONY: validate
validate:
	aws cloudformation validate-template \
		--template-body file://$(TEMPLATE_FILE)

.PHONY: create
create:
	aws cloudformation create-stack \
		--disable-rollback \
		--stack-name $(CFN_STACK_NAME) \
		--template-url https://$(S3_BUCKET).s3.amazonaws.com/$(TEMPLATE_FILE) \
		--parameters \
			ParameterKey=BastionAMIOS,ParameterValue=$(AMI_OS) \
			ParameterKey=BastionHostName,ParameterValue=$(HOST_NAME) \
			ParameterKey=BastionInstanceType,ParameterValue=$(EC2_INSTANCE_TYPE) \
			ParameterKey=KeyPairName,ParameterValue=$(KEY_PAIR_NAME) \
			ParameterKey=NumBastionHosts,ParameterValue=$(NUM_HOSTS) \
			ParameterKey=VPCID,ParameterValue=$(VPC_ID) \
			ParameterKey=PublicSubnet1ID,ParameterValue=$(SUBNET1_ID) \
			ParameterKey=PublicSubnet2ID,ParameterValue=$(SUBNET2_ID) \
			ParameterKey=QSS3BucketName,ParameterValue=$(S3_BUCKET) \
			ParameterKey=QSS3KeyPrefix,ParameterValue=$(S3_PREFIX) \
			ParameterKey=QSS3BucketRegion,ParameterValue=$(S3_BUCKET_REGION) \
			ParameterKey=RemoteAccessCIDR,ParameterValue=$(REMOTE_ACCESS_CIDR) \
			ParameterKey=EnableBanner,ParameterValue=$(ENABLE_BANNER) \
			ParameterKey=RootVolumeSize,ParameterValue=$(EBS_SIZE_GB) \
		--capabilities "$(CFN_CAPABILITIES)"

.PHONY: deploy
deploy:
	aws cloudformation deploy \
		--stack-name $(CFN_STACK_NAME) \
		--s3-bucket $(S3_BUCKET) \
		--template-file $(TEMPLATE_FILE) \
		--force-upload \
		--parameter-overrides \
			BastionAMIOS=$(AMI_OS) \
			BastionHostName=$(HOST_NAME) \
			BastionInstanceType=$(EC2_INSTANCE_TYPE) \
			KeyPairName=$(KEY_PAIR_NAME) \
			NumBastionHosts=$(NUM_HOSTS) \
			VPCID=$(VPC_ID) \
			PublicSubnet1ID=$(SUBNET1_ID) \
			PublicSubnet2ID=$(SUBNET2_ID) \
			QSS3BucketName=$(S3_BUCKET) \
			QSS3KeyPrefix=$(S3_PREFIX) \
			QSS3BucketRegion=$(S3_BUCKET_REGION) \
			RemoteAccessCIDR=$(REMOTE_ACCESS_CIDR) \
			RootVolumeSize=$(EBS_SIZE_GB) \
		--capabilities "$(CFN_CAPABILITIES)"

.PHONY: destroy
destroy:
	aws cloudformation delete-stack --stack-name $(CFN_STACK_NAME)
