// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/log;
import ballerina/test;

@test:Config {}
function insertXml()
    {
    log:printInfo("bulkClient -> insertXml");
    string batchId = "";

    xml contacts = xml `<sObjects xmlns="http://www.force.com/2009/06/asyncapi/dataload">
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <FirstName>Lucas</FirstName>
            <LastName>Podolski</LastName>
            <Title>Professor Grade 05</Title>
            <Phone>0332254123</Phone>
            <Email>lucas@yahoo.com</Email>
            <My_External_Id__c>221</My_External_Id__c>
        </sObject>
        <sObject>
            <description>Created_from_Ballerina_Sf_Bulk_API</description>
            <FirstName>Miroslav</FirstName>
            <LastName>Klose</LastName>
            <Title>Professor Grade 05</Title>
            <Phone>0442554423</Phone>
            <Email>klose@gmail.com</Email>
            <My_External_Id__c>222</My_External_Id__c>
        </sObject>
    </sObjects>`;

    //create job
    error|BulkJob insertJob = bulkClient->creatJob("insert", "Contact", "XML");

        if (insertJob is BulkJob) {
        //add xml content
        error|BatchInfo batch = insertJob->addBatch(contacts);
        if (batch is BatchInfo) {
            test:assertTrue(batch.id.length() > 0, msg = "Could not upload the contacts using xml.");
            batchId = batch.id;
        } else {
            test:assertFail(msg = batch.detail()?.message.toString());
        }

        //get job info
        error|JobInfo jobInfo = bulkClient->getJobInfo(insertJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.detail()?.message.toString());
        }

        //get batch info
        error|BatchInfo batchInfo = insertJob->getBatchInfo(batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        //get all batches
        error|BatchInfo[] batchInfoList = insertJob->getAllBatches();
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = batchInfoList.detail()?.message.toString());
        }

        //get batch request
        var batchRequest = insertJob->getBatchRequest(batchId);
            if (batchRequest is xml) {
            test:assertTrue ((batchRequest/<*>).length() == 2, msg ="Retrieving batch request failed.");
        } else if (batchRequest is error) {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        } else {
            test:assertFail("Invalid batch request!");
        }

        //get batch result
        var batchResult = insertJob->getBatchResult(batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            test:assertTrue(checkBatchResults(batchResult), msg = "Insert was not successful.");
        } else if (batchResult is error) {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        } else {
            test:assertFail("Invalid Batch Result!");
        }

        //close job
        error|JobInfo closedJob = bulkClient->closeJob(insertJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }

    } else {
        test:assertFail(msg = insertJob.detail()?.message.toString());
    }
}

@test:Config {}
function insertXmlFromFile()
    {
    log:printInfo("bulkClient -> insertXmlFromFile");
    string batchId = "";

    string xmlContactsFilePath = "sfdc-connector/src/sfdc/tests/resources/contacts.xml";

    //create job
    error|BulkJob insertJob = bulkClient->creatJob("insert", "Contact", "XML");

        if (insertJob is BulkJob) {
        //add xml content via file
        io:ReadableByteChannel|io:Error rbc = io:openReadableFile(xmlContactsFilePath);
        if (rbc is io:ReadableByteChannel) {
            error|BatchInfo batchUsingXmlFile = insertJob->addBatch(<@untainted>rbc);
            if (batchUsingXmlFile is BatchInfo) {
                test:assertTrue(batchUsingXmlFile.id.length() > 0, msg = "Could not upload the contacts using xml file.");
                batchId = batchUsingXmlFile.id;
            } else {
                test:assertFail(msg = batchUsingXmlFile.detail()?.message.toString());
            }
            // close channel.
            closeRb(rbc);
        } else {
            test:assertFail(msg = rbc.detail()?.message.toString());
        }

        //get job info
        error|JobInfo jobInfo = bulkClient->getJobInfo(insertJob);
        if (jobInfo is JobInfo) {
            test:assertTrue(jobInfo.id.length() > 0, msg = "Getting job info failed.");
        } else {
            test:assertFail(msg = jobInfo.detail()?.message.toString());
        }

        //get batch info
        error|BatchInfo batchInfo = insertJob->getBatchInfo(batchId);
        if (batchInfo is BatchInfo) {
            test:assertTrue(batchInfo.id == batchId, msg = "Getting batch info failed.");
        } else {
            test:assertFail(msg = batchInfo.detail()?.message.toString());
        }

        //get all batches
        error|BatchInfo[] batchInfoList = insertJob->getAllBatches();
        if (batchInfoList is BatchInfo[]) {
            test:assertTrue(batchInfoList.length() == 1, msg = "Getting all batches info failed.");
        } else {
            test:assertFail(msg = batchInfoList.detail()?.message.toString());
        }

        //get batch request
        var batchRequest = insertJob->getBatchRequest(batchId);
            if (batchRequest is xml) {
            test:assertTrue ((batchRequest/<*>).length() == 2, msg ="Retrieving batch request failed.");
        } else if (batchRequest is error) {
            test:assertFail(msg = batchRequest.detail()?.message.toString());
        } else {
            test:assertFail("Invalid batch request!");
        }

        //get batch result
        var batchResult = insertJob->getBatchResult(batchId);
        if (batchResult is Result[]) {
            test:assertTrue(batchResult.length() > 0, msg = "Retrieving batch result failed.");
            test:assertTrue(checkBatchResults(batchResult), msg = "Insert was not successful.");
        } else if (batchResult is error) {
            test:assertFail(msg = batchResult.detail()?.message.toString());
        } else {
            test:assertFail("Invalid Batch Result!");
        }

        //close job
        error|JobInfo closedJob = bulkClient->closeJob(insertJob);
        if (closedJob is JobInfo) {
            test:assertTrue(closedJob.state == "Closed", msg = "Closing job failed.");
        } else {
            test:assertFail(msg = closedJob.detail()?.message.toString());
        }

    } else {
        test:assertFail(msg = insertJob.detail()?.message.toString());
    }
}
