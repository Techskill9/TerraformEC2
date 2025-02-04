package test

import (
	//"github.com/gruntwork-io/terratest/modules/aws"
	"os"
	//"github.com/gruntwork-io/terratest/modules/random"
	"log"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformEC2(t *testing.T) {
	t.Parallel()
	file, err := os.OpenFile("terratest_logs.txt", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		log.Fatal(err)
	}
	log.SetOutput(file)
	// Make a copy of the terraform module to a temporary directory. This allows running multiple tests in parallel
	// against the same terraform module.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../examples/",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{"terraform_workspace": "tec-dce-inn-dev-93400-terratest"},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	ec2ID := terraform.Output(t, terraformOptions, "id")
	assert.NotEmpty(t, terraformOptions, ec2ID)
	log.Println("Passed:ec2ID", ec2ID)
	ec2Privateip := terraform.Output(t, terraformOptions, "private_ip")
	assert.NotEmpty(t, terraformOptions, ec2Privateip)
	log.Println("Passed:ec2Privateip", ec2Privateip)
	ec2InstanceType := terraform.Output(t, terraformOptions, "instance_type")
	assert.NotEqual(t, "t2.micro", ec2InstanceType)
	log.Println("Passed:ec2InstanceType", ec2InstanceType)
}
