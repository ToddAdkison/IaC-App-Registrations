1. Create an Azure DevOps Service Connection
In Azure DevOps:

1. Go to Project Settings → Service connections
2. Create a new Azure Resource Manager service connection
3. Use a service principal (Workload Identity Federation or secret-based)
4. Ensure the service principal has permission to create Entra ID applications

1.1 Assign Owner at Tenant Root Scope
```
az role assignment create \
  --assignee "746762c5-eb50-45e3-b0bd-e22fa50d91e5" \
  --role "Owner" \
  --scope "/"
```
1.2 Grant Graph API Permission to the SP (Application.ReadWrite.All)
```
# Get the Microsoft Graph service principal ID in your tenant
GRAPH_SP_ID=$(az ad sp list --filter "appId eq '00000003-0000-0000-c000-000000000000'" \
  --query "[0].id" -o tsv)

# Get the Application.ReadWrite.All role ID from Graph
APP_RW_ROLE_ID=$(az ad sp show --id "00000003-0000-0000-c000-000000000000" \
  --query "appRoles[?value=='Application.ReadWrite.All'].id" -o tsv)

# Grant the app role to your pipeline SP
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$GRAPH_SP_ID/appRoleAssignedTo" \
  --body "{
    \"principalId\": \"746762c5-eb50-45e3-b0bd-e22fa50d91e5\",
    \"resourceId\": \"$GRAPH_SP_ID\",
    \"appRoleId\": \"$APP_RW_ROLE_ID\"
  }"
```
