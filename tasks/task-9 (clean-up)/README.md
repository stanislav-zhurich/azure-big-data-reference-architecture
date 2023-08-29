# Task 9 - Clean up resources.
> **Time to complete**: 1 hour
## Objective 
After all task are completed we need to purge all resources created in scope of these exercises.
## Steps
1. Run following commande from inside the project:
> terraform\azure> terraform destroy
2. Make sure it's completed successfully.
3. Sometimes it might fail so you can go to Azure portal -> resource group and delete it expicitly. As long as all resources reside within the same resource group, they all be removed.
## Validation
1. All resources are deleted.
