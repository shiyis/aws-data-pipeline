#!/usr/bin/env python
from os import access
from constructs import Construct
from cdktf import App, NamedRemoteWorkspace, TerraformStack, TerraformOutput, RemoteBackend
from cdktf_cdktf_provider_aws import AwsProvider, ec2 
import json

ACCESS_KEY = "AKIAW7FIH46GF2X7JRXB"
SECRET_KEY = "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"
REGION = "us-west-1"

class MyStack(TerraformStack):
    def __init__(self, scope: Construct, ns: str):
        super().__init__(scope, ns)

        AwsProvider(self, "AWS",region=REGION, access_key=ACCESS_KEY, secret_key=SECRET_KEY)

        instance = ec2.Instance(self, "compute",
                                ami="ami-01456a894f71116f2",
                                instance_type="t2.micro",
                                )

        TerraformOutput(self, "public_ip",
                        value=instance.public_ip,
                        )


app = App()
stack = MyStack(app, "aws_instance")

RemoteBackend(stack,
              hostname='app.terraform.io',
              organization='quintrix-aws-data-pipeline',
              workspaces=NamedRemoteWorkspace('aws-data-streaming-pipeline')
              )

app.synth()
