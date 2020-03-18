[![Build Status](https://travis-ci.org/wso2-ballerina/module-salesforce.svg?branch=master)](https://travis-ci.org/wso2-ballerina/module-salesforce)

# Module Salesforce

Connects to Salesforce from Ballerina. 

The Salesforce connector allows you to perform CRUD operations for SObjects, query using SOQL, search using SOSL, and
describe SObjects and organizational data through the Salesforce REST API. Also it supports insert, upsert, update, 
query and delete operations for CSV, JSON and XML data types which provides in Salesforce bulk API. 
It handles OAuth 2.0 authentication.

**SObject Operations**

The `wso2/sfdc46` module contains operations to do CRUD operations for standard and customized SObjects. It can create, 
get, update, and delete SObjects via SObject IDs, and upsert via external IDs.

**SOQL & SOSL Operations**

The `wso2/sfdc46` module contains operations that query using SOQL and search using SOSL. This allows for complex 
operations using SObjects relationships.

**Describe Operations**

The `wso2/sfdc46` module contains operations that describe SObjects, organizational data, available resources, APIs, and 
limitations for organizations.

**Bulk Operations**

The `wso2/sfdc46` module contains insert, upsert, update, query and delete asynchronous bulk operations for CSV, JSON
and XML data types.

## Compatibility
|                     |    Version     |
|:-------------------:|:--------------:|
| Ballerina Language  | 1.0.X, 1.1.0   |
| Salesforce REST API | v46.0          |

## Sample
First, import the `wso2/sfdc46` module into the Ballerina project.
```ballerina
import wso2/sfdc46;
```
Instantiate the connector by giving authentication details in the HTTP client config, which has built-in support for 
BasicAuth and OAuth 2.0. Salesforce uses OAuth 2.0 to authenticate and authorize requests. The Salesforce connector can 
be instantiated in the HTTP client config using the access token or using the client ID, client secret, and refresh 
token.

**Obtaining Tokens**

1. Visit [Salesforce](https://www.salesforce.com) and create a Salesforce Account.
2. Create a connected app and obtain the following credentials: 
    * Base URL (Endpoint)
    * Access Token
    * Client ID
    * Client Secret
    * Refresh Token
    * Refresh Token URL
    
3.  When you are setting up the connected app, select the following scopes under Selected OAuth Scopes:

    * Access and manage your data (api)
    * Perform requests on your behalf at any time (refresh_token, offline_access)
    * Provide access to your data via the Web (web)

4. Provide the client ID and client secret to obtain the refresh token and access token. For more information on 
   obtaining OAuth2 credentials, go to 
   [Salesforce documentation](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm).

**Create Salesforce client**

You can define the Salesforce configuration and create Salesforce client as mentioned below. 
```ballerina
// Create Salesforce client configuration by reading from config file.
sfdc46:SalesforceConfiguration sfConfig = {
    baseUrl: "<EP_URL>",
    clientConfig: {
        accessToken: "<ACCESS_TOKEN>",
        refreshConfig: {
            clientId: "<CLIENT_ID>",
            clientSecret: "<CLIENT_SECRET>",
            refreshToken: "<REFRESH_TOKEN>",
            refreshUrl: "<REFRESH_URL>"
        }
    }
};

// Create the Salesforce client.
sfdc46:Client salesforceClient = new(sfConfig);
```

If you want to add your own key store to define the `secureSocketConfig`, change the Salesforce configuration as
mentioned below.
```ballerina
// Create Salesforce client configuration by reading from config file.
sfdc46:SalesforceConfiguration sfConfig = {
    baseUrl: "<EP_URL>",
    clientConfig: {
        accessToken: "<ACCESS_TOKEN>",
        refreshConfig: {
            clientId: "<CLIENT_ID>",
            clientSecret: "<CLIENT_SECRET>",
            refreshToken: "<REFRESH_TOKEN>",
            refreshUrl: "<REFRESH_URL>"
        }
    },
    secureSocketConfig: {
        trustStore: {
            path: "<TRUSTSTORE_PATH>",
            password: "<TRUSTSTORE_PASSWORD>"
        }
    }
};
```

**Salesforce CRUD Operations**

The `createAccount` remote function creates an Account SObject. Pass a JSON object with the relevant fields needed for 
the SObject Account.

```ballerina
json account = { Name: "ABC Inc", BillingCity: "New York" };
string|sfdc46:ConnectorError createReponse = salesforceClient->createAccount(account);
```

The response from `createAccount` is either the string ID of the created account (if the account was created 
successfully) or `ConnectorError` (if the account creation was unsuccessful).

```ballerina
if (createReponse is string) {
    io:println("Account id: " + createReponse);
} else {
    io:println(createReponse.detail()?.message.toString());
}
```

The `getQueryResult` remote function executes a SOQL query that returns all the results in a single response or if it 
exceeds the maximum record limit, it returns part of the results and an identifier that can be used to retrieve the 
remaining results.

```ballerina
string sampleQuery = "SELECT name FROM Account";
sfdc46:SoqlResult|sfdc46:ConnectorError response = salesforceClient->getQueryResult(sampleQuery);
```

The response from `getQueryResult` is either a SoqlResult record with total size, execution status, resulting records, 
and URL to get next record set (if query execution was successful) or `ConnectorError` (if the query execution 
was unsuccessful).

```ballerina
if (response is sfdc46:SoqlResult) {
    io:println("TotalSize:  ", response.totalSize.toString());
    io:println("Done:  ", response.done.toString());
    io:println("Records: ", response.records.toString());
} else {
    io:println("Error: ", response.detail()?.message.toString());
}
```
The `createLead` remote function creates a Lead SObject. It returns the lead ID if successful or 
`ConnectorError` if unsuccessful.

```ballerina
json lead = {LastName:"Carmen", Company:"WSO2", City:"New York"};
string|sfdc46:ConnectorError createResponse = salesforceClient->createLead(lead);

if (createResponse is string) {
    io:println("Lead id: " + createResponse);
} else {
    io:println("Error: ", createResponse.detail()?.message.toString());
}
```

**Salesforce Bulk Operations**

The `createSalesforceBulkClient` remote function creates the salesforce bulk client which facilitates bulk operations.
Bulk client can create appropriate operator Corresponding to the data type. The `createCsvInsertOperator` remote 
function creates Insert operator for CSV content type.

```ballerina
// Create salesforce bulk client.
sfdc46:SalesforceBulkClient sfBulkClient = salesforceClient->createSalesforceBulkClient();

// Create CSV insert operator for object type `Contact`.
sfdc46:CsvInsertOperator|sfdc46:ConnectorError csvInsertOperator = sfBulkClient->createCsvInsertOperator("Contact");
```

`insert` remote function creates a insert batch using CSV content. CSV content can be passed as a `string` or 
`io:ReadableByteChannel` as given below.

```ballerina
// Upload the CSV contacts as a string.
string contacts = "description,FirstName,LastName,Title,Phone,Email,My_External_Id__c
Created_from_Ballerina_Sf_Bulk_API,John,Michael,Professor Grade 04,0332236677,john434@gmail.com,301
Created_from_Ballerina_Sf_Bulk_API,Peter,Shane,Professor Grade 04,0332211777,peter77@gmail.com,302";
sfdc46:BatchInfo|sfdc46:ConnectorError batchUsingCsv = csvInsertOperator->insert(contacts);

// Upload CSV contacts as a file.
io:ReadableByteChannel|io:Error rbc = io:openReadableFile("path/to/the/file/contacts.csv");
if (rbc is io:ReadableByteChannel) {
    sfdc46:BatchInfo|sfdc46:ConnectorError batchUsingCsvFile = csvInsertOperator->insert(rbc);
    // close channel.
    var cr = rbc.close();
    if (cr is error) {
        io:println("Error occured while closing the channel: " + cr.toString());
    }
} else {
    io:println("Error occurred while reading file: " + rbc.toString());
}
```

`closeJob` and `abortJob` remote functions close and abort CSV insert job respectively. When a job is closed, no more 
batches can be added. When a job is aborted, no more records are processed. If changes to data have already been 
committed, they aren’t rolled back.

```ballerina
// Close job.
sfdc46:JobInfo|sfdc46:ConnectorError closedJob = csvInsertOperator->closeJob();

// Abort job.
sfdc46:JobInfo|sfdc46:ConnectorError abortedJob = csvInsertOperator->abortJob();
```

`getJobInfo` remote function get all details for an existing job. `getBatchInfo` remote function get information about 
an existing batch. `getAllBatches` remote function get information about all batches in a job.

```ballerina
// Get job information.
sfdc46:JobInfo|sfdc46:ConnectorError job = csvInsertOperator->getJobInfo();

// Get batch ID using sfdc46:BatchInfo record.
string batchId = batchUsingCsv.id;
// Get batch information.
sfdc46:BatchInfo|sfdc46:ConnectorError batchInfo = csvInsertOperator->getBatchInfo(batchId);

// Get information of all batches of this csv insert job.
sfdc46:BatchInfo[]|sfdc46:ConnectorError allBatchInfo = csvInsertOperator->getAllBatches();
```

`getBatchRequest` remote function gets the batch request uploaded to the csv insert job. `getResult` remote 
function get results of a batch that has completed processing.

```ballerina
// Retrieve the csv batch request.
string|sfdc46:ConnectorError batchRequest = csvInsertOperator->getBatchRequest(batchId);
// Get batch result as csv.
int noOfRetries = 5; // Number of times trying to get the results.
int waitTime = 3000; // Time between two tries in milli-seconds.
sfdc46:Result[]|sfdc46:ConnectorError batchResult = csvInsertOperator->getResult(batchId, noOfRetries, waitTime);
```

Likewise Salesforce bulk client provides following operators:

- CSV 
  - insert operator
  - upsert operator
  - update operator
  - query operator
  - delete operator
- JSON 
  - insert operator
  - upsert operator
  - update operator
  - query operator
  - delete operator
- XML
  - insert operator
  - upsert operator
  - update operator
  - query operator
  - delete operator
